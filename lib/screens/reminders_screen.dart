import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/plant_remiinder.dart';
import '../providers/locale_provider.dart';
import '../providers/reminder_provider.dart';
import 'add_reminder_screen.dart';
import '../../l10n/app_localizations.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final reminders = ref.watch(reminderProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.waterReminders ?? 'Water Reminders',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddReminderScreen()),
            ),
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          ),
        ],
      ),
      body: reminders.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return _buildReminderCard(context, ref, reminder);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none, size: 64, color: Colors.green.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.noRemindersYet ?? 'No Reminders Yet',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.noRemindersSubtitle ?? 'Set daily alerts to never forget watering your plants again!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddReminderScreen()),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(l10n?.addFirstPlant ?? 'Add Your First Plant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, PlantReminder reminder) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.water_drop, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.plantName,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      l10n?.timesDaily(reminder.times.length) ?? '${reminder.times.length} times daily',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isActive,
                activeColor: Colors.green,
                onChanged: (val) {
                  ref.read(reminderProvider.notifier).updateReminder(reminder.copyWith(isActive: val));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              ...reminder.times.map((t) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              )),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _editReminder(context, reminder),
                icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteConfirm(context, ref, reminder),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editReminder(BuildContext context, PlantReminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(reminder: reminder),
      ),
    );
  }

  void _deleteConfirm(BuildContext context, WidgetRef ref, PlantReminder reminder) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteReminderTitle ?? 'Delete Reminder?'),
        content: Text(l10n?.deleteReminderConfirm(reminder.plantName) ?? 'Are you sure you want to remove the schedule for ${reminder.plantName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n?.cancel ?? 'Cancel')),
          TextButton(
            onPressed: () {
              ref.read(reminderProvider.notifier).deleteReminder(reminder.id!);
              Navigator.pop(context);
            },
            child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
