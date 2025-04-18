import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io';
import 'app.dart';

/// This method initializes macos_window_utils and styles window.
Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureMacosWindowUtils();

  if (Platform.isMacOS) {
    await TrayManager.instance.setIcon('assets/app_icon.png');
    await TrayManager.instance.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: 'Afficher'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quitter'),
        ],
      ),
    );
    TrayManager.instance.addListener(_PozeTrayListener());
  }

  runApp(const App());
}

class _PozeTrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        // Optionally bring window to front (implementation depends on window manager)
        break;
      case 'quit':
        TrayManager.instance.destroy();
        exit(0);
    }
  }
}
