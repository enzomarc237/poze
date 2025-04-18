import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:poze/views/settings_view.dart';
import 'package:provider/provider.dart';
import '../models/process_model.dart';
import '../models/system_stats.dart';
import '../services/process_service.dart';
import '../services/system_service.dart';
import '../widgets/process_list_item.dart';
import '../widgets/cpu_usage_chart.dart';
import '../app.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ProcessService _processService = ProcessService();
  final SystemService _systemService = SystemService();

  List<ProcessModel> _processes = [];
  SystemStats _systemStats = SystemStats.initial();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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
        (_) => _loadData(),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final processes = await _processService.getProcessesWithCpuUsage();
      final systemStats = await _systemService.getSystemStats();

      // Vérifier l'état de pause pour chaque processus
      for (int i = 0; i < processes.length; i++) {
        final process = processes[i];
        final isPaused = await _processService.isProcessPaused(process.pid);
        if (isPaused) {
          processes[i] = process.copyWith(isPaused: true);
        }
      }

      setState(() {
        _processes = processes;
        _systemStats = systemStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Afficher un message d'erreur
      if (mounted) {
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const FlutterLogo(),
                title: const Text('Erreur'),
                message: Text('Impossible de charger les données: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
        );
      }
    }
  }

  Future<void> _pauseProcess(ProcessModel process) async {
    final success = await _processService.pauseProcess(process.name);
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
    final success = await _processService.resumeProcess(process.name);
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
              controlSize: ControlSize.regular,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
    );
  }

  List<ProcessModel> get _filteredProcesses {
    if (_searchQuery.isEmpty) {
      return _processes;
    }

    return _processes.where((process) {
      return process.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          process.command.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (_refreshTimer == null && appState.autoRefresh) {
          _startAutoRefresh();
        } else if (_refreshTimer != null && !appState.autoRefresh) {
          _cancelRefreshTimer();
        }

        return MacosScaffold(
          toolBar: ToolBar(
            title: const Text('Poze - Gestionnaire d\'Applications'),
            titleWidth: 300,
            leading: MacosIconButton(
              icon: const MacosIcon(CupertinoIcons.settings),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const SettingsView()),
              ),
            ),
            actions: [
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
                    title: const Text('Par CPU (décroissant)'),
                    onTap: () {
                      setState(() {
                        _processes.sort(
                          (a, b) => b.cpuUsage.compareTo(a.cpuUsage),
                        );
                      });
                    },
                  ),
                  MacosPulldownMenuItem(
                    title: const Text('Par nom'),
                    onTap: () {
                      setState(() {
                        _processes.sort((a, b) => a.name.compareTo(b.name));
                      });
                    },
                  ),
                  MacosPulldownMenuItem(
                    title: const Text('Par PID'),
                    onTap: () {
                      setState(() {
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
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
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
        return ProcessListItem(
          process: process,
          onPause: () => _pauseProcess(process),
          onResume: () => _resumeProcess(process),
        );
      },
    );
  }
}
