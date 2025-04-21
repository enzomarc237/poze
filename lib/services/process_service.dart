import 'dart:async';
import 'dart:io';
import 'package:process_run/process_run.dart';
import '../models/process_model.dart';

class ProcessService {
  // Ensure commands run within a shell environment
  final _shell = Shell(runInShell: true);

  // Cache for app icons to avoid repeated AppleScript calls
  final Map<String, String?> _iconPathCache = {};

  // Récupérer uniquement les applications GUI lancées par l'utilisateur
  Future<List<ProcessModel>> getRunningProcesses() async {
    try {
      // Utiliser AppleScript pour obtenir uniquement les applications GUI
      final result = await _shell.run(
        'osascript -e \'tell application "System Events" to get name of every process whose background only is false\'',
      );

      final appNames = result.outText.trim().split(', ');
      final List<ProcessModel> processes = [];

      // Pour chaque application, obtenir des informations supplémentaires
      for (final appName in appNames) {
        final sanitizedName = appName.replaceAll('"', '\\"');
        final pidResult = await _shell.run(
          'osascript -e \'tell application "System Events" to get unix id of process "$sanitizedName"\'',
        );

        if (pidResult.outText.trim().isEmpty) continue;

        final pid = pidResult.outText.trim();
        final cpuUsage = await _getProcessCpuUsage(pid);

        processes.add(
          ProcessModel(
            pid: pid,
            name: appName,
            command: appName,
            cpuUsage: cpuUsage,
          ),
        );
      }

      return processes;
    } catch (e) {
      // print('Erreur lors de la récupération des applications: $e');
      return [];
    }
  }

  // Obtenir l'utilisation CPU pour un PID spécifique
  Future<double> _getProcessCpuUsage(String pid) async {
    try {
      final result = await _shell.run('ps -o %cpu -p $pid');

      // Ignorer la première ligne (en-tête)
      final lines = result.outLines.skip(1).toList();
      if (lines.isEmpty) return 0.0;

      return double.tryParse(lines.first.trim()) ?? 0.0;
    } catch (e) {
      // print('Erreur lors de la récupération de l\'utilisation CPU: $e');
      return 0.0;
    }
  }

  // Get the icon path for a given application name using AppleScript, with caching and PNG conversion
  Future<String?> _getAppIconPath(String appName) async {
    if (_iconPathCache.containsKey(appName)) {
      print("Cached icon for $appName: \\${_iconPathCache[appName]}");
      return _iconPathCache[appName];
    }
    try {
      // Get the bundle path of the app
      final script = '''
        tell application "System Events"
          set appProc to first process whose name is "${appName.replaceAll('"', '\\"')}"
          set appPath to (POSIX path of (file of appProc))
        end tell
        return appPath
      ''';
      // Write to a temp file to avoid AppleScript escaping issues
      final tempDir = Directory.systemTemp;
      final tempScriptFile = File(
        '${tempDir.path}/poze_icon_script_${DateTime.now().millisecondsSinceEpoch}.applescript',
      );
      await tempScriptFile.writeAsString(script);
      final results = await _shell.run('osascript "${tempScriptFile.path}"');
      await tempScriptFile.delete();
      if (results.isEmpty || results.first.exitCode != 0) {
        _iconPathCache[appName] = null;
        return null;
      }
      final appPath = results.first.outText.trim();
      if (appPath.isEmpty) {
        _iconPathCache[appName] = null;
        return null;
      }
      // Try to find the icon file
      final iconPath = '$appPath/Contents/Resources/AppIcon.icns';
      String? icnsPath;
      if (await File(iconPath).exists()) {
        icnsPath = iconPath;
      } else {
        // Fallback: try generic app icon
        final genericIcon = '$appPath/Contents/Resources/${appName}.icns';
        if (await File(genericIcon).exists()) {
          icnsPath = genericIcon;
        }
      }
      if (icnsPath == null) {
        _iconPathCache[appName] = null;
        return null;
      }
      // Convert .icns to .png using sips (macOS built-in)
      final pngPath =
          '${tempDir.path}/poze_icon_${appName.replaceAll(' ', '_')}.png';
      final sipsResult = await Process.run('sips', [
        '-s',
        'format',
        'png',
        icnsPath,
        '--out',
        pngPath,
      ]);
      if (sipsResult.exitCode == 0 && await File(pngPath).exists()) {
        _iconPathCache[appName] = pngPath;
        return pngPath;
      } else {
        // If conversion fails, fallback to .icns (will not display in Flutter)
        _iconPathCache[appName] = icnsPath;
        return icnsPath;
      }
    } catch (e) {
      print(
        'Erreur lors de la récupération de l\'icône de l\'application: $e',
      ); // Only keep this print for appIcon
      _iconPathCache[appName] = null;
      return null;
    }
  }

