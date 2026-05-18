import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class AppointmentItem {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final String? doctorName;
  final String? location;
  final String? notes;

  const AppointmentItem({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.doctorName,
    this.location,
    this.notes,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    return AppointmentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      doctorName: json['doctor_name'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }

  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());
}

class AppointmentState {
  final List<AppointmentItem> appointments;
  final bool isLoading;
  final String? error;

  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  AppointmentState copyWith({
    List<AppointmentItem>? appointments,
    bool? isLoading,
    String? error,
  }) =>
      AppointmentState(
        appointments: appointments ?? this.appointments,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  List<AppointmentItem> get upcoming =>
      appointments.where((a) => a.isUpcoming).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<AppointmentItem> get past =>
      appointments.where((a) => !a.isUpcoming).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
}

class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final Dio _dio;

  AppointmentNotifier(this._dio) : super(const AppointmentState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.get('/appointments/');
      final list = (response.data as List<dynamic>? ?? [])
          .map((a) => AppointmentItem.fromJson(a as Map<String, dynamic>))
          .toList();
      state = AppointmentState(appointments: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail'] ?? e.message ?? 'Failed to load',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> create({
    required String title,
    required DateTime scheduledAt,
    String? doctorName,
    String? location,
    String? notes,
  }) async {
    await _dio.post('/appointments/', data: {
      'title': title,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      if (doctorName != null && doctorName.isNotEmpty)
        'doctor_name': doctorName,
      if (location != null && location.isNotEmpty) 'location': location,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    await refresh();
  }

  Future<void> delete(String id) async {
    await _dio.delete('/appointments/$id');
    state = state.copyWith(
      appointments: state.appointments.where((a) => a.id != id).toList(),
    );
  }
}

final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentState>(
  (ref) => AppointmentNotifier(ref.watch(apiServiceProvider)),
);
