import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:poze/views/settings_view.dart';
import 'package:poze/views/process_detail_view.dart';
import 'package:provider/provider.dart';
import '../models/process_model.dart';
import '../models/system_stats.dart';
import '../services/osquery_service.dart';
import '../services/system_service.dart';
import '../services/background_fetch_service.dart';
import '../services/process_service.dart' show SortBy;
import '../widgets/process_list_item.dart';
import '../widgets/cpu_usage_chart.dart';
import '../app.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final OsqueryService _osqueryService = OsqueryService();
  final SystemService _systemService = SystemService();
  final BackgroundFetchService _backgroundFetchService = BackgroundFetchService();

  List<ProcessModel> _processes = [];
  SystemStats _systemStats = SystemStats.initial();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String _searchQuery = '';
  StreamSubscription? _processDataSubscription;
  StreamSubscription? _systemDataSubscription;
  StreamSubscription? _errorSubscription;
  SortBy _sortBy = SortBy.cpuUsage;
  String _filterState = 'all'; // 'all', 'running', 'paused'

  // Batch selection state
  final Set<String> _selectedPids = {};

  void _toggleSelectProcess(String pid) {
    setState(() {
      if (_selectedPids.contains(pid)) {
        _selectedPids.remove(pid);
      } else {
        _selectedPids.add(pid);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPids.clear();
    });
  }

  bool get _hasSelection => _selectedPids.isNotEmpty;

  List<ProcessModel> get _selectedProcesses =>
      _processes.where((p) => _selectedPids.contains(p.pid)).toList();

  Future<void> _batchPause() async {
    final names = _selectedProcesses.map((p) => p.name).toList();
    await _osqueryService.pauseProcesses(names);
    final procs = await _osqueryService.queryProcesses();
    setState(() {
      _processes = procs;
      _selectedPids.clear();
    });
    _backgroundFetchService.fetchData();
  }

  Future<void> _batchKill() async {
    final confirmed = await showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(),
            title: const Text('Confirmer la terminaison multiple'),
            message: Text(
              'Êtes-vous sûr de vouloir terminer ${_selectedPids.length} processus sélectionnés ? Cette action est irréversible.',
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terminer'),
            ),
            secondaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
          ),
    );
    if (confirmed == true) {
      await _osqueryService.killProcesses(_selectedPids.toList());
      final procs = await _osqueryService.queryProcesses();
      setState(() {
        _processes = procs;
        _selectedPids.clear();
      });
      _backgroundFetchService.fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeBackgroundService();
    _initializeOsquery();
  }

  /// Initialize osquery polling for process data.
  Future<void> _initializeOsquery() async {
    final installed = await _osqueryService.isInstalled();
    if (!installed) return;
    final interval = Duration(
      seconds: Provider.of<AppState>(context, listen: false).refreshInterval,
    );
    _processDataSubscription = _osqueryService
        .watchProcesses(interval)
        .listen((processes) {
      setState(() {
        _processes = processes;
        _isLoading = false;
      });
    });
  }

  Future<void> _initializeBackgroundService() async {
    setState(() {
      _isLoading = true;
    });

    await _backgroundFetchService.initialize();

    // Subscribe to system stats updates
    _systemDataSubscription = _backgroundFetchService.systemDataStream.listen(
      (stats) {
        setState(() {
          _systemStats = stats;
        });
      },
    );

    // Subscribe to error messages
    _errorSubscription = _backgroundFetchService.errorStream.listen((errorMsg) {
      if (mounted) {
        _showErrorDialog('Erreur lors du chargement des données: $errorMsg');
      }
    });

    // Initial data fetch
    _backgroundFetchService.fetchData();

    // Start auto-refresh
    _startAutoRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Redémarrer le timer si les paramètres changent
    _restartRefreshTimerIfNeeded();
  }

  @override
  void dispose() {
    _cancelRefreshTimer();
    _processDataSubscription?.cancel();
    _systemDataSubscription?.cancel();
    _errorSubscription?.cancel();
    _backgroundFetchService.dispose();
    super.dispose();
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _restartRefreshTimerIfNeeded() {
    _cancelRefreshTimer();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.autoRefresh) {
      _refreshTimer = Timer.periodic(
        Duration(seconds: appState.refreshInterval),
        (_) => _backgroundFetchService.fetchData(),
      );
    }
  }

  // Manual refresh function that triggers background fetch
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _backgroundFetchService.fetchData();
  }

  Future<void> _pauseProcess(ProcessModel process) async {
    final success = await _osqueryService.pauseProcess(process.name);
    if (success) {
      setState(() {
        final index = _processes.indexWhere((p) => p.pid == process.pid);
        if (index != -1) {
          _processes[index] = process.copyWith(isPaused: true);
        }
      });
    } else {
      _showErrorDialog(
        'Impossible de mettre en pause l\'application ${process.name}',
      );
    }
  }

  Future<void> _resumeProcess(ProcessModel process) async {
    final success = await _osqueryService.resumeProcess(process.name);
    if (success) {
      setState(() {
        final index = _processes.indexWhere((p) => p.pid == process.pid);
        if (index != -1) {
          _processes[index] = process.copyWith(isPaused: false);
        }
      });
    } else {
      _showErrorDialog(
        'Impossible de reprendre l\'application ${process.name}',
      );
    }
  }

  void _showErrorDialog(String message) {
    showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(),
            title: const Text('Erreur'),
            message: Text(message),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
    );
  }

  List<ProcessModel> get _filteredProcesses {
    List<ProcessModel> filtered = _processes;

    // Filter by state
    if (_filterState == 'paused') {
      filtered = filtered.where((p) => p.isPaused).toList();
    } else if (_filterState == 'running') {
      filtered = filtered.where((p) => !p.isPaused).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty && _searchQuery.length > 1) {
      filtered =
          filtered.where((process) {
            return process.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                process.command.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    return filtered;
  }

  Future<void> _killProcess(ProcessModel process) async {
    final confirmed = await showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(),
            title: const Text('Confirmer la terminaison'),
            message: Text(
              'Êtes-vous sûr de vouloir terminer le processus "${process.name}" (PID: ${process.pid}) ? Cette action est irréversible.',
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terminer'),
            ),
            secondaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
          ),
    );
    if (confirmed == true) {
      final success = await _osqueryService.killProcess(process.pid);
      if (success) {
        _backgroundFetchService.fetchData();
        _showSuccessDialog('Le processus a été terminé avec succès.');
      } else {
        _showErrorDialog('Échec de la terminaison du processus.');
      }
    }
  }

  void _showSuccessDialog(String message) {
    showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(),
            title: const Text('Succès'),
            message: Text(message),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (_refreshTimer == null && appState.autoRefresh) {
          _startAutoRefresh();
        } else if (_refreshTimer != null && !appState.autoRefresh) {
          _cancelRefreshTimer();
        } else if (_refreshTimer != null && appState.autoRefresh) {
          // If refreshInterval changed, restart timer
          _cancelRefreshTimer();
          _startAutoRefresh();
        }

        return MacosScaffold(
          toolBar: ToolBar(
            title: const Text('Poze - Gestionnaire d\'Applications'),
            titleWidth: 300,
            actions: [
              ToolBarIconButton(
                icon: const MacosIcon(CupertinoIcons.settings_solid),
                label: "Paramètres",
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const SettingsView(),
                    ),
                  );
                },
                showLabel: false,
              ),
              ToolBarIconButton(
                icon: const MacosIcon(CupertinoIcons.refresh),
                label: "Rafraîchir",
                onPressed: _loadData,
                showLabel: false,
              ),
              if (appState.autoRefresh)
                ToolBarIconButton(
                  label: 'Actualisation automatique active',
                  icon: const MacosIcon(CupertinoIcons.timer),
                  onPressed: null,
                  showLabel: false,
                ),
              ToolBarPullDownButton(
                label: 'Trier',
                icon: CupertinoIcons.sort_down,
                items: [
                  MacosPulldownMenuItem(
                    title: Text(
                      "${_sortBy == SortBy.cpuUsage ? '✓' : ''} Par CPU (décroissant)",
                    ),
                    onTap: () {
                      setState(() {
                        _sortBy = SortBy.cpuUsage;
                        _processes.sort(
                          (a, b) => b.cpuUsage.compareTo(a.cpuUsage),
                        );
                      });
                    },
                  ),
                  MacosPulldownMenuItem(
                    title: Text("${_sortBy == SortBy.name ? '✓' : ''} Par Nom"),
                    onTap: () {
                      setState(() {
                        _sortBy = SortBy.name;
                        _processes.sort((a, b) => a.name.compareTo(b.name));
                      });
                    },
                  ),
                  MacosPulldownMenuItem(
                    title: Text("${_sortBy == SortBy.pid ? '✓' : ''} Par PID"),
                    onTap: () {
                      setState(() {
                        _sortBy = SortBy.pid;
                        _processes.sort((a, b) => a.pid.compareTo(b.pid));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                // if (_isLoading) {
                //   return const Center(child: ProgressCircle());
                // }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: MacosSearchField(
                              placeholder: 'Rechercher une application...',
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                } else {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          MacosPulldownButton(
                            items: [
                              MacosPulldownMenuItem(
                                title: Text(
                                  "${_filterState == 'all' ? '✓ ' : ''}Tous",
                                ),
                                onTap:
                                    () => setState(() => _filterState = 'all'),
                              ),
                              MacosPulldownMenuItem(
                                title: Text(
                                  "${_filterState == 'running' ? '✓ ' : ''}Actifs",
                                ),
                                onTap:
                                    () => setState(
                                      () => _filterState = 'running',
                                    ),
                              ),
                              MacosPulldownMenuItem(
                                title: Text(
                                  "${_filterState == 'paused' ? '✓ ' : ''}En pause",
                                ),
                                onTap:
                                    () =>
                                        setState(() => _filterState = 'paused'),
                              ),
                            ],
                            title:
                                _filterState == 'all'
                                    ? 'Tous'
                                    : _filterState == 'running'
                                    ? 'Actifs'
                                    : 'En pause',
                          ),
                          const SizedBox(width: 16),
                          if (_hasSelection) ...[
                            PushButton(
                              controlSize: ControlSize.small,
                              color: MacosColors.systemOrangeColor,
                              onPressed: _batchPause,
                              child: const Text('Pause sélection'),
                            ),
                            const SizedBox(width: 8),
                            PushButton(
                              controlSize: ControlSize.small,
                              color: MacosColors.systemRedColor,
                              onPressed: _batchKill,
                              child: const Text('Terminer sélection'),
                            ),
                            const SizedBox(width: 8),
                            PushButton(
                              controlSize: ControlSize.small,
                              color: MacosColors.systemGrayColor,
                              onPressed: _clearSelection,
                              child: const Text('Annuler sélection'),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Text(
                            appState.autoRefresh
                                ? 'Auto-actualisation: ${appState.refreshInterval}s'
                                : 'Auto-actualisation: désactivée',
                            style: MacosTheme.of(context).typography.callout,
                          ),
                        ],
                      ),
                    ),
                    _buildSystemInfoCard(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildProcessList(scrollController)),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: MacosTheme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _systemStats.systemVersion,
                  style: MacosTheme.of(
                    context,
                  ).typography.title1.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.apps,
                      size: 18,
                      color: MacosColors.systemBlueColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Applications actives: ${_systemStats.totalProcesses}',
                      style: MacosTheme.of(context).typography.body,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 18,
                      color: MacosColors.systemGrayColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dernière mise à jour: ${_systemStats.timestamp.hour}:${_systemStats.timestamp.minute.toString().padLeft(2, '0')}',
                      style: MacosTheme.of(context).typography.body,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          CpuUsageChart(
            cpuUsage: _systemStats.totalCpuUsage,
            width: 220,
            height: 90,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessList(ScrollController scrollController) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filteredProcesses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final process = _filteredProcesses[index];
        final selected = _selectedPids.contains(process.pid);
        return GestureDetector(
          onTap: () => _toggleSelectProcess(process.pid),
          child: Container(
            decoration:
                selected
                    ? BoxDecoration(
                      border: Border.all(
                        color: MacosColors.systemBlueColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    )
                    : null,
            child: ProcessListItem(
              process: process,
              onPause: () => _pauseProcess(process),
              onResume: () => _resumeProcess(process),
              onKill: () => _killProcess(process),
              onInfo: () => _showProcessInfo(process),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showProcessInfo(ProcessModel process) async {
    showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(),
            title: Text('Chargement...'),
            message: const Text('Récupération des informations détaillées...'),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ),
    );
    final details = await _osqueryService.getProcessDetails(process);
    Navigator.of(context).pop(); // Close loading dialog

    if (details == null) {
      _showErrorDialog(
        'Impossible de récupérer les informations du processus.',
      );
      return;
    }

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ProcessDetailView(details: details),
      ),
    );
  }
}
