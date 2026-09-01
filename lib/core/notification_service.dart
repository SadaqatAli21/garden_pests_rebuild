import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      developer.log(
        "Timezone initialized: $timeZoneName",
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log("Error loading timezone: $e", name: 'NotificationService');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Check status first to decide if we should set the delegate for foreground notifications
    // Check status first using the NATIVE implementation for Darwin
    // permission_handler is sometimes out of sync, and init() needs the truth
    // to correctly set the foreground notification delegate.
    bool enrolledInNotifications = false;
    /*
    if (Platform.isIOS) {
      enrolledInNotifications =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: false, badge: false, sound: false) ??
          false;
    } else if (Platform.isMacOS) {
      // On macOS, we don't request with all false just to check status
      // as it might be unreliable. We'll use the checkPermissionStatus logic.
      final settings = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: false, badge: false, sound: false);
      enrolledInNotifications = settings ?? false;
    } else if (Platform.isAndroid) {
      enrolledInNotifications = await Permission.notification.isGranted;
    }
    */
    // Default to false at init to avoid any early permission-related system calls.
    // Real check happens in checkPermissionStatus() which is called at the end of init.
    enrolledInNotifications = false;
    if (Platform.isAndroid) {
      enrolledInNotifications = await Permission.notification.isGranted;
    }

    developer.log(
      "Initial authorization detected (Native): $enrolledInNotifications",
      name: 'NotificationService',
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: enrolledInNotifications,
      requestBadgePermission: enrolledInNotifications,
      requestAlertPermission: enrolledInNotifications,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        developer.log(
          "Notification tapped: ${response.payload}",
          name: 'NotificationService',
        );
      },
    );

    await checkPermissionStatus();
  }

  Future<bool> requestPermissions() async {
    bool granted = false;
    developer.log(
      "Starting permission request flow...",
      name: 'NotificationService',
    );

    if (Platform.isIOS || Platform.isMacOS) {
      // Direct native request first
      developer.log(
        "Requesting native permissions for Darwin platform...",
        name: 'NotificationService',
      );
      if (Platform.isIOS) {
        granted =
            await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
            >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
                false;
      } else if (Platform.isMacOS) {
        granted =
            await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
            >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
                false;
      }
      developer.log(
        "Native request result: $granted",
        name: 'NotificationService',
      );
    }

    // On macOS/iOS, we rely on the native plugin result
    if (!Platform.isMacOS && !Platform.isIOS) {
      // Sync with permission_handler and check for permanently denied
      final status = await Permission.notification.status;
      developer.log(
        "Permission status via permission_handler: $status",
        name: 'NotificationService',
      );

      if (status.isPermanentlyDenied) {
        developer.log(
          "Permission permanently denied. User must enable in settings.",
          name: 'NotificationService',
        );
      } else if (!granted && status.isDenied) {
        developer.log(
          "Requesting via permission_handler as fallback...",
          name: 'NotificationService',
        );
        final newStatus = await Permission.notification.request();
        granted = newStatus.isGranted;
        developer.log(
          "Permission_handler request result: $granted (New status: $newStatus)",
          name: 'NotificationService',
        );
      } else if (status.isGranted) {
        granted = true;
      }
    }

    if (Platform.isAndroid && granted) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    developer.log(
      "Permissions requested. Final granted status: $granted",
      name: 'NotificationService',
    );

    if (granted) {
      // Refresh the initialization to ensure foreground banners (Delegate) are set correctly
      developer.log(
        "Permissions granted, re-initializing to set foreground delegate...",
        name: 'NotificationService',
      );
      await init();
    } else {
      await checkPermissionStatus();
    }
    return granted;
  }

  Future<void> checkPermissionStatus() async {
    bool isGranted = false;
    String source = "native";

    if (Platform.isIOS || Platform.isAndroid) {
      source = "permission_handler";
      final status = await Permission.notification.status;
      isGranted = status.isGranted;
    } else if (Platform.isMacOS) {
      source = "macos_native";
      // permission_handler often lacks full macOS implementation
      // For MacOS, we assume it's granted if we are checking, or you can rely on the request result
      isGranted = true;
    }

    developer.log(
      "Checked notification authorization (via $source): $isGranted",
      name: 'NotificationService',
    );

    if (isGranted) {
      debugPrint("🔔 [NotificationService] Status: Authorized");
    } else {
      debugPrint("🔔 [NotificationService] Status: Not Authorized/Pending");
    }
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    developer.log(
      "Scheduling daily reminder for: ${time.hour}:${time.minute}",
      name: 'NotificationService',
    );

    await flutterLocalNotificationsPlugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    developer.log(
      "Scheduled DateTime: $scheduledDate",
      name: 'NotificationService',
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Time to Check Your Plants! 🌿',
        body: 'Take a moment to scan your garden for pests and keep it healthy.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_v3',
            'Daily Reminder',
            channelDescription: 'Reminds you to check your plants daily',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log(
        "Successfully scheduled reminder",
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        "Error scheduling reminder: $e",
        name: 'NotificationService',
        error: e,
      );
    }
  }

  Future<void> showTestNotification() async {
    developer.log(
      "Attempting to show test notification...",
      name: 'NotificationService',
    );
    try {
      await flutterLocalNotificationsPlugin.show(
        id: 888,
        title: 'Test Notification 🔔',
        body: 'If you see this, your notifications are working correctly!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_v3',
            'Daily Reminder',
            channelDescription: 'Reminds you to check your plants daily',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
      );
      developer.log(
        "Test notification 'show' call completed.",
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        "Error showing test notification: $e",
        name: 'NotificationService',
        error: e,
      );
      debugPrint("❌ [NotificationService] Error: $e");
    }
  }

  Future<void> scheduleTestNotification(int seconds) async {
    developer.log(
      "Scheduling test notification in $seconds seconds",
      name: 'NotificationService',
    );

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 999,
        title: 'Delayed Test 🔔',
        body: 'This notification was scheduled $seconds seconds ago.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_v3',
            'Daily Reminder',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      developer.log(
        "Test notification scheduled for: $scheduledDate",
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        "Error scheduling test notification: $e",
        name: 'NotificationService',
        error: e,
      );
    }
  }

  Future<void> cancelReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
