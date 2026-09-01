import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../../core/notification_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../data/database_helper.dart';
import '../data/models/plant_remiinder.dart';

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<PlantReminder>>((ref) {
  return ReminderNotifier();
});

class ReminderNotifier extends StateNotifier<List<PlantReminder>> {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  ReminderNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    // Force permission check before initializing notifications for reminders
    await _notifService.requestPermissions();
    await loadReminders();
  }

  Future<void> loadReminders() async {
    state = await _db.getReminders();
  }

  Future<void> addReminder(PlantReminder reminder) async {
    final id = await _db.insertReminder(reminder);
    final newReminder = reminder.copyWith(id: id);
    state = [...state, newReminder];
    _scheduleNotifications(newReminder);
  }

  Future<void> updateReminder(PlantReminder reminder) async {
    await _db.updateReminder(reminder);
    state = [
      for (final r in state)
        if (r.id == reminder.id) reminder else r
    ];

    if (reminder.isActive) {
      _scheduleNotifications(reminder);
    } else {
      _cancelNotifications(reminder);
    }
  }

  Future<void> deleteReminder(int id) async {
    final reminder = state.firstWhere((r) => r.id == id);
    await _db.deleteReminder(id);
    state = state.where((r) => r.id != id).toList();
    _cancelNotifications(reminder);
  }

  Future<void> _scheduleNotifications(PlantReminder reminder) async {
    _cancelNotifications(reminder);

    if (!reminder.isActive) return;

    for (int i = 0; i < reminder.times.length; i++) {
      final timeStr = reminder.times[i];
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifService.flutterLocalNotificationsPlugin.zonedSchedule(
        id: reminder.id! * 100 + i,
        title: 'Water your plant! 🌿',
        body: 'Time to water your ${reminder.plantName}',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'watering_channel',
            'Watering Reminders',
            channelDescription: 'Daily notifications for plant care',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _cancelNotifications(PlantReminder reminder) async {
    for (int i = 0; i < 10; i++) {
      await _notifService.flutterLocalNotificationsPlugin.cancel(id: reminder.id! * 100 + i);
    }
  }
}
