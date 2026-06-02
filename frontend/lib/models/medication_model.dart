class DoseEntry {
  final String doseId;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String scheduledTime;
  final String timeOfDay;
  final String status; // "pending" | "taken" | "missed" | "late"
  final String? notes;

  const DoseEntry({
    required this.doseId,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    required this.timeOfDay,
    required this.status,
    this.notes,
  });

  DoseEntry copyWith({String? status}) => DoseEntry(
        doseId: doseId,
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        timeOfDay: timeOfDay,
        status: status ?? this.status,
        notes: notes,
      );

  factory DoseEntry.fromJson(Map<String, dynamic> json) {
    final doseInfo = json['medication_doses'] as Map<String, dynamic>? ?? {};
    final med = doseInfo['medications'] as Map<String, dynamic>? ?? {};
    final doseAmount = (med['dose_amount'] as num?)?.toString() ?? '';
    final doseUnit = med['dose_unit'] as String? ?? '';
    final dosage = doseAmount.isNotEmpty ? '$doseAmount $doseUnit'.trim() : '';
    final scheduledAt = doseInfo['scheduled_at'] as String? ?? '';
    return DoseEntry(
      doseId: json['dose_id'] as String? ?? json['id'] as String,
      medicationId: doseInfo['medication_id'] as String? ?? '',
      medicationName: med['name'] as String? ?? '',
      dosage: dosage,
      scheduledTime: scheduledAt,
      timeOfDay: _scheduledAtToKey(scheduledAt),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
    );
  }

  static String _scheduledAtToKey(String scheduledAt) {
    if (scheduledAt.isEmpty) return 'morning';
    try {
      // Use UTC hour directly — doses are stored in UTC with schedule times
      // as-is (08:00 = morning, 13:00 = afternoon, etc.)
      final hour = DateTime.parse(scheduledAt).toUtc().hour;
      if (hour < 11) return 'morning';
      if (hour < 15) return 'afternoon';
      if (hour < 20) return 'evening';
      return 'night';
    } catch (_) {
      return 'morning';
    }
  }
}

class MedicationItem {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String? instruction;
  final List<MedicationSchedule> schedules;

  const MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.instruction,
    required this.schedules,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    final rawSchedules =
        (json['medication_schedules'] as List<dynamic>?) ?? [];
    final doseAmount = (json['dose_amount'] as num?)?.toString() ?? '';
    final doseUnit = json['dose_unit'] as String? ?? '';
    final dosage = doseAmount.isNotEmpty ? '$doseAmount $doseUnit'.trim() : '';
    final frequency = json['frequency'] as String? ?? 'daily';
    return MedicationItem(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: dosage,
      frequency: frequency,
      instruction: json['instructions'] as String?,
      schedules: rawSchedules
          .map((s) => MedicationSchedule.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MedicationSchedule {
  final String timeOfDay;
  final String doseTime;

  const MedicationSchedule({
    required this.timeOfDay,
    required this.doseTime,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    // DB stores time as "HH:MM:SS" — normalize to "HH:MM" for reverse map lookup
    final raw = json['time_of_day'] as String? ?? '08:00';
    final timeOfDay = raw.length >= 5 ? raw.substring(0, 5) : raw;
    return MedicationSchedule(
      timeOfDay: timeOfDay,
      doseTime: timeOfDay,
    );
  }
}
