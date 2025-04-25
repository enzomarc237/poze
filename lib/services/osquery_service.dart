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
}