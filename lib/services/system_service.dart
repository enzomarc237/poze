import 'dart:async';
import 'dart:io';
import 'package:process_run/process_run.dart';
import '../models/system_stats.dart';

class SystemService {
  final _shell = Shell();

  // Obtenir les statistiques système globales
  Future<SystemStats> getSystemStats() async {
    try {
      double cpuUsage = await _getCpuUsage();
      int appCount = await _getGuiAppCount();
      String osVersion = await _getOsVersion();

      return SystemStats(
        totalCpuUsage: cpuUsage,
        totalProcesses: appCount,
        systemVersion: osVersion,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors de la récupération des statistiques système: $e');
      return SystemStats.initial();
    }
  }

  // Obtenir l'utilisation CPU globale
  Future<double> _getCpuUsage() async {
    try {
      final result = await _shell.run('top -l 1 -n 0');

      // Rechercher la ligne contenant "CPU usage"
      final cpuLine = result.outLines.firstWhere(
        (line) => line.contains('CPU usage:'),
        orElse: () => '',
      );

      if (cpuLine.isEmpty) return 0.0;

      // Extraire le pourcentage d'utilisation
      final regex = RegExp(r'(\d+\.\d+)% user');
      final match = regex.firstMatch(cpuLine);

      if (match != null && match.groupCount >= 1) {
        return double.tryParse(match.group(1) ?? '0.0') ?? 0.0;
      }

      return 0.0;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisation CPU: $e');
      return 0.0;
    }
  }

  // Obtenir le nombre d'applications GUI
  Future<int> _getGuiAppCount() async {
    try {
      // Utiliser AppleScript pour compter uniquement les applications GUI
      final result = await _shell.run(
        'osascript -e \'tell application "System Events" to count of (every process whose background only is false)\'',
      );
      final countText = result.outText.trim();
      return int.tryParse(countText) ?? 0;
    } catch (e) {
      print('Erreur lors du comptage des applications: $e');
      return 0;
    }
  }

  // Obtenir la version du système d'exploitation
  Future<String> _getOsVersion() async {
    try {
      final result = await _shell.run('sw_vers -productVersion');
      return 'macOS ${result.outText.trim()}';
    } catch (e) {
      print('Erreur lors de la récupération de la version du système: $e');
      return 'macOS';
    }
  }
}
