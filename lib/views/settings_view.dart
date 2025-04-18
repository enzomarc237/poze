import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../app.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _refreshIntervalController;

  @override
  void initState() {
    super.initState();
    // On initialise le contrôleur avec la valeur actuelle
    _refreshIntervalController = TextEditingController();

    // La valeur sera définie dans didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mise à jour du contrôleur avec la valeur actuelle de AppState
    final refreshInterval =
        Provider.of<AppState>(context, listen: false).refreshInterval;
    _refreshIntervalController.text = refreshInterval.toString();
  }

  @override
  void dispose() {
    _refreshIntervalController.dispose();
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
