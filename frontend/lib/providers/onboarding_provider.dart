import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ── Value types ───────────────────────────────────────────────────────────────

class OnboardingMedication {
  final String name;
  final String dosage;
  final String frequency; // 'Once daily' | 'Twice daily' | 'Three times daily' | 'Custom'
  final bool withFood;

  const OnboardingMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.withFood,
  });
}

class OnboardingContact {
  final String name;
  final String phone;
  final String relation;
  final int priority;

  const OnboardingContact({
    required this.name,
    required this.phone,
    required this.relation,
    required this.priority,
  });
}

// ── State ─────────────────────────────────────────────────────────────────────

class OnboardingState {
  // S04
  final String fullName;
  final int age;
  final String gender;

  // S05
  final List<String> conditions;
  final String conditionDuration; // 'new' | 'chronic'

  // S06
  final String mobilityLevel; // display value, e.g. 'Fully Mobile'
  final String cognitiveState; // display value, e.g. 'Fully Independent'

  // S07
  final List<OnboardingMedication> medications;

  // S08
  final List<OnboardingContact> contacts;

  // S09
  final String checkinTime; // 'Morning' | 'Midday' | 'Evening' | 'Custom'
  final String checkinFrequency; // 'Daily' | 'Twice daily' | 'Custom'
  final double painBaseline;

  const OnboardingState({
    this.fullName = '',
    this.age = 65,
    this.gender = '',
    this.conditions = const [],
    this.conditionDuration = 'chronic',
    this.mobilityLevel = 'Fully Mobile',
    this.cognitiveState = 'Fully Independent',
    this.medications = const [],
    this.contacts = const [],
    this.checkinTime = 'Morning',
    this.checkinFrequency = 'Daily',
    this.painBaseline = 3.0,
  });

  OnboardingState copyWith({
    String? fullName,
    int? age,
    String? gender,
    List<String>? conditions,
    String? conditionDuration,
    String? mobilityLevel,
    String? cognitiveState,
    List<OnboardingMedication>? medications,
    List<OnboardingContact>? contacts,
    String? checkinTime,
    String? checkinFrequency,
    double? painBaseline,
  }) =>
      OnboardingState(
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        conditions: conditions ?? this.conditions,
        conditionDuration: conditionDuration ?? this.conditionDuration,
        mobilityLevel: mobilityLevel ?? this.mobilityLevel,
        cognitiveState: cognitiveState ?? this.cognitiveState,
        medications: medications ?? this.medications,
        contacts: contacts ?? this.contacts,
        checkinTime: checkinTime ?? this.checkinTime,
        checkinFrequency: checkinFrequency ?? this.checkinFrequency,
        painBaseline: painBaseline ?? this.painBaseline,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Dio _dio;

  OnboardingNotifier(this._dio) : super(const OnboardingState());

  // S04
  void setBasicInfo({required String fullName, required int age, required String gender}) {
    state = state.copyWith(fullName: fullName, age: age, gender: gender);
  }

  // S05
  void setConditions({required List<String> conditions, required String duration}) {
    state = state.copyWith(conditions: conditions, conditionDuration: duration);
  }

  // S06
  void setMobility({required String mobilityLevel, required String cognitiveState}) {
    state = state.copyWith(mobilityLevel: mobilityLevel, cognitiveState: cognitiveState);
  }

  // S07
  void setMedications(List<OnboardingMedication> medications) {
    state = state.copyWith(medications: medications);
  }

  // S08
  void setContacts(List<OnboardingContact> contacts) {
    state = state.copyWith(contacts: contacts);
  }

  /// Pre-fill state from existing profile data so edit screens show real values.
  void prefillFromProfile({
    String? fullName,
    int? age,
    List<String>? conditions,
    String? checkinTime,
    int? checkinFrequency,
  }) {
    String? timeDisplay;
    if (checkinTime != null) {
      if (checkinTime.startsWith('08')) timeDisplay = 'Morning';
      else if (checkinTime.startsWith('12')) timeDisplay = 'Midday';
      else if (checkinTime.startsWith('18')) timeDisplay = 'Evening';
    }
    state = state.copyWith(
      fullName: fullName ?? state.fullName,
      age: age ?? state.age,
      conditions: conditions ?? state.conditions,
      checkinTime: timeDisplay ?? state.checkinTime,
    );
  }

  // S09
  void setCheckinPrefs({
    required String checkinTime,
    required String checkinFrequency,
    required double painBaseline,
  }) {
    state = state.copyWith(
      checkinTime: checkinTime,
      checkinFrequency: checkinFrequency,
      painBaseline: painBaseline,
    );
  }

  // S10 — submit all accumulated data
  Future<void> submit() async {
    await Future.wait([
      _submitProfile(),
      _submitConditions(),
      _submitContacts(),
      _submitMedications(),
    ]);
  }

  Future<void> _submitProfile() async {
    // Calculate approximate date_of_birth from age (Jan 1 of birth year)
    final birthYear = DateTime.now().year - state.age;
    final dob = '$birthYear-01-01';
    await _dio.patch('/patient/profile', data: {
      'full_name': state.fullName,
      'date_of_birth': dob,
      'mobility_level': _mobilityToApi(state.mobilityLevel),
      'cognitive_state': _cognitionToApi(state.cognitiveState),
      'checkin_time': _checkinTimeToApi(state.checkinTime),
      'checkin_frequency': _frequencyToApi(state.checkinFrequency),
    });
  }

  Future<void> _submitConditions() async {
    // Delete all existing conditions first to avoid duplicates on re-submit
    try {
      final existing = await _dio.get('/health-conditions/');
      final list = (existing.data as List<dynamic>? ?? []);
      await Future.wait(
        list.map((c) => _dio.delete('/health-conditions/${c['id']}')),
      );
    } catch (_) {}
    if (state.conditions.isEmpty) return;
    await Future.wait(state.conditions.map((name) => _dio.post(
          '/health-conditions/',
          data: {
            'name': name,
            'notes': state.conditionDuration == 'chronic' ? 'Chronic' : 'New',
          },
        )));
  }

  Future<void> _submitContacts() async {
    // Delete all existing contacts first to avoid duplicates on re-submit
    try {
      final existing = await _dio.get('/emergency-contacts/');
      final list = (existing.data as List<dynamic>? ?? []);
      await Future.wait(
        list.map((c) => _dio.delete('/emergency-contacts/${c['id']}')),
      );
    } catch (_) {}
    if (state.contacts.isEmpty) return;
    await Future.wait(state.contacts.map((c) => _dio.post(
          '/emergency-contacts/',
          data: {
            'name': c.name,
            'phone': c.phone,
            'priority': c.priority,
            'relationship': c.relation,
          },
        )));
  }

  Future<void> _submitMedications() async {
    // Delete all existing medications first to avoid duplicates on re-submit
    try {
      final existing = await _dio.get('/medications/');
      final list = (existing.data as List<dynamic>? ?? []);
      await Future.wait(
        list.map((m) => _dio.delete('/medications/${m['id']}')),
      );
    } catch (_) {}
    if (state.medications.isEmpty) return;
    await Future.wait(
      state.medications.map(
        (m) => _dio.post(
          '/medications/',
          data: {
            'name': m.name,
            'dose_amount': _parseDoseAmount(m.dosage),
            'dose_unit': _parseDoseUnit(m.dosage),
            'frequency': _medFrequencyToApi(m.frequency),
            if (m.withFood) 'instructions': 'Take with food',
            'start_date': DateTime.now().toIso8601String().split('T')[0],
            'schedules': [
              {'time_of_day': _checkinTimeToApi(state.checkinTime)},
            ],
          },
        ),
      ),
    );
  }

  double _parseDoseAmount(String dosage) {
    final match = RegExp(r'[\d.]+').firstMatch(dosage);
    return match != null ? double.tryParse(match.group(0)!) ?? 1.0 : 1.0;
  }

  String _parseDoseUnit(String dosage) {
    final lower = dosage.toLowerCase();
    if (lower.contains('mg')) return 'mg';
    if (lower.contains('ml')) return 'ml';
    if (lower.contains('mcg')) return 'mcg';
    if (lower.contains('tablet')) return 'tablet';
    if (lower.contains('capsule')) return 'capsule';
    return 'tablet';
  }

  // ── Mapping helpers ───────────────────────────────────────────────────────

  String _mobilityToApi(String display) {
    switch (display) {
      case 'Fully Mobile':
        return 'independent'; // ← was 'fully_mobile'
      case 'Limited':
        return 'assisted'; // ← was 'limited'
      case 'Wheelchair':
        return 'wheelchair';
      case 'Bedridden':
        return 'bedridden';
      default:
        return 'independent'; // ← was 'fully_mobile'
    }
  }

  String _cognitionToApi(String display) {
    switch (display) {
      case 'Fully Independent':
        return 'normal'; // ← was 'fully_independent'
      case 'Mild Impairment':
        return 'mild_impairment';
      case 'Needs Guidance':
        return 'moderate_impairment'; // ← was 'needs_guidance'
      default:
        return 'normal'; // ← was 'fully_independent'
    }
  }

  String _checkinTimeToApi(String display) {
    switch (display) {
      case 'Morning':
        return '08:00';
      case 'Midday':
        return '12:00';
      case 'Evening':
        return '18:00';
      default:
        return '08:00';
    }
  }

  String _medFrequencyToApi(String display) {
    switch (display) {
      case 'Twice daily':
        return 'twice_daily';
      case 'Three times daily':
        return 'three_times_daily';
      default:
        return 'daily';
    }
  }

  int _frequencyToApi(String display) {
    switch (display) {
      case 'Twice daily':
        return 2;
      default:
        return 1;
    }
  }

}

// ── Provider ──────────────────────────────────────────────────────────────────

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref.watch(apiServiceProvider)),
);
