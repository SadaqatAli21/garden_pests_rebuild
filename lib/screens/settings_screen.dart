import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_theme.dart';
import '../core/app_constrants.dart';
import '../core/services/analytics_services.dart';
import '../providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_dialogs.dart';
import 'language_screen.dart';
import 'history_screen.dart';
import '../../core/services/permission_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader(AppLocalizations.of(context)!.notifications),
        _buildSettingsCard([
          _buildToggleTile(
            icon: Icons.notifications_active_outlined,
            color: Colors.redAccent,
            title: AppLocalizations.of(context)!.dailyReminder,
            value: ref.watch(settingsProvider).reminderEnabled,
            onChanged: (val) async {
              if (val) {
                final granted =
                await PermissionService.requestNotificationPermission(
                  context,
                );
                if (!granted) return;
              }
              ref.read(settingsProvider.notifier).toggleReminder(val);
            },
          ),
          if (ref.watch(settingsProvider).reminderEnabled) ...[
            _buildDivider(),
            _buildActionTile(
              icon: Icons.access_time_rounded,
              color: Colors.blueGrey,
              title: AppLocalizations.of(context)!.reminderTime,
              trailingText: ref
                  .watch(settingsProvider)
                  .reminderTime
                  .format(context),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: ref.watch(settingsProvider).reminderTime,
                );
                if (picked != null) {
                  ref.read(settingsProvider.notifier).setReminderTime(picked);
                }
              },
            ),
            /* _buildDivider(),
            _buildActionTile(
              icon: Icons.notification_important_outlined,
              color: Colors.orange,
              title: "Send Test Notification",
              onTap: () {
                AnalyticsService.instance.logEvent(
                  'settings_screen_onTap_tapped',
                );
                ref.read(settingsProvider.notifier).testNotification();
              },
            ),*/
          ],
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader(AppLocalizations.of(context)!.preferences),
        _buildSettingsCard([
          _buildToggleTile(
            icon: Icons.history,
            color: Colors.blue,
            title: AppLocalizations.of(context)!.saveToHistory,
            value: ref.watch(settingsProvider).historyAutoSave,
            onChanged: (val) =>
                ref.read(settingsProvider.notifier).setHistoryAutoSave(val),
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.language,
            color: Colors.purple,
            title: AppLocalizations.of(context)!.language,
            onTap: () {
              AnalyticsService.instance.logEvent(
                'settings_screen_onTap_tapped',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const LanguageScreen(isFromSettings: true),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.history_rounded,
            color: Colors.indigo,
            title: AppLocalizations.of(context)!.history,
            onTap: () {
              AnalyticsService.instance.logEvent(
                'settings_screen_onTap_tapped',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(showAppBar: true),
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader(AppLocalizations.of(context)!.support),
        _buildSettingsCard([
          _buildActionTile(
            icon: Icons.star_outline_rounded,
            color: Colors.orange,
            title: AppLocalizations.of(context)!.rateUs,
            onTap: () {
              AnalyticsService.instance.logEvent(
                'settings_screen_onTap_tapped',
              );
              AppDialogs.showRateUsDialog(context);
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.share_rounded,
            color: Colors.blue,
            title: AppLocalizations.of(context)!.shareApp,
            onTap: () {
              AnalyticsService.instance.logEvent(
                'settings_screen_onTap_tapped',
              );

              final box = context.findRenderObject() as RenderBox?;
              Share.share(
                AppLocalizations.of(context)!.shareBody(
                  AppConstants.appName,
                  AppConstants.getStoreUrl(),
                ),
                sharePositionOrigin: box != null
                    ? box.localToGlobal(Offset.zero) & box.size
                    : null,
              );
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.mail_outline_rounded,
            color: Colors.green,
            title: AppLocalizations.of(context)!.contactSupport,
            onTap: () {
              AnalyticsService.instance.logEvent(
                'settings_screen_onTap_tapped',
              );
              AppDialogs.showFeedbackDialog(context);
            },
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader(AppLocalizations.of(context)!.legal),
        _buildSettingsCard([
          _buildActionTile(
            icon: Icons.privacy_tip_outlined,
            color: Colors.purple,
            title: AppLocalizations.of(context)!.privacyPolicy,
            onTap: () async {
              final uri = Uri.parse(
                'https://sites.google.com/view/eline-chart-terms-condition/privacy-policy',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.article_outlined,
            color: Colors.blue,
            title: AppLocalizations.of(context)!.termsOfService,
            onTap: () async {
              final uri = Uri.parse(
                'https://sites.google.com/view/eline-chart-terms-condition/terms-of-services',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ]),

        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${AppLocalizations.of(context)!.version} 1.0.0",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Tablet: Two Column Grid in a constrained width center container
  Widget _buildTabletLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Preferences & Support
            Expanded(
              child: Column(
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.notifications,
                  ),
                  _buildSettingsCard([
                    _buildToggleTile(
                      icon: Icons.notifications_active_outlined,
                      color: Colors.redAccent,
                      title: AppLocalizations.of(context)!.dailyReminder,
                      value: ref.watch(settingsProvider).reminderEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final granted =
                          await PermissionService.requestNotificationPermission(
                            context,
                          );
                          if (!granted) return;
                        }
                        ref.read(settingsProvider.notifier).toggleReminder(val);
                      },
                    ),
                    if (ref.watch(settingsProvider).reminderEnabled) ...[
                      _buildDivider(),
                      _buildActionTile(
                        icon: Icons.access_time_rounded,
                        color: Colors.blueGrey,
                        title: AppLocalizations.of(context)!.reminderTime,
                        trailingText: ref
                            .watch(settingsProvider)
                            .reminderTime
                            .format(context),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: ref
                                .watch(settingsProvider)
                                .reminderTime,
                          );
                          if (picked != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .setReminderTime(picked);
                          }
                        },
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        icon: Icons.notification_important_outlined,
                        color: Colors.orange,
                        title: AppLocalizations.of(context)!.sendTestNotification,
                        onTap: () {
                          AnalyticsService.instance.logEvent(
                            'settings_screen_onTap_tapped',
                          );
                          ref
                              .read(settingsProvider.notifier)
                              .testNotification();
                        },
                      ),
                    ],
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.preferences,
                  ),
                  _buildSettingsCard([
                    _buildToggleTile(
                      icon: Icons.history,
                      color: Colors.blue,
                      title: AppLocalizations.of(context)!.saveToHistory,
                      value: ref.watch(settingsProvider).historyAutoSave,
                      onChanged: (val) => ref
                          .read(settingsProvider.notifier)
                          .setHistoryAutoSave(val),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.language,
                      color: Colors.purple,
                      title: AppLocalizations.of(context)!.language,
                      onTap: () {
                        AnalyticsService.instance.logEvent(
                          'settings_screen_onTap_tapped',
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const LanguageScreen(isFromSettings: true),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.history_rounded,
                      color: Colors.indigo,
                      title: AppLocalizations.of(context)!.history,
                      onTap: () {
                        AnalyticsService.instance.logEvent(
                          'settings_screen_onTap_tapped',
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const HistoryScreen(showAppBar: true),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader(AppLocalizations.of(context)!.support),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.star_outline_rounded,
                      color: Colors.orange,
                      title: AppLocalizations.of(context)!.rateUs,
                      onTap: () {
                        AnalyticsService.instance.logEvent(
                          'settings_screen_onTap_tapped',
                        );
                        AppDialogs.showRateUsDialog(context);
                      },
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.share_rounded,
                      color: Colors.blue,
                      title: AppLocalizations.of(context)!.shareApp,
                      onTap: () {
                        AnalyticsService.instance.logEvent(
                          'settings_screen_share_tapped',
                        );

                        final box = context.findRenderObject() as RenderBox?;
                        Share.share(
                          AppLocalizations.of(context)!.shareBody(
                            AppConstants.appName,
                            AppConstants.getStoreUrl(),
                          ),
                          sharePositionOrigin: box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null,
                        );
                      },
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Column: Legal & Contact
            Expanded(
              child: Column(
                children: [
                  _buildSectionHeader(AppLocalizations.of(context)!.legal),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.privacy_tip_outlined,
                      color: Colors.purple,
                      title: AppLocalizations.of(context)!.privacyPolicy,
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://sites.google.com/view/eline-chart-terms-condition/privacy-policy',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.article_outlined,
                      color: Colors.blue,
                      title: AppLocalizations.of(context)!.termsOfService,
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://sites.google.com/view/eline-chart-terms-condition/terms-of-services',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader(AppLocalizations.of(context)!.contact),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.mail_outline_rounded,
                      color: Colors.green,
                      title: AppLocalizations.of(context)!.contactSupport,
                      onTap: () {
                        AnalyticsService.instance.logEvent(
                          'settings_screen_onTap_tapped',
                        );
                        AppDialogs.showFeedbackDialog(context);
                      },
                    ),
                  ]),
                  const Spacer(),
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60, color: Color(0xFFEEEEEE));
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Color(0xFFC7C7CC),
          ),
        ],
      ),
    );
  }
}
