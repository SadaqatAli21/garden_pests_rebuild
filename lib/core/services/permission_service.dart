import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_macos_permissions/flutter_macos_permissions.dart' as mp;
import 'dart:io';

import '../../widgets/app_dialogs.dart';

class PermissionService {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (Platform.isMacOS) {
      final status = await mp.FlutterMacosPermissions.cameraStatus();

      if (status == 'authorized') {
        return true;
      }

      if (status == 'denied') {
        if (context.mounted) {
          await AppDialogs.showPermissionDeniedDialog(context);
        }
        return false;
      }

      /*
      // Show custom consent dialog first
      bool? userConsent = false;
      if (context.mounted) {
        userConsent = await AppDialogs.showPermissionConsentDialog(
          context,
          type: PermissionType.camera,
        );
      }
      */
      bool userConsent = true; // Direct to system dialog

      if (userConsent == true) {
        final dynamic result = await mp.FlutterMacosPermissions.requestCamera();
        return result == true || result == 'authorized';
      }
      return false;
    }

    return _requestCustomPermission(
      context,
      permission: Permission.camera,
      type: PermissionType.camera,
    );
  }

  static Future<bool> requestPhotosPermission(BuildContext context) async {
    // On macOS, bypass permission_handler as it's missing implementation
    // and Photos are handled via entitlements.
    if (Platform.isMacOS) {
      return true;
    }

    // On iOS 14+, we use photos
    // On Android, simplified as well
    Permission permission = Platform.isIOS ? Permission.photos : Permission.storage;

    // For Android 13+, use photos instead of storage
    if (Platform.isAndroid) {
      permission = Permission.photos;
    }

    return _requestCustomPermission(
      context,
      permission: permission,
      type: PermissionType.gallery,
    );
  }

  static Future<bool> requestNotificationPermission(
      BuildContext context,
      ) async {
    // For macOS, use flutter_macos_permissions as requested
    if (Platform.isMacOS) {
      debugPrint("🔔 [PermissionService] Checking Notification status on macOS...");
      final status = await mp.FlutterMacosPermissions.notificationStatus();
      debugPrint("🔔 [PermissionService] Current status: $status");

      if (status == 'authorized' || status == 'provisional') {
        return true;
      }

      if (status == 'denied') {
        debugPrint("🔔 [PermissionService] Permission denied. Showing dialog.");
        if (context.mounted) {
          await AppDialogs.showPermissionDeniedDialog(context);
        }
        return false;
      }

      /*
      // Show custom consent dialog first
      debugPrint("🔔 [PermissionService] Status unknown/notDetermined. Showing consent dialog.");
      bool? userConsent = false;
      if (context.mounted) {
        userConsent = await AppDialogs.showPermissionConsentDialog(
          context,
          type: PermissionType.notification,
        );
      }
      */
      bool userConsent = true; // Direct to system dialog

      debugPrint("🔔 [PermissionService] User consent: $userConsent");
      if (userConsent == true) {
        debugPrint("🔔 [PermissionService] Requesting native macOS notification permission...");
        final dynamic result = await mp.FlutterMacosPermissions.requestNotification();
        debugPrint("🔔 [PermissionService] Native request result: $result");
        return result == true || result == 'authorized' || result == 'provisional';
      }
      return false;
    }

    return _requestCustomPermission(
      context,
      permission: Permission.notification,
      type: PermissionType.notification,
    );
  }

  static Future<bool> _requestCustomPermission(
      BuildContext context, {
        required Permission permission,
        required PermissionType type,
      }) async {
    // Permission handler is missing implementation on macOS in this project.
    // Redirect or bypass for macOS to prevent MissingPluginException.
    if (Platform.isMacOS) {
      if (type == PermissionType.notification) {
        return requestNotificationPermission(context);
      }
      if (type == PermissionType.camera) {
        return requestCameraPermission(context);
      }
      if (type == PermissionType.gallery) {
        return requestPhotosPermission(context);
      }
    }

    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await AppDialogs.showPermissionDeniedDialog(context);
      }
      return false;
    }

    // Show custom consent dialog first (Disabled per user request)
    /*
    bool? userConsent = false;
    if (context.mounted) {
      userConsent = await AppDialogs.showPermissionConsentDialog(
        context,
        type: type,
      );
    }
    */
    bool userConsent = true; // Bypass and go direct to system dialog

    if (userConsent == true) {
      final newStatus = await permission.request();
      if (newStatus.isGranted) {
        return true;
      } else if (newStatus.isPermanentlyDenied) {
        if (context.mounted) {
          await AppDialogs.showPermissionDeniedDialog(context);
        }
      }
    }

    return false;
  }
}

enum PermissionType { camera, gallery, notification }
