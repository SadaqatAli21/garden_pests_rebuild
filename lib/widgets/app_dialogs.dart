import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/permission_service.dart';
import '../core/app_constrants.dart';
import '../core/services/analytics_services.dart';
import 'no_internet_dialog.dart';

class AppDialogs {
  static Future<void> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required VoidCallback onConfirm,
        String? confirmText,
        String? cancelText,
        bool isDestructive = false,
      }) async {
    final l10n = AppLocalizations.of(context);
    final confirmBtn = confirmText ?? l10n?.continueText ?? "Confirm";
    final cancelBtn = cancelText ?? l10n?.cancel ?? "Cancel";
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.outfit()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              AnalyticsService.instance.logEvent('app_dialog_cancel');
              Navigator.pop(ctx);
            },
            child: Text(
              cancelBtn,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              AnalyticsService.instance.logEvent('app_dialog_confirm');
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              confirmBtn,
              style: GoogleFonts.outfit(
                color: isDestructive ? Colors.red : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> showExitDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.exitAppTitle ?? "Exit App?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n?.exitAppMessage ?? "Are you sure you want to exit the application?",
          style: GoogleFonts.outfit(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              AnalyticsService.instance.logEvent('app_dialog_exit_cancel');
              Navigator.pop(ctx, false);
            },
            child: Text(
              l10n?.cancel ?? "Cancel",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              AnalyticsService.instance.logEvent('app_dialog_exit_confirm');
              Navigator.pop(ctx, true);
            },
            child: Text(
              l10n?.done ?? "Exit",
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  /// Shows a beautiful feedback dialog. On submit, opens the email client
  /// with the feedback pre-filled.
  static Future<void> showFeedbackDialog(
      BuildContext context, {
        String supportEmail = 'mahboobk522@gmail.com',
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => _FeedbackDialog(supportEmail: supportEmail),
    );
  }

  /// Attractive star-rating Rate Us dialog → opens Play Store on submit.
  static Future<void> showRateUsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => const _RateUsDialog(),
    );
  }

  /// Share app dialog with a pre-built message and copy/share action.
  static Future<void> showShareDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => const _ShareDialog(),
    );
  }

  /// Shows a beautiful permission consent dialog.
  static Future<bool> showPermissionConsentDialog(
      BuildContext context, {
        required PermissionType type,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => _PermissionConsentDialog(type: type),
    );
    return result ?? false;
  }

  /// Shows a dialog when permission is permanently denied, directing to settings.
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n?.permissionRequired ?? "Permission Required",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n?.permissionDenied ??
              "To use this feature, please enable the required permission in your device settings.",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AnalyticsService.instance.logEvent(
                'app_dialog_perm_denied_later',
              );
              Navigator.pop(ctx);
            },
            child: Text(
              l10n?.later ?? "Later",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AnalyticsService.instance.logEvent(
                'app_dialog_perm_denied_settings',
              );
              Navigator.pop(ctx);
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n?.settings ?? "Settings",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  /// Shows a dialog when there is no internet connection.
  static Future<void> showNoInternetDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const NoInternetDialog(),
    );
  }

  /// Robustly opens app settings with fallbacks for different platforms.
  static Future<void> _openAppSettings() async {
    bool opened = false;
    try {
      debugPrint("🛠️ [AppDialogs] Attempting to open App Settings via plugin...");
      opened = await openAppSettings();
    } catch (e) {
      debugPrint("⚠️ [AppDialogs] Plugin openAppSettings() failed or missing: $e");
    }

    if (!opened) {
      debugPrint("🛠️ [AppDialogs] Plugin failed or returned false. Trying fallbacks...");
      try {
        if (Platform.isIOS) {
          final url = Uri.parse('app-settings:');
          await launchUrl(url);
        } else if (Platform.isMacOS) {
          // Try modern and legacy macOS Privacy & Security URI schemes
          final urls = [
            'x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_All', // Ventura+
            'x-apple.systempreferences:com.apple.preference.security?Privacy_All', // Legacy
          ];

          for (final urlStr in urls) {
            final uri = Uri.parse(urlStr);
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
                debugPrint("✅ [AppDialogs] Opened Mac settings via: $urlStr");
                return;
              }
            } catch (_) {}
          }

          // Ultimate fallback for Mac: try basic settings URI
          debugPrint("🛠️ [AppDialogs] Trying Mac ultimate fallback...");
          await launchUrl(Uri.parse('x-apple.systempreferences:'));
        }
      } catch (e) {
        debugPrint("❌ [AppDialogs] Fallback failed: $e");
      }
    } else {
      debugPrint("✅ [AppDialogs] App Settings opened successfully via plugin.");
    }
  }
}

// ─── Feedback Dialog ─────────────────────────────────────────────────────────

class _FeedbackDialog extends StatefulWidget {
  final String supportEmail;
  const _FeedbackDialog({required this.supportEmail});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late AnimationController _anim;
  late Animation<double> _scale;

  int _catIdx = 0;
  bool _sending = false;

