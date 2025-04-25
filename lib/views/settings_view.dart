import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:process_run/cmd_run.dart';
import 'package:provider/provider.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import '../app.dart';
import '../services/process_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _refreshIntervalController;
  late MacosTabController _themeTabController;
  bool _startAtLogin = false;
  bool _startAtLoginLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshIntervalController = TextEditingController();
    _themeTabController = MacosTabController(initialIndex: 0, length: 3);
    _initStartAtLogin();
  }

  Future<void> _initStartAtLogin() async {
    try {
      final enabled = await launchAtStartup.isEnabled();
      setState(() {
        _startAtLogin = enabled;
        _startAtLoginLoading = false;
      });
    } catch (_) {
      setState(() {
        _startAtLogin = false;
        _startAtLoginLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    final refreshInterval = appState.refreshInterval;
    _refreshIntervalController.text = refreshInterval.toString();

    // Set the theme tab controller index based on appState.themeMode
    switch (appState.themeMode) {
      case ThemeMode.system:
        _themeTabController.index = 0;
        break;
      case ThemeMode.light:
        _themeTabController.index = 1;
        break;
      case ThemeMode.dark:
        _themeTabController.index = 2;
        break;
    }
  }

  @override
  void dispose() {
    _refreshIntervalController.dispose();
    _themeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return MacosScaffold(
          toolBar: ToolBar(
            title: const Text('Paramètres'),
            actions: [
              ToolBarIconButton(
                label: 'Sauvegarder',
                icon: const MacosIcon(CupertinoIcons.checkmark_circle),
                onPressed: () async {
                  // Récupérer et valider l'intervalle de rafraîchissement
                  final intervalText = _refreshIntervalController.text;
                  final interval = int.tryParse(intervalText);

                  if (interval == null) {
                    _showErrorDialog(
                      'Veuillez entrer un nombre valide pour l\'intervalle d\'actualisation.',
                    );
                    return;
                  }

                  // Appliquer les modifications avec la méthode améliorée applySettings
                  final success = await appState.applySettings(
                    appState.autoRefresh,
                    interval,
                  );

                  if (!success) {
                    _showErrorDialog(
                      'L\'intervalle doit être entre ${AppState.minRefreshInterval} et ${AppState.maxRefreshInterval} secondes.',
                    );
                    return;
                  }

                  // Afficher une notification de confirmation
                  if (mounted) {
                    _showSuccessDialog();
                  }
                },
                showLabel: false,
              ),
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Apparence',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Thème'),
                        const Spacer(),
                        MacosPopupButton<ThemeMode>(
                          value: appState.themeMode,
                          onChanged: (ThemeMode? mode) {
                            if (mode != null) {
                              appState.setThemeMode(mode);
                            }
                          },
                          items: const [
                            MacosPopupMenuItem(
                              value: ThemeMode.system,
                              child: Text('Système'),
                            ),
                            MacosPopupMenuItem(
                              value: ThemeMode.light,
                              child: Text('Clair'),
                            ),
                            MacosPopupMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Sombre'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Text('Démarrer au login'),
                        const Spacer(),
                        _startAtLoginLoading
                            ? const CupertinoActivityIndicator()
                            : MacosSwitch(
                              value: _startAtLogin,
                              onChanged: (value) async {
                                setState(() {
                                  _startAtLogin = value;
                                  _startAtLoginLoading = true;
                                });
                                try {
                                  if (value) {
                                    await launchAtStartup.enable();
                                  } else {
                                    await launchAtStartup.disable();
                                  }
                                } finally {
                                  setState(() {
                                    _startAtLoginLoading = false;
                                  });
                                }
                              },
                            ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Actualisation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Actualisation automatique'),
                        const Spacer(),
                        MacosSwitch(
                          value: appState.autoRefresh,
                          onChanged: (value) {
                            appState.setAutoRefresh(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Intervalle d\'actualisation (secondes)'),
                        const Spacer(),
                        SizedBox(
                          width: 80,
                          child: MacosTextField(
                            placeholder: 'Secondes',
                            keyboardType: TextInputType.number,
                            controller: _refreshIntervalController,
                            enabled: appState.autoRefresh,
                            maxLength: 4, // Permet jusqu'à 9999 secondes
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Min: ${AppState.minRefreshInterval}, Max: ${AppState.maxRefreshInterval} secondes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MacosColors.systemGrayColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(size: 56),
            title: const Text('Erreur'),
            message: Text(message),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('OK'),
            ),
          ),
    );
  }

  void _showSuccessDialog() {
    showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(size: 56),
            title: const Text('Paramètres sauvegardés'),
            message: const Text(
              'Vos paramètres ont été enregistrés avec succès.',
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('OK'),
            ),
          ),
    );
  }
}
