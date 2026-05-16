import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class C06PatientHistory extends StatefulWidget {
  const C06PatientHistory({super.key});

  @override
  State<C06PatientHistory> createState() => _C06PatientHistoryState();
}

class _C06PatientHistoryState extends State<C06PatientHistory>
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
        title: const Text('Health History — Hassan Ali',
            style: TextStyle(
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
            Tab(text: 'Adherence'),
            Tab(text: 'Emergencies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CheckinsTab(),
          _AdherenceTab(),
          _EmergenciesTab(),
        ],
      ),
    );
  }
}

class _CheckinsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final checkins = [
      {
        'date': 'Today, 9:00 AM',
        'mood': 3,
        'pain': 4,
        'sleep': 'Poor',
        'energy': 2,
        'flag': true
      },
      {
        'date': 'Yesterday, 9:15 AM',
        'mood': 4,
        'pain': 2,
        'sleep': 'Good',
        'energy': 4,
        'flag': false
      },
      {
        'date': 'Apr 2, 9:00 AM',
        'mood': 3,
        'pain': 5,
        'sleep': 'Fair',
        'energy': 3,
        'flag': true
      },
      {
        'date': 'Apr 1, 9:30 AM',
        'mood': 4,
        'pain': 3,
        'sleep': 'Good',
        'energy': 4,
        'flag': false
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI insight card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MedColors.warningLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MedColors.warningMid),
          ),
          child: const Row(
            children: [
              Icon(Icons.psychology, color: MedColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text('Pain scores have increased for 4 consecutive days',
                    style: TextStyle(
                        fontSize: 14,
                        color: MedColors.warning,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...checkins.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: c['flag'] == true
                        ? MedColors.warningMid
                        : MedColors.slate300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c['date'] as String,
                          style: const TextStyle(
                              fontSize: 13, color: MedColors.slate500)),
                      const Spacer(),
                      if (c['flag'] == true)
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
                      _StatChip(label: 'Mood', value: '${c['mood']}/5'),
                      _StatChip(label: 'Pain', value: '${c['pain']}/10'),
                      _StatChip(label: 'Sleep', value: c['sleep'] as String),
                      _StatChip(label: 'Energy', value: '${c['energy']}/5'),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _AdherenceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final meds = [
      {'name': 'Metformin', 'pct': 92},
      {'name': 'Amlodipine', 'pct': 78},
      {'name': 'Aspirin', 'pct': 95},
      {'name': 'Atorvastatin', 'pct': 88},
    ];

    Color pctColor(int p) {
      if (p >= 90) return MedColors.success;
      if (p >= 70) return MedColors.warningMid;
      return MedColors.emergency;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MedColors.slate300),
          ),
          child: const Column(
            children: [
              Text('Overall Adherence',
                  style: TextStyle(fontSize: 14, color: MedColors.slate500)),
              SizedBox(height: 8),
              Text('88%',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: MedColors.success)),
              Text('Good — above target',
                  style: TextStyle(fontSize: 13, color: MedColors.success)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...meds.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MedColors.slate300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m['name'] as String,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: MedColors.slate900)),
                      const Spacer(),
                      Text('${m['pct']}%',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: pctColor(m['pct'] as int))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (m['pct'] as int) / 100,
                      backgroundColor: MedColors.slate100,
                      color: pctColor(m['pct'] as int),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _EmergenciesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final events = [
      {
        'type': 'Fall Detected',
        'date': 'Apr 4, 2:10 AM',
        'outcome': 'Handled by caregiver',
        'color': MedColors.emergency
      },
      {
        'type': 'Manual SOS',
        'date': 'Mar 28, 4:45 PM',
        'outcome': 'False alarm',
        'color': MedColors.warningMid
      },
      {
        'type': 'Fall Detected',
        'date': 'Mar 15, 3:20 AM',
        'outcome': '911 activated',
        'color': MedColors.emergency
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: events
          .map((e) => Container(
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
                      child: Icon(Icons.warning_rounded,
                          color: e['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['type'] as String,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: MedColors.slate900)),
                          Text(e['date'] as String,
                              style: const TextStyle(
                                  fontSize: 12, color: MedColors.slate500)),
                          const SizedBox(height: 4),
                          Text(e['outcome'] as String,
                              style: const TextStyle(
                                  fontSize: 13, color: MedColors.slate700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: MedColors.slate500),
                  ],
                ),
              ))
          .toList(),
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
