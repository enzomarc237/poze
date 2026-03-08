import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poze/app.dart';
import 'package:flutter/material.dart';

void main() {
  setUp(() {
    // Provide a fake in-memory SharedPreferences store for each test.
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState', () {
    test('defaults are correct before preferences are loaded', () {
      final state = AppState();

      // Verify default values before async _loadSettings completes.
      expect(state.themeMode, ThemeMode.system);
      expect(state.autoRefresh, true);
      expect(state.refreshInterval, 50);
    });

    test('setRefreshInterval accepts values within allowed range', () {
      final state = AppState();

      state.setRefreshInterval(AppState.minRefreshInterval);
      expect(state.refreshInterval, AppState.minRefreshInterval);

      state.setRefreshInterval(AppState.maxRefreshInterval);
      expect(state.refreshInterval, AppState.maxRefreshInterval);

      state.setRefreshInterval(120);
      expect(state.refreshInterval, 120);
    });

    test('setRefreshInterval ignores values below minimum', () {
      final state = AppState();
      state.setRefreshInterval(100); // set a known value first
      state.setRefreshInterval(0);   // below min
      expect(state.refreshInterval, 100); // unchanged
    });

    test('setRefreshInterval ignores values above maximum', () {
      final state = AppState();
      state.setRefreshInterval(60);
      state.setRefreshInterval(AppState.maxRefreshInterval + 1);
      expect(state.refreshInterval, 60); // unchanged
    });

    test('setAutoRefresh updates and notifies', () {
      final state = AppState();
      int notifications = 0;
      state.addListener(() => notifications++);

      state.setAutoRefresh(false);

      expect(state.autoRefresh, false);
      expect(notifications, greaterThan(0));
    });

    test('setThemeMode updates and notifies', () {
      final state = AppState();
      int notifications = 0;
      state.addListener(() => notifications++);

      state.setThemeMode(ThemeMode.dark);

      expect(state.themeMode, ThemeMode.dark);
      expect(notifications, greaterThan(0));
    });

    test('applySettings returns true for valid interval', () async {
      final state = AppState();
      final result = await state.applySettings(true, 30);
      expect(result, true);
      expect(state.refreshInterval, 30);
      expect(state.autoRefresh, true);
    });

    test('applySettings returns false for interval below minimum', () async {
      final state = AppState();
      final result = await state.applySettings(true, 0);
      expect(result, false);
    });

    test('applySettings returns false for interval above maximum', () async {
      final state = AppState();
      final result = await state.applySettings(
        false,
        AppState.maxRefreshInterval + 1,
      );
      expect(result, false);
    });

    test('constants have expected boundary values', () {
      expect(AppState.minRefreshInterval, 1);
      expect(AppState.maxRefreshInterval, 3600);
    });

    test('loads persisted theme mode from shared preferences', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});

      final state = AppState();
      await state.ready;

      expect(state.themeMode, ThemeMode.dark);
    });

    test('loads persisted refresh interval from shared preferences', () async {
      SharedPreferences.setMockInitialValues({'refreshInterval': 120});

      final state = AppState();
      await state.ready;

      expect(state.refreshInterval, 120);
    });

    test('loads persisted autoRefresh=false from shared preferences', () async {
      SharedPreferences.setMockInitialValues({'autoRefresh': false});

      final state = AppState();
      await state.ready;

      expect(state.autoRefresh, false);
    });
  });
}