  // Version optimisée pour obtenir l'utilisation CPU détaillée pour toutes les applications GUI
  Future<List<ProcessModel>> getProcessesWithCpuUsage() async {
    try {
      // Utiliser un script AppleScript plus complet pour obtenir les noms et PIDs en une seule commande
      final script = '''
        tell application "System Events"
          set appList to {}
          set processList to every process whose background only is false
          repeat with proc in processList
            set procName to name of proc
            set procId to unix id of proc
            set end of appList to procName & ":" & procId
          end repeat
          return appList
        end tell
      ''';

      File? tempScriptFile;
      ProcessResult? appListResult;

      try {
        // Create a temporary file
        final tempDir = Directory.systemTemp;
        tempScriptFile = File(
          '${tempDir.path}/poze_script_${DateTime.now().millisecondsSinceEpoch}.applescript',
        );

        // Write the script to the temporary file
        await tempScriptFile.writeAsString(script);

        // Execute osascript with the file path using run() which uses the shell
        final results = await _shell.run('osascript "${tempScriptFile.path}"');

        // Check for errors in the results list
        if (results.any((result) => result.exitCode != 0)) {
          final errorOutput = results.map((r) => r.errText).join('\n');
          // Clean up before throwing
          try {
            await tempScriptFile.delete();
          } catch (_) {}
          throw Exception('AppleScript execution failed: $errorOutput');
        }

        // Assuming the first result contains the output
        appListResult = results.first;

        // Original check (redundant now but kept for safety)
        if (appListResult.exitCode != 0) {
          throw Exception(
            'AppleScript execution failed: ${appListResult.errText}',
          );
        }
      } finally {
        // Ensure the temporary file is deleted
        try {
          await tempScriptFile?.delete();
        } catch (e) {
          // print('Error deleting temporary script file: $e');
        }
      }

      final appInfoList = appListResult.outText.trim().split(', ');

      // Obtenir l'utilisation CPU pour tous les processus en une seule commande
      final allPids = <String>[];
      final nameByPid = <String, String>{};

      for (final appInfo in appInfoList) {
        final parts = appInfo.split(':');
        if (parts.length == 2) {
          final name = parts[0];
          final pid = parts[1];
          allPids.add(pid);
          nameByPid[pid] = name;
        }
      }

      if (allPids.isEmpty) return [];

      // Obtenir l'utilisation CPU pour tous les PIDs en une seule commande
      final cpuResult = await _shell.run(
        'ps -o pid,%cpu -p ${allPids.join(',')}',
      );
      final cpuLines = cpuResult.outLines.skip(1).toList(); // Skip header

      final pidToCpu = <String, double>{};
      for (final line in cpuLines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final pid = parts[0];
          final cpu = double.tryParse(parts[1]) ?? 0.0;
          pidToCpu[pid] = cpu;
        }
      }

      // Vérifier l'état de pause pour tous les processus en une seule commande
      final stateResult = await _shell.run(
        'ps -o pid,state -p ${allPids.join(',')}',
      );
      final stateLines = stateResult.outLines.skip(1).toList(); // Skip header

      final pidToState = <String, String>{};
      for (final line in stateLines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final pid = parts[0];
          final state = parts[1];
          pidToState[pid] = state;
        }
      }

      // Construire la liste des processus
      final processes = <ProcessModel>[];
      for (final pid in allPids) {
        final name = nameByPid[pid] ?? 'Unknown';
        final cpuUsage = pidToCpu[pid] ?? 0.0;
        final isPaused = pidToState[pid] == 'T';
        final iconPath = await _getAppIconPath(name);
        processes.add(
          ProcessModel(
            pid: pid,
            name: name,
            command: name,
            cpuUsage: cpuUsage,
            isPaused: isPaused,
            iconPath: iconPath,
          ),
        );
      }

      // Trier par utilisation CPU
      processes.sort((a, b) => b.cpuUsage.compareTo(a.cpuUsage));

      return processes;
    } catch (e) {
      // print('Erreur lors de la récupération des applications: $e');
      return [];
    }
  }

  // Mettre en pause un processus via killall -STOP
  Future<bool> pauseProcess(String processName) async {
    try {
      final results = await _shell.run('killall -STOP "$processName"');
      return results.every((result) => result.exitCode == 0);
    } catch (e) {
      // print('Erreur lors de la mise en pause du processus: $e');
      return false;
    }
  }

  // Reprendre un processus mis en pause via killall -CONT
  Future<bool> resumeProcess(String processName) async {
    try {
      final results = await _shell.run('killall -CONT "$processName"');
      return results.every((result) => result.exitCode == 0);
    } catch (e) {
      // print('Erreur lors de la reprise du processus: $e');
      return false;
    }
  }

  // Vérifier l'état de pause pour plusieurs processus en une seule commande
  Future<Map<String, bool>> areProcessesPaused(List<String> pids) async {
    if (pids.isEmpty) return {};

    try {
      final result = await _shell.run('ps -o pid,state -p ${pids.join(',')}');
      final lines = result.outLines.skip(1); // Skip header

      final pauseStates = <String, bool>{};
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final pid = parts[0];
          final state = parts[1];
          pauseStates[pid] = state == 'T';
        }
      }

      return pauseStates;
    } catch (e) {
      // print('Erreur lors de la vérification de l\'état des processus: $e');
      return {};
    }
  }

  // Call this on app startup to load any previously cached PNG icons
  Future<void> loadPersistentIconCache() async {
    final tempDir = Directory.systemTemp;
    final pngFiles = tempDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.png') && f.path.contains('poze_icon_'),
    );
    for (final file in pngFiles) {
      final nameMatch = RegExp(r'poze_icon_(.*)\.png').firstMatch(file.path);
      if (nameMatch != null) {
        final appName = nameMatch.group(1)?.replaceAll('_', ' ');
        if (appName != null && !_iconPathCache.containsKey(appName)) {
          _iconPathCache[appName] = file.path;
        }
      }
    }
  }

  // Call this on app exit or periodically to clean up old PNG icons
  Future<void> cleanupOldPngIcons() async {
    final tempDir = Directory.systemTemp;
    final pngFiles = tempDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.png') && f.path.contains('poze_icon_'),
    );
    for (final file in pngFiles) {
      try {
        await file.delete();
      } catch (_) {}
    }
    _iconPathCache.clear();
  }
}
