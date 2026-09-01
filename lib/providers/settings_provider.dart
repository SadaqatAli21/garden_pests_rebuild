import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import '../../core/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../core/app_constrants.dart';

class SettingsState {
  final bool historyAutoSave;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;

  SettingsState({
    this.historyAutoSave = true,
    this.reminderEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
  });

  SettingsState copyWith({
    bool? historyAutoSave,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
  }) {
    return SettingsState(
      historyAutoSave: historyAutoSave ?? this.historyAutoSave,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final historyAutoSave =
        prefs.getBool(AppConstants.historyAutoSaveKey) ?? true;
    final reminderEnabled =
        prefs.getBool(AppConstants.reminderEnabledKey) ?? false;

    final timeString = prefs.getString(AppConstants.reminderTimeKey);
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);

    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        reminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    state = SettingsState(
      historyAutoSave: historyAutoSave,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
    );

    // Re-schedule if enabled to ensure it's active
    if (reminderEnabled) {
      NotificationService().scheduleDailyReminder(reminderTime);
    }
  }

  Future<void> setHistoryAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.historyAutoSaveKey, value);
    state = state.copyWith(historyAutoSave: value);
  }

  Future<void> toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.reminderEnabledKey, value);

    state = state.copyWith(reminderEnabled: value);

    if (value) {
      await NotificationService().scheduleDailyReminder(state.reminderTime);
    } else {
      await NotificationService().cancelReminders();
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = '${time.hour}:${time.minute}';
    await prefs.setString(AppConstants.reminderTimeKey, timeString);

    state = state.copyWith(reminderTime: time);

    if (state.reminderEnabled) {
      await NotificationService().scheduleDailyReminder(time);
    }
  }

  Future<void> testNotification() async {
    // Scheduling for 10 seconds from now to test background/lock screen
    await NotificationService().scheduleTestNotification(10);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
      (ref) {
    return SettingsNotifier();
  },
);
