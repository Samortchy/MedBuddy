import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/service_interfaces.dart';

class PatientProfileData {
  final String id;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final String? avatarUrl;
  final String? preferredLanguage;
  final String? gender;
  final String? mobilityLevel;
  final String? cognitiveState;
  final bool fallDetectionEnabled;
  final String? checkinTime;
  final String? checkinFrequency;
  final int? medicationGraceMins;
  final int? painBaseline;

  const PatientProfileData({
    required this.id,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.avatarUrl,
    this.preferredLanguage,
    this.gender,
    this.mobilityLevel,
    this.cognitiveState,
    this.fallDetectionEnabled = false,
    this.checkinTime,
    this.checkinFrequency,
    this.medicationGraceMins,
    this.painBaseline,
  });

  factory PatientProfileData.fromJson(Map<String, dynamic> json) {
    return PatientProfileData(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Patient',
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      gender: json['gender'] as String?,
      mobilityLevel: json['mobility_level'] as String?,
      cognitiveState: json['cognitive_state'] as String?,
      fallDetectionEnabled: json['fall_detection_enabled'] as bool? ?? false,
      checkinTime: json['checkin_time'] as String?,
      checkinFrequency: json['checkin_frequency']?.toString(),
      medicationGraceMins: json['medication_grace_mins'] as int?,
      painBaseline: (json['pain_baseline'] as num?)?.toInt(),
    );
  }

  String get firstName => fullName.split(' ').first;
}

class PatientProfileNotifier
    extends StateNotifier<AsyncValue<PatientProfileData?>> {
  final Dio _dio;

  PatientProfileNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/patient/profile');
      final data = response.data as Map<String, dynamic>;
      state = AsyncValue.data(PatientProfileData.fromJson(data));
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data?['detail'] ?? e.message ?? 'Failed to load profile',
        e.stackTrace,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}

final patientProfileProvider = StateNotifierProvider<PatientProfileNotifier,
    AsyncValue<PatientProfileData?>>(
  (ref) => PatientProfileNotifier(ref.watch(apiServiceProvider)),
);

// ── My caregivers (caregivers linked to the authenticated patient) ────────────

String _initialsFrom(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

final myCaregiversProvider = FutureProvider<List<CaregiverLink>>((ref) async {
  final dio = ref.watch(apiServiceProvider);
  final response = await dio.get('/caregiver/my-caregivers');
  final list = (response.data['caregivers'] as List<dynamic>? ?? []);
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    final name = m['full_name'] as String? ?? 'Caregiver';
    return CaregiverLink(
      id: m['link_id'] as String? ?? '',
      name: name,
      relationship: 'Caregiver',
      initials: _initialsFrom(name),
      isActive: (m['status'] as String?) == 'active',
    );
  }).toList();
});
