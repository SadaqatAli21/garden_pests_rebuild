import 'dart:convert';

class PlantReminder {
  final int? id;
  final String plantName;
  final List<String> times; // Format: "HH:mm"
  final bool isActive;

  PlantReminder({
    this.id,
    required this.plantName,
    required this.times,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_name': plantName,
      'times': jsonEncode(times),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory PlantReminder.fromMap(Map<String, dynamic> map) {
    return PlantReminder(
      id: map['id'],
      plantName: map['plant_name'] ?? '',
      times: List<String>.from(jsonDecode(map['times'] ?? '[]')),
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  PlantReminder copyWith({
    int? id,
    String? plantName,
    List<String>? times,
    bool? isActive,
  }) {
    return PlantReminder(
      id: id ?? this.id,
      plantName: plantName ?? this.plantName,
      times: times ?? this.times,
      isActive: isActive ?? this.isActive,
    );
  }
}
