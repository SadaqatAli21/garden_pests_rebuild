import 'dart:io';
import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class ConsentService {
  static Future<void> handleConsent() async {
    // Set test device ID for ads debugging (Mobile only)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['E0F65D1E4F74AFD41F224BB4751E8ADE'],
          ),
        );
      } catch (e) {
        debugPrint('MobileAds Init Error: $e');
      }
    }

    if (Platform.isIOS) {
      // iOS: Request GDPR (if needed) then ATT
      await _requestGDPR();
      await _requestATT();
    } else if (Platform.isMacOS) {
      // macOS: Request ATT (UMP is not supported)
      await _requestATT();
    } else if (Platform.isAndroid) {
      // Android: Request GDPR
      await _requestGDPR();
    }
  }

  static Future<void> _requestATT() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Small delay to ensure splash screen is fully rendered
        await Future.delayed(const Duration(milliseconds: 500));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ATT Error: $e');
    }
  }

  static Future<void> _requestGDPR() async {
    final params = ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        testIdentifiers: ['E0F65D1E4F74AFD41F224BB4751E8ADE'],
        debugGeography:
        DebugGeography.debugGeographyEea, // Forces EEA behavior for testing
      ),
    );

    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
          () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _loadForm(completer);
        } else {
          completer.complete();
        }
      },
          (FormError error) {
        debugPrint('Consent Error: ${error.message}');
        completer.complete();
      },
    );

    return completer.future;
  }

  static void _loadForm(Completer<void> completer) {
    ConsentForm.loadConsentForm(
          (ConsentForm consentForm) {
        consentForm.show((FormError? formError) {
          if (formError != null) {
            debugPrint('Consent Form Show Error: ${formError.message}');
          }
          completer.complete();
        });
      },
          (FormError formError) {
        debugPrint('Consent Form Load Error: ${formError.message}');
        completer.complete();
      },
    );
  }
}
