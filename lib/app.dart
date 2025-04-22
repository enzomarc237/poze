import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/home_view.dart';
import 'views/settings_view.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _autoRefresh = true;
  // Intervalle de rafraîchissement en secondes
  int _refreshInterval = 50;

  // Constantes pour la validation
  static const int minRefreshInterval = 1; // Minimum 1 seconde
  static const int maxRefreshInterval = 3600; // Maximum 1 heure (3600 secondes)

  ThemeMode get themeMode => _themeMode;
  bool get autoRefresh => _autoRefresh;
  int get refreshInterval => _refreshInterval;

  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    _autoRefresh = prefs.getBool('autoRefresh') ?? true;
    _refreshInterval = prefs.getInt('refreshInterval') ?? 50;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    switch (_themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
    }
    await prefs.setString('themeMode', themeString);
    await prefs.setBool('autoRefresh', _autoRefresh);
    await prefs.setInt('refreshInterval', _refreshInterval);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
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
            themeMode: appState.themeMode,
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
