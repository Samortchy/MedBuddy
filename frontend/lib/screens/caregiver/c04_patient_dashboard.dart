import 'package:flutter/material.dart';
import '/constants/colors.dart';
import 'c05_patient_medications.dart';
import 'c06_patient_history.dart';
import 'c07_emergency_active.dart';
import 'c08_caregiver_chat.dart';

class C04PatientDashboard extends StatelessWidget {
  final String patientName;
  final String lastCheckin;
  final String status;

  const C04PatientDashboard({
    super.key,
    required this.patientName,
    required this.lastCheckin,
    required this.status,
  });

  Color get statusDotColor {
    if (status == 'red') return MedColors.emergency;
    if (status == 'amber') return MedColors.warningMid;
    return MedColors.success;
  }

  bool get isEmergency => status == 'red';

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency banner — only shown for emergency status
          if (isEmergency)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MedColors.emergencyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MedColors.emergencyMid),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: MedColors.emergency),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Active alert — Fall detected 2 min ago',
                        style: TextStyle(
                            fontSize: 14,
                            color: MedColors.emergency,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View',
                        style: TextStyle(color: MedColors.emergency)),
                  ),
                ],
              ),
            ),

          if (isEmergency) const SizedBox(height: 16),

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
                  child: Text(patientName[0],
                      style: const TextStyle(
                          fontSize: 24,
                          color: MedColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MedColors.slate900)),
                    const SizedBox(height: 4),
                    Text('Last check-in: $lastCheckin',
                        style: TextStyle(
                          fontSize: 13,
                          color: isEmergency
                              ? MedColors.emergency
                              : MedColors.slate500,
                          fontWeight:
                              isEmergency ? FontWeight.bold : FontWeight.normal,
                        )),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Today's medications
          const _SectionTitle(title: "Today's Medications"),
          const SizedBox(height: 8),
          const _MedStatusTile(
              name: 'Metformin 500mg', time: '8:00 AM', status: 'taken'),
          const _MedStatusTile(
              name: 'Amlodipine 5mg', time: '2:00 PM', status: 'missed'),
          const _MedStatusTile(
              name: 'Aspirin 100mg', time: '8:00 PM', status: 'pending'),

          const SizedBox(height: 16),

          // Last check-in
          const _SectionTitle(title: 'Last Wellness Check-in'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedColors.slate300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Today, 9:00 AM',
                        style:
                            TextStyle(fontSize: 13, color: MedColors.slate500)),
                    Spacer(),
                    Text('View full history',
                        style:
                            TextStyle(fontSize: 13, color: MedColors.primary)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CheckinStat(
                        label: 'Mood',
                        value: '3/5',
                        color: MedColors.warningMid),
                    _CheckinStat(
                        label: 'Pain',
                        value: '4/10',
                        color: MedColors.emergency),
                    _CheckinStat(
                        label: 'Sleep',
                        value: 'Poor',
                        color: MedColors.warningMid),
                    _CheckinStat(
                        label: 'Energy',
                        value: '2/5',
                        color: MedColors.emergency),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Trigger check-in button
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
            label: const Text('Trigger Check-in Now',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
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
                  label: 'Edit Medications',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const C05PatientMedications()))),
              _QuickAction(
                  icon: Icons.history,
                  label: 'View History',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const C06PatientHistory()))),
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

class _MedStatusTile extends StatelessWidget {
  final String name;
  final String time;
  final String status;

  const _MedStatusTile({
    required this.name,
    required this.time,
    required this.status,
  });

  Color get statusColor {
    if (status == 'taken') return MedColors.success;
    if (status == 'missed') return MedColors.emergency;
    return MedColors.slate500;
  }

  Color get statusBg {
    if (status == 'taken') return MedColors.successLight;
    if (status == 'missed') return MedColors.emergencyLight;
    return MedColors.slate100;
  }

  String get statusLabel {
    if (status == 'taken') return 'Taken';
    if (status == 'missed') return 'Missed';
    return 'Pending';
  }

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
                Text(time,
                    style: const TextStyle(
                        fontSize: 13, color: MedColors.slate500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
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
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: MedColors.slate700,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
