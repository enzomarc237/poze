import 'dart:async';
import 'dart:convert';
import 'package:process_run/process_run.dart';
import '../models/process_model.dart';

class ProcessService {
  final _shell = Shell();

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
      print('Erreur lors de la récupération des applications: $e');
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
      print('Erreur lors de la récupération de l\'utilisation CPU: $e');
      return 0.0;
    }
  }

  // Obtenir l'utilisation CPU détaillée pour toutes les applications GUI
  Future<List<ProcessModel>> getProcessesWithCpuUsage() async {
    try {
      // Récupérer la liste des applications GUI directement
      final appListResult = await _shell.run(
        'osascript -e \'tell application "System Events" to get the name of every process whose background only is false\'',
      );
      final appNames = appListResult.outText.trim().split(', ');

      final List<ProcessModel> processes = [];

      // Pour chaque application, obtenir son PID et l'utilisation CPU
      for (final appName in appNames) {
        try {
          final sanitizedName = appName.replaceAll('"', '\\"');

          // Obtenir le PID pour cette application
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
        } catch (e) {
          print('Erreur lors du traitement de l\'application $appName: $e');
          // Continuer avec la prochaine application
          continue;
        }
      }

      // Trier par utilisation CPU
      processes.sort((a, b) => b.cpuUsage.compareTo(a.cpuUsage));

      return processes;
    } catch (e) {
      print('Erreur lors de la récupération des applications: $e');
      return [];
    }
  }

  // Mettre en pause un processus via killall -STOP
  Future<bool> pauseProcess(String processName) async {
    try {
      final results = await _shell.run('killall -STOP "$processName"');
      return results.every((result) => result.exitCode == 0);
    } catch (e) {
      print('Erreur lors de la mise en pause du processus: $e');
      return false;
    }
  }

  // Reprendre un processus mis en pause via killall -CONT
  Future<bool> resumeProcess(String processName) async {
    try {
      final results = await _shell.run('killall -CONT "$processName"');
      return results.every((result) => result.exitCode == 0);
    } catch (e) {
      print('Erreur lors de la reprise du processus: $e');
      return false;
    }
  }

  // Vérifier si un processus est en pause
  Future<bool> isProcessPaused(String pid) async {
    try {
      // Utiliser ps pour vérifier l'état du processus
      final result = await _shell.run('ps -o state= -p $pid');
      // T indique généralement un processus arrêté/en pause
      return result.outText.trim() == 'T';
    } catch (e) {
      print('Erreur lors de la vérification de l\'état du processus: $e');
      return false;
    }
  }
}
