import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:poze/models/process_model.dart';
import 'package:poze/models/app_model.dart';

/// Service to interact with osquery via shell commands.
class OsqueryService {
  /// Checks if osqueryi binary is installed.
  Future<bool> isInstalled() async {
    try {
      final result = await Process.run('which', ['osqueryi']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Runs a SQL query against the processes table and returns [ProcessModel]s.
  Future<List<ProcessModel>> queryProcesses() async {
    final result = await Process.run(
      'osqueryi',
      ['--json', 'SELECT pid, name, path, cpu_time FROM processes;'],
    );
    if (result.exitCode != 0) {
      throw Exception('osqueryi error: \\${result.stderr}');
    }
    final rows = jsonDecode(result.stdout) as List<dynamic>;
    return rows
        .map((m) => ProcessModel.fromOsquery(m as Map<String, dynamic>))
        .toList();
  }

  /// Continuously polls [queryProcesses] every [interval].
  Stream<List<ProcessModel>> watchProcesses(Duration interval) async* {
    while (true) {
      try {
        yield await queryProcesses();
      } catch (_) {
        yield [];
      }
      await Future.delayed(interval);
    }
  }

  /// Queries installed applications via the apps table.
  Future<List<AppModel>> queryInstalledApps() async {
    final result = await Process.run(
      'osqueryi',
      ['--json', 'SELECT name, bundle_identifier, path, version FROM apps;'],
    );
    if (result.exitCode != 0) {
      throw Exception('osqueryi error: \\${result.stderr}');
    }
    final rows = jsonDecode(result.stdout) as List<dynamic>;
    return rows
        .map((m) => AppModel.fromOsquery(m as Map<String, dynamic>))
        .toList();
  }

  /// Continuously polls installed apps every [interval].
  Stream<List<AppModel>> watchInstalledApps(Duration interval) async* {
    while (true) {
      try {
        yield await queryInstalledApps();
      } catch (_) {
        yield [];
      }
      await Future.delayed(interval);
    }
  }

  /// Pause a process by name via killall -STOP
  Future<bool> pauseProcess(String name) async {
    final res = await Process.run('killall', ['-STOP', name]);
    return res.exitCode == 0;
  }

  /// Resume a process by name via killall -CONT
  Future<bool> resumeProcess(String name) async {
    final res = await Process.run('killall', ['-CONT', name]);
    return res.exitCode == 0;
  }

  /// Kill a process by PID via kill -9
  Future<bool> killProcess(String pid) async {
    final res = await Process.run('kill', ['-9', pid]);
    return res.exitCode == 0;
  }

  /// Batch pause processes
  Future<void> pauseProcesses(List<String> names) async {
    for (final name in names) {
      await pauseProcess(name);
    }
  }

  /// Batch kill processes
  Future<void> killProcesses(List<String> pids) async {
    for (final pid in pids) {
      await killProcess(pid);
    }
  }

  /// Get detailed info for a process, including open files and child processes
  Future<Map<String, dynamic>?> getProcessDetails(ProcessModel process) async {
    // Main process fields
    final sql = 'SELECT pid, name, path, cpu_time, memory_percent, '
        'resident_size AS mem_rss, thread_count '
        'FROM processes WHERE pid=${process.pid};';
    final result = await Process.run('osqueryi', ['--json', sql]);
    if (result.exitCode != 0) return null;
    final rows = jsonDecode(result.stdout) as List<dynamic>;
    if (rows.isEmpty) return null;
    final details = Map<String, dynamic>.from(rows.first as Map<String, dynamic>);
    // Open files
    final openSql = 'SELECT path FROM process_open_files WHERE pid=${process.pid};';
    final openRes = await Process.run('osqueryi', ['--json', openSql]);
    if (openRes.exitCode == 0) {
      final files = jsonDecode(openRes.stdout) as List<dynamic>;
      details['open_files'] = files.map((e) => e['path']?.toString() ?? '').toList();
    } else {
      details['open_files'] = <String>[];
    }
    // Child processes
    final childSql = 'SELECT pid, name FROM processes WHERE ppid=${process.pid};';
    final childRes = await Process.run('osqueryi', ['--json', childSql]);
    if (childRes.exitCode == 0) {
      final childs = jsonDecode(childRes.stdout) as List<dynamic>;
      details['children'] = childs
          .map((e) => {
                'pid': e['pid']?.toString() ?? '',
                'name': e['name']?.toString() ?? '',
              })
          .toList();
    } else {
      details['children'] = <Map<String, String>>[];
    }
    return details;
  }
}