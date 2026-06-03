import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/caregiver_provider.dart';
import '/services/service_interfaces.dart';

/// Read-only health history for a linked patient (caregiver side).
class C06PatientHistory extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const C06PatientHistory({
    super.key,
    required this.patientId,
    this.patientName = 'Patient',
  });

  @override
  ConsumerState<C06PatientHistory> createState() => _C06PatientHistoryState();
}

class _C06PatientHistoryState extends ConsumerState<C06PatientHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Health History — ${widget.patientName}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Check-ins'),
            Tab(text: 'Medications'),
            Tab(text: 'Emergencies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CheckinsTab(patientId: widget.patientId),
          _MedicationsTab(patientId: widget.patientId),
          _EmergenciesTab(patientId: widget.patientId),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ap = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day}, $h:$m $ap';
}

Widget _asyncList<T>(
  WidgetRef ref,
  AsyncValue<List<T>> async,
  ProviderBase toInvalidate,
  String emptyText,
  Widget Function(List<T>) builder,
) {
  return async.when(
    loading: () => const Center(
        child: CircularProgressIndicator(color: MedColors.primary)),
    error: (e, _) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load data',
              style: TextStyle(color: MedColors.emergency)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(toInvalidate),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
    data: (items) => items.isEmpty
        ? Center(
            child: Text(emptyText,
                style: const TextStyle(color: MedColors.slate500)))
        : builder(items),
  );
}

// ── Check-ins ─────────────────────────────────────────────────────────────────

class _CheckinsTab extends ConsumerWidget {
  final String patientId;
  const _CheckinsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(caregiverPatientCheckinsProvider(patientId));
    return _asyncList<WellnessCheckIn>(
      ref,
      async,
      caregiverPatientCheckinsProvider(patientId),
      'No check-ins yet.',
      (checkins) => ListView(
        padding: const EdgeInsets.all(16),
        children: checkins.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: c.isFlagged
                      ? MedColors.warningMid
                      : MedColors.slate300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_fmtDate(c.timestamp),
                        style: const TextStyle(
                            fontSize: 13, color: MedColors.slate500)),
                    const Spacer(),
                    if (c.isFlagged)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: MedColors.warningLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Flagged',
                            style: TextStyle(
                                fontSize: 11,
                                color: MedColors.warning,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(label: 'Mood', value: '${c.mood}/5'),
                    _StatChip(label: 'Pain', value: '${c.painLevel}/10'),
                    _StatChip(label: 'Sleep', value: c.sleepQuality),
                    _StatChip(label: 'Energy', value: '${c.energy}/5'),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Medications ───────────────────────────────────────────────────────────────

class _MedicationsTab extends ConsumerWidget {
  final String patientId;
  const _MedicationsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(caregiverPatientMedsProvider(patientId));
    return _asyncList(
      ref,
      async,
      caregiverPatientMedsProvider(patientId),
      'No medications on file.',
      (meds) => ListView(
        padding: const EdgeInsets.all(16),
        children: meds.map((m) {
          final times =
              m.schedules.isEmpty ? '—' : m.schedules.map((s) => s.timeOfDay).join(' · ');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedColors.slate300),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication, color: MedColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          m.dosage.isNotEmpty
                              ? '${m.name} · ${m.dosage}'
                              : m.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: MedColors.slate900)),
                      Text('${m.frequency.replaceAll('_', ' ')} · $times',
                          style: const TextStyle(
                              fontSize: 13, color: MedColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Emergencies ───────────────────────────────────────────────────────────────

class _EmergenciesTab extends ConsumerWidget {
  final String patientId;
  const _EmergenciesTab({required this.patientId});

  String _typeLabel(EmergencyEventType t) =>
      t == EmergencyEventType.fallDetected ? 'Fall Detected' : 'Manual SOS';

  String _outcomeLabel(EmergencyOutcome o) {
    switch (o) {
      case EmergencyOutcome.handledByCaregiver:
        return 'Handled by caregiver';
      case EmergencyOutcome.falseAlarm:
        return 'False alarm';
      case EmergencyOutcome.activated911:
        return '911 activated';
      case EmergencyOutcome.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(caregiverPatientEmergenciesProvider(patientId));
    return _asyncList<EmergencyEvent>(
      ref,
      async,
      caregiverPatientEmergenciesProvider(patientId),
      'No emergency events.',
      (events) => ListView(
        padding: const EdgeInsets.all(16),
        children: events.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedColors.slate300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MedColors.emergencyLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_rounded,
                      color: MedColors.emergency, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_typeLabel(e.type),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: MedColors.slate900)),
                      Text(_fmtDate(e.timestamp),
                          style: const TextStyle(
                              fontSize: 12, color: MedColors.slate500)),
                      const SizedBox(height: 4),
                      Text(_outcomeLabel(e.outcome),
                          style: const TextStyle(
                              fontSize: 13, color: MedColors.slate700)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: MedColors.slate900)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: MedColors.slate500)),
      ],
    );
  }
}
