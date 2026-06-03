import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/caregiver_provider.dart';
import 'c05_patient_medications.dart';
import 'c06_patient_history.dart';
import 'c07_emergency_active.dart';
import 'c08_caregiver_chat.dart';

class C04PatientDashboard extends ConsumerWidget {
  final String patientName;
  final String lastCheckin;
  final String status;
  final String? patientId;

  const C04PatientDashboard({
    super.key,
    required this.patientName,
    required this.lastCheckin,
    required this.status,
    this.patientId,
  });

  Color get statusDotColor {
    if (status == 'red') return MedColors.emergency;
    if (status == 'amber') return MedColors.warningMid;
    return MedColors.success;
  }

  bool get isEmergency => status == 'red';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pid = patientId;

    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(patientName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: statusDotColor, shape: BoxShape.circle),
          ),
        ],
      ),
      body: pid == null
          ? const Center(child: Text('Missing patient reference.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Patient info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MedColors.slate300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: MedColors.primarySoft,
                        child: Text(
                            patientName.isNotEmpty ? patientName[0] : '?',
                            style: const TextStyle(
                                fontSize: 24,
                                color: MedColors.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patientName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: MedColors.slate900)),
                            const SizedBox(height: 4),
                            Text('Last check-in: $lastCheckin',
                                style: const TextStyle(
                                    fontSize: 13, color: MedColors.slate500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Medications (real)
                const _SectionTitle(title: 'Medications'),
                const SizedBox(height: 8),
                ref.watch(caregiverPatientMedsProvider(pid)).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: MedColors.primary)),
                      ),
                      error: (e, _) => const Text('Could not load medications',
                          style: TextStyle(color: MedColors.emergency)),
                      data: (meds) => meds.isEmpty
                          ? const Text('No medications on file.',
                              style: TextStyle(color: MedColors.slate500))
                          : Column(
                              children: meds.map((m) {
                                final times = m.schedules.isEmpty
                                    ? ''
                                    : m.schedules
                                        .map((s) => s.timeOfDay)
                                        .join(' · ');
                                return _MedTile(
                                  name: m.dosage.isNotEmpty
                                      ? '${m.name} ${m.dosage}'
                                      : m.name,
                                  subtitle:
                                      '${m.frequency.replaceAll('_', ' ')}${times.isNotEmpty ? ' · $times' : ''}',
                                );
                              }).toList(),
                            ),
                    ),
                const SizedBox(height: 16),

                // Last wellness check-in (real)
                const _SectionTitle(title: 'Last Wellness Check-in'),
                const SizedBox(height: 8),
                ref.watch(caregiverPatientCheckinsProvider(pid)).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: MedColors.primary)),
                      ),
                      error: (e, _) => const Text('Could not load check-ins',
                          style: TextStyle(color: MedColors.emergency)),
                      data: (checkins) {
                        if (checkins.isEmpty) {
                          return const Text('No check-ins yet.',
                              style: TextStyle(color: MedColors.slate500));
                        }
                        final c = checkins.first;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MedColors.slate300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _CheckinStat(
                                      label: 'Mood',
                                      value: '${c.mood}/5',
                                      color: MedColors.warningMid),
                                  _CheckinStat(
                                      label: 'Pain',
                                      value: '${c.painLevel}/10',
                                      color: MedColors.emergency),
                                  _CheckinStat(
                                      label: 'Sleep',
                                      value: c.sleepQuality,
                                      color: MedColors.warningMid),
                                  _CheckinStat(
                                      label: 'Energy',
                                      value: '${c.energy}/5',
                                      color: MedColors.emergency),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                const SizedBox(height: 16),

                // Quick actions
                const _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: [
                    _QuickAction(
                        icon: Icons.medication,
                        label: 'View Medications',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => C05PatientMedications(
                                    patientId: pid,
                                    patientName: patientName)))),
                    _QuickAction(
                        icon: Icons.history,
                        label: 'View History',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => C06PatientHistory(
                                    patientId: pid,
                                    patientName: patientName)))),
                    _QuickAction(
                        icon: Icons.chat,
                        label: 'Send Message',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const C08CaregiverChat()))),
                    _QuickAction(
                        icon: Icons.warning,
                        label: 'Emergency Log',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const C07EmergencyActive()))),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: MedColors.slate900));
  }
}

class _MedTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const _MedTile({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: MedColors.slate900)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: MedColors.slate500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CheckinStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: MedColors.slate500)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MedColors.slate300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MedColors.primary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: MedColors.slate700,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
