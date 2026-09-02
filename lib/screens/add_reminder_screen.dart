import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/plant_remiinder.dart';
import '../providers/locale_provider.dart';
import '../providers/reminder_provider.dart';
import '../../l10n/app_localizations.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final PlantReminder? reminder;
  const AddReminderScreen({super.key, this.reminder});

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final TextEditingController _plantNameController = TextEditingController();
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _plantNameController.text = widget.reminder!.plantName;
      _selectedTimes = widget.reminder!.times.map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final l10n = AppLocalizations.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null) {
      if (_selectedTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.timeAlreadySelected ?? 'Time already selected!'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  void _addTime() {
    final l10n = AppLocalizations.of(context);
    if (_selectedTimes.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.maxRemindersReached ?? 'Max 3 reminders per plant!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
    });
  }

  void _removeTime(int index) {
    if (_selectedTimes.length <= 1) return;
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    if (_plantNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.pleaseEnterPlantName ?? 'Please enter plant name!'), backgroundColor: Colors.red),
      );
      return;
    }

    final times = _selectedTimes.map((t) {
      final hour = t.hour.toString().padLeft(2, '0');
      final minute = t.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }).toList();

    if (widget.reminder != null) {
      final updated = widget.reminder!.copyWith(
        plantName: _plantNameController.text,
        times: times,
      );
      ref.read(reminderProvider.notifier).updateReminder(updated);
    } else {
      final newReminder = PlantReminder(
        plantName: _plantNameController.text,
        times: times,
      );
      ref.read(reminderProvider.notifier).addReminder(newReminder);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n?.reminderSavedSuccess ?? 'Reminder saved successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.reminder != null
              ? (l10n?.editReminder ?? 'Edit Reminder')
              : (l10n?.setNewAlert ?? 'Set New Alert'),
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l10n?.save ?? 'Save',
              style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.plantName ?? 'Plant Name', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _plantNameController,
              decoration: InputDecoration(
                hintText: l10n?.plantNameHint ?? 'e.g., Money Plant, Rose...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.park_outlined, color: Colors.green),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n?.scheduledTimes ?? 'Scheduled Times', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_selectedTimes.length < 3)
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add_alarm, size: 20),
                    label: Text(l10n?.addTime ?? 'Add Time'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_selectedTimes.length, (index) {
              final time = _selectedTimes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.blue, size: 22),
                    const SizedBox(width: 16),
                    Text(
                      time.format(context),
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _pickTime(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n?.change ?? 'Change'),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedTimes.length > 1)
                      IconButton(
                        onPressed: () => _removeTime(index),
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n?.dailyNotificationInfo(_plantNameController.text.isEmpty ? (l10n.plantName) : _plantNameController.text) ??
                          'You will get daily notifications at these times for ${_plantNameController.text.isEmpty ? "your plant" : _plantNameController.text}.',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.orange.shade900),
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
}