  List<_Cat> _cats(AppLocalizations? l10n) => [
    _Cat(l10n?.catBug ?? 'Bug Report', Icons.bug_report_outlined, const Color(0xFFE53935)),
    _Cat(l10n?.catIdea ?? 'Suggestion', Icons.lightbulb_outlined, const Color(0xFFFF9800)),
    _Cat(l10n?.catQuestion ?? 'Question', Icons.chat_bubble_outline, const Color(0xFF2196F3)),
    _Cat(l10n?.catOther ?? 'Other', Icons.more_horiz_rounded, const Color(0xFF9E9E9E)),
  ];

  static const _emojis = ['😞', '😕', '😐', '😊', '🤩'];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      final l10n = AppLocalizations.of(context);
      _snack(l10n?.yourMessage ?? 'Please write your feedback first.', Colors.red.shade700);
      return;
    }
    setState(() => _sending = true);

    final l10n = AppLocalizations.of(context);
    final cat = _cats(l10n)[_catIdx].label;
    final subject = Uri.encodeComponent('[$cat] Feedback — ${AppConstants.appName}');
    final body = Uri.encodeComponent(
      '${l10n?.category ?? "Category"}: $cat\n\n${l10n?.yourMessage ?? "Feedback"}:\n$text\n\n---\nSent from ${AppConstants.appName} v1.0.0',
    );

    final uri = Uri.parse(
      'mailto:${widget.supportEmail}?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } else {
      // Fallback: Copy email to clipboard
      await Clipboard.setData(ClipboardData(text: widget.supportEmail));
      if (mounted) {
        setState(() => _sending = false);
        _snack(
          l10n?.error ?? 'Could not open email app. Support email copied to clipboard.',
          Colors.orange.shade800,
        );
      }
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00897B);
    const dark = Color(0xFF1A1A2E);
    final l10n = AppLocalizations.of(context);

    return ScaleTransition(
      scale: _scale,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: dark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [teal, Color(0xFF00695C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rate_review_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.shareFeedback ?? 'Share Your Feedback',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l10n?.helpImproveExperience ?? 'Help us improve your experience',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            AnalyticsService.instance.logEvent(
                              'app_dialog_feedback_close',
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable body ──────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Category chips
                          Text(
                            l10n?.category ?? 'Category',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_cats(l10n).length, (i) {
                              final cat = _cats(l10n)[i];
                              final active = _catIdx == i;
                              return GestureDetector(
                                onTap: () {
                                  AnalyticsService.instance.logEvent(
                                    'app_dialog_feedback_category',
                                  );
                                  setState(() => _catIdx = i);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? cat.color.withOpacity(0.16)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: active
                                          ? cat.color
                                          : Colors.white12,
                                      width: active ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cat.icon,
                                        color: active
                                            ? cat.color
                                            : Colors.white38,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: GoogleFonts.outfit(
                                          color: active
                                              ? cat.color
                                              : Colors.white54,
                                          fontSize: 13,
                                          fontWeight: active
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Text field
                          Text(
                            l10n?.yourMessage ?? 'Your Message',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: TextField(
                              controller: _controller,
                              maxLines: 5,
                              maxLength: 500,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              onChanged: (_) => setState(() {}),
                              cursorColor: teal,
                              decoration: InputDecoration(
                                hintText:
                                l10n?.feedbackHint ?? 'Tell us what you think — bug, idea, or anything...',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.white24,
                                  fontSize: 13,
                                ),
                                counterStyle: GoogleFonts.outfit(
                                  color: _controller.text.length > 400
                                      ? Colors.orange
                                      : Colors.white24,
                                  fontSize: 11,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),

                  // ── Buttons ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AnalyticsService.instance.logEvent(
                                'app_dialog_feedback_cancel',
                              );
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white54,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              l10n?.cancel ?? 'Cancel',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Send
                        Expanded(
                          flex: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [teal, Color(0xFF00695C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _sending ? null : _submit,
                              icon: _sending
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                _sending ? (l10n?.opening ?? 'Opening...') : (l10n?.sendFeedback ?? 'Send Feedback'),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}

// ─── Rate Us Dialog ───────────────────────────────────────────────────────────

class _RateUsDialog extends StatefulWidget {
  const _RateUsDialog();
  @override
  State<_RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<_RateUsDialog>
    with SingleTickerProviderStateMixin {
  int _stars = 0;
  bool _submitting = false;

  late AnimationController _anim;
  late Animation<double> _scale;

  // Store URL is now platform-aware via AppConstants
  static String get _storeUrl => AppConstants.getStoreUrl();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a star rating first.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final uri = Uri.parse(_storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open Play Store.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<String> _starLabels(AppLocalizations? l10n) => [
    l10n?.starTerrible ?? 'Terrible 😤',
    l10n?.starPoor ?? 'Poor 😕',
    l10n?.starOkay ?? 'Okay 😐',
    l10n?.starGood ?? 'Good 😊',
    l10n?.starExcellent ?? 'Excellent! 🤩',
  ];

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);
    const dark = Color(0xFF1A1A2E);
    final l10n = AppLocalizations.of(context);

    return ScaleTransition(
      scale: _scale,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: dark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.rateAppTitle(AppConstants.appName) ?? 'Rate ${AppConstants.appName}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l10n?.reviewMeansLot ?? 'Your review means a lot to us ❤️',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            AnalyticsService.instance.logEvent(
                              'app_dialog_rateus_close',
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Body ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      children: [
                        Text(
                          l10n?.howRateApp ?? 'How would you rate our app?',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Stars row ──────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final filled = _stars > i;
                            return GestureDetector(
                              onTap: () {
                                AnalyticsService.instance.logEvent(
                                  'app_dialog_rateus_star_tap',
                                );
                                setState(() => _stars = i + 1);
                              },
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                scale: filled ? 1.22 : 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 40,
                                    color: filled ? orange : Colors.white24,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _stars > 0
                              ? Text(
                            _starLabels(l10n)[_stars - 1],
                            key: ValueKey(_stars),
                            style: GoogleFonts.outfit(
                              color: orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          )
                              : const SizedBox(height: 20),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // ── Buttons ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white54,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              l10n?.later ?? 'Later',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: orange.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                _submitting ? (l10n?.opening ?? 'Opening...') : (l10n?.rateNow ?? 'Rate Now'),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Share Dialog ─────────────────────────────────────────────────────────────

class _ShareDialog extends StatefulWidget {
  const _ShareDialog();
  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  bool _copied = false;

  static String get _shareText =>
      '🌿 Try AI Pest Identifire — the smartest way to detect garden pests & diseases instantly!\n\n'
          '📲 Download now: ${AppConstants.getStoreUrl()}';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    // Use flutter's built-in clipboard
    await Clipboard.setData( ClipboardData(text: _shareText));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _shareViaEmail() async {
    final subject = Uri.encodeComponent('Check out AI Pest Identifire!');
    final body = Uri.encodeComponent(_shareText);
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2196F3);
    const dark = Color(0xFF1A1A2E);
    final l10n = AppLocalizations.of(context);

    return ScaleTransition(
      scale: _scale,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: dark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: blue.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.shareApp ?? 'Share the App',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            l10n?.shareAppSub ?? 'Spread the word with your friends!',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        AnalyticsService.instance.logEvent(
                          'app_dialog_share_close',
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.shareMessageLabel ?? 'Share this message',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Message preview card ───────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        _shareText,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Share option tiles ─────────────────────
                    Text(
                      l10n?.shareVia ?? 'Share via',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _shareTile(
                          icon: _copied
                              ? Icons.check_circle_rounded
                              : Icons.copy_rounded,
                          label: _copied ? (l10n?.copiedText ?? 'Copied!') : (l10n?.copy ?? 'Copy'),
                          color: _copied ? Colors.green : Colors.white54,
                          onTap: _copyToClipboard,
                        ),
                        const SizedBox(width: 10),
                        _shareTile(
                          icon: Icons.email_outlined,
                          label: l10n?.email ?? 'Email',
                          color: Colors.lightBlue,
                          onTap: _shareViaEmail,
                        ),
                        const SizedBox(width: 10),
                        _shareTile(
                          icon: Icons.message_rounded,
                          label: l10n?.whatsapp ?? 'WhatsApp',
                          color: Colors.green,
                          onTap: () async {
                            AnalyticsService.instance.logEvent(
                              'app_dialog_share_more',
                            );
                            final msg = Uri.encodeComponent(_shareText);
                            final uri = Uri.parse('https://wa.me/?text=$msg');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Close button ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AnalyticsService.instance.logEvent(
                          'app_dialog_share_done',
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        l10n?.done ?? 'Done',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ─── Permission Consent Dialog ───────────────────────────────────────────────

class _PermissionConsentDialog extends StatelessWidget {
  final PermissionType type;
  const _PermissionConsentDialog({required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    IconData icon;
    String title;
    String content;
    Color color = AppTheme.primaryColor;

    switch (type) {
      case PermissionType.camera:
        icon = Icons.camera_alt_outlined;
        title = l10n?.cameraTitle ?? "Camera Permission";
        content =
            l10n?.cameraContent ??
                "Allow access to your camera to take photos of plants and identify pests using AI.";
        break;
      case PermissionType.gallery:
        icon = Icons.photo_library_outlined;
        title = l10n?.galleryTitle ?? "Gallery Permission";
        content =
            l10n?.galleryContent ??
                "Allow access to your gallery to select photos of plants for AI analysis.";
        break;
      case PermissionType.notification:
        icon = Icons.notifications_active_outlined;
        title = l10n?.notificationsTitle ?? "Enable Notifications?";
        content =
            l10n?.notificationsContent ??
                "Get reminders to check your plants and keep your garden healthy with daily notifications.";
        break;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          AnalyticsService.instance.logEvent(
                            'app_dialog_perm_consent_cancel',
                          );
                          Navigator.pop(context, false);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n?.later ?? "Later",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          AnalyticsService.instance.logEvent(
                            'app_dialog_perm_consent_allow',
                          );
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n?.allow ?? "Allow",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
