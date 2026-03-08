import 'package:flutter_test/flutter_test.dart';
import 'package:poze/models/process_model.dart';
import 'package:poze/models/app_model.dart';
import 'package:poze/models/system_stats.dart';

void main() {
  group('ProcessModel', () {
    test('fromAppleScript creates model with correct fields', () {
      final model = ProcessModel.fromAppleScript(
        pid: '123',
        name: 'Safari',
        cpuUsage: 5.5,
      );

      expect(model.pid, '123');
      expect(model.name, 'Safari');
      expect(model.command, 'Safari');
      expect(model.cpuUsage, 5.5);
      expect(model.isPaused, false);
      expect(model.iconPath, isNull);
    });

    test('fromOsquery creates model from complete map', () {
      final row = {
        'pid': '42',
        'name': 'Finder',
        'path': '/System/Library/CoreServices/Finder.app',
        'cpu_time': 12.3,
      };

      final model = ProcessModel.fromOsquery(row);

      expect(model.pid, '42');
      expect(model.name, 'Finder');
      expect(model.command, '/System/Library/CoreServices/Finder.app');
      expect(model.cpuUsage, 12.3);
    });

    test('fromOsquery handles integer cpu_time', () {
      final row = {
        'pid': '1',
        'name': 'launchd',
        'path': '/sbin/launchd',
        'cpu_time': 100,
      };

      final model = ProcessModel.fromOsquery(row);

      expect(model.cpuUsage, 100.0);
    });

    test('fromOsquery uses empty strings for missing fields', () {
      final model = ProcessModel.fromOsquery({});

      expect(model.pid, '');
      expect(model.name, '');
      expect(model.command, '');
      expect(model.cpuUsage, 0.0);
    });

    test('fromOsquery handles null cpu_time', () {
      final row = {'pid': '5', 'name': 'test', 'path': '/test', 'cpu_time': null};
      final model = ProcessModel.fromOsquery(row);
      expect(model.cpuUsage, 0.0);
    });

    test('copyWith returns new instance with updated fields', () {
      final original = ProcessModel(
        pid: '1',
        name: 'App',
        command: 'app',
        cpuUsage: 1.0,
        isPaused: false,
      );

      final paused = original.copyWith(isPaused: true, cpuUsage: 2.5);

      expect(paused.pid, '1');
      expect(paused.name, 'App');
      expect(paused.isPaused, true);
      expect(paused.cpuUsage, 2.5);
      // Original is unchanged
      expect(original.isPaused, false);
      expect(original.cpuUsage, 1.0);
    });

    test('copyWith preserves optional fields when not specified', () {
      final original = ProcessModel(
        pid: '1',
        name: 'App',
        command: 'app',
        cpuUsage: 1.0,
        iconPath: '/tmp/icon.png',
        memoryKb: 4096,
        threads: 4,
        openFiles: ['/dev/null'],
      );

      final updated = original.copyWith(cpuUsage: 9.9);

      expect(updated.iconPath, '/tmp/icon.png');
      expect(updated.memoryKb, 4096);
      expect(updated.threads, 4);
      expect(updated.openFiles, ['/dev/null']);
    });

    test('toString contains key fields', () {
      final model = ProcessModel(
        pid: '7',
        name: 'Dock',
        command: 'Dock',
        cpuUsage: 0.5,
        isPaused: false,
      );

      final str = model.toString();
      expect(str, contains('7'));
      expect(str, contains('Dock'));
      expect(str, contains('0.5'));
    });
  });

  group('AppModel', () {
    test('fromOsquery creates model with all fields', () {
      final row = {
        'name': 'Xcode',
        'bundle_identifier': 'com.apple.dt.Xcode',
        'path': '/Applications/Xcode.app',
        'version': '15.0',
      };

      final model = AppModel.fromOsquery(row);

      expect(model.name, 'Xcode');
      expect(model.bundleIdentifier, 'com.apple.dt.Xcode');
      expect(model.path, '/Applications/Xcode.app');
      expect(model.version, '15.0');
    });

    test('fromOsquery uses empty strings for missing keys', () {
      final model = AppModel.fromOsquery({});

      expect(model.name, '');
      expect(model.bundleIdentifier, '');
      expect(model.path, '');
      expect(model.version, '');
    });

    test('copyWith returns updated instance without mutating original', () {
      final original = AppModel(
        name: 'TextEdit',
        bundleIdentifier: 'com.apple.TextEdit',
        path: '/System/Applications/TextEdit.app',
        version: '1.18',
      );

      final updated = original.copyWith(version: '1.19');

      expect(updated.version, '1.19');
      expect(original.version, '1.18');
      expect(updated.name, 'TextEdit');
    });

    test('toString contains all key fields', () {
      final model = AppModel(
        name: 'Mail',
        bundleIdentifier: 'com.apple.mail',
        path: '/System/Applications/Mail.app',
        version: '16.0',
      );

      final str = model.toString();
      expect(str, contains('Mail'));
      expect(str, contains('com.apple.mail'));
    });
  });

  group('SystemStats', () {
    test('initial factory returns sensible defaults', () {
      final stats = SystemStats.initial();

      expect(stats.totalCpuUsage, 0.0);
      expect(stats.totalProcesses, 0);
      expect(stats.systemVersion, 'macOS');
      // timestamp should be close to now
      expect(
        stats.timestamp.difference(DateTime.now()).abs().inSeconds,
        lessThan(2),
      );
    });

    test('constructor stores all provided values', () {
      final ts = DateTime(2025, 1, 15, 10, 30);
      final stats = SystemStats(
        totalCpuUsage: 42.5,
        totalProcesses: 80,
        systemVersion: 'macOS 14.0',
        timestamp: ts,
      );

      expect(stats.totalCpuUsage, 42.5);
      expect(stats.totalProcesses, 80);
      expect(stats.systemVersion, 'macOS 14.0');
      expect(stats.timestamp, ts);
    });

    test('toString contains usage and process count', () {
      final stats = SystemStats(
        totalCpuUsage: 33.0,
        totalProcesses: 50,
        systemVersion: 'macOS 13.6',
        timestamp: DateTime.now(),
      );

      final str = stats.toString();
      expect(str, contains('33.0'));
      expect(str, contains('50'));
    });
  });
}
