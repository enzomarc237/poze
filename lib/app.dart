import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/home_view.dart';
import 'views/settings_view.dart';

class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _autoRefresh = true;
  // Intervalle de rafraîchissement en secondes
  int _refreshInterval = 50;

  // Constantes pour la validation
  static const int minRefreshInterval = 1; // Minimum 1 seconde
  static const int maxRefreshInterval = 3600; // Maximum 1 heure (3600 secondes)

  bool get isDarkMode => _isDarkMode;
  bool get autoRefresh => _autoRefresh;
  int get refreshInterval => _refreshInterval;

  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _autoRefresh = prefs.getBool('autoRefresh') ?? true;
    _refreshInterval = prefs.getInt('refreshInterval') ?? 50;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('autoRefresh', _autoRefresh);
    await prefs.setInt('refreshInterval', _refreshInterval);
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    saveSettings();
    notifyListeners();
  }

  void setAutoRefresh(bool value) {
    _autoRefresh = value;
    saveSettings();
    notifyListeners();
  }

  void setRefreshInterval(int value) {
    if (value >= minRefreshInterval && value <= maxRefreshInterval) {
      _refreshInterval = value;
      saveSettings();
      notifyListeners();
    }
  }

  // Méthode pour appliquer et sauvegarder les paramètres avec validation
  Future<bool> applySettings(bool autoRefresh, int refreshInterval) async {
    // Valider l'intervalle de rafraîchissement
    if (refreshInterval < minRefreshInterval ||
        refreshInterval > maxRefreshInterval) {
      return false;
    }

    _autoRefresh = autoRefresh;
    _refreshInterval = refreshInterval;
    await saveSettings();
    notifyListeners();
    return true;
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MacosApp(
            title: 'Poze',
            theme: MacosThemeData.light(),
            darkTheme: MacosThemeData.dark(),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const PozeMacosWindow(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class PozeMacosWindow extends StatefulWidget {
  const PozeMacosWindow({super.key});

  @override
  State<PozeMacosWindow> createState() => _PozeMacosWindowState();
}

class _PozeMacosWindowState extends State<PozeMacosWindow> {
  int _selectedViewIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      // sidebar: Sidebar(
      //   minWidth: 64,
      //   maxWidth: 64,
      //   isResizable: false,
      //   builder: (context, scrollController) {
      //     return SidebarItems(
      //       currentIndex: _selectedViewIndex,
      //       onChanged: (index) {
      //         setState(() {
      //           _selectedViewIndex = index;
      //         });
      //       },
      //       items: [
      //         SidebarItem(
      //           leading: MacosIcon(Icons.home),
      //           label: const SizedBox.shrink(),
      //         ),
      //         SidebarItem(
      //           leading: MacosIcon(Icons.settings),
      //           label: const SizedBox.shrink(),
      //         ),
      //       ],
      //     );
      //   },
      //   // Remove bottom controls for minimalism
      //   bottom: null,
      // ),
      child: IndexedStack(
        index: _selectedViewIndex,
        children: const [HomeView(), SettingsView()],
      ),
    );
  }
}
