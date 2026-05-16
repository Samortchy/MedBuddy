import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class C03AlertsFeed extends StatefulWidget {
  const C03AlertsFeed({super.key});

  @override
  State<C03AlertsFeed> createState() => _C03AlertsFeedState();
}

class _C03AlertsFeedState extends State<C03AlertsFeed> {
  String selectedFilter = 'All';
  final filters = ['All', 'Emergency', 'Medications', 'Check-ins'];

  final List<Map<String, dynamic>> alerts = [
    {
      'patient': 'Mohamed Samir',
      'type': 'Emergency',
      'message': 'Fall detected — liveness verification failed',
      'time': '2 min ago',
      'read': false,
    },
    {
      'patient': 'Fatma Khaled',
      'type': 'Medications',
      'message': 'Missed morning dose of Metformin',
      'time': '1 hour ago',
      'read': false,
    },
    {
      'patient': 'Hassan Ali',
      'type': 'Check-ins',
      'message': 'Wellness check-in completed — pain score increased',
      'time': '3 hours ago',
      'read': true,
    },
    {
      'patient': 'Hassan Ali',
      'type': 'Medications',
      'message': 'Evening dose of Aspirin taken on time',
      'time': '5 hours ago',
      'read': true,
    },
    {
      'patient': 'Fatma Khaled',
      'type': 'Check-ins',
      'message': 'Missed scheduled wellness check-in',
      'time': 'Yesterday',
      'read': true,
    },
  ];

  Color _typeColor(String type) {
    if (type == 'Emergency') return MedColors.emergency;
    if (type == 'Medications') return MedColors.warning;
    return MedColors.primary;
  }

  Color _typeBg(String type) {
    if (type == 'Emergency') return MedColors.emergencyLight;
    if (type == 'Medications') return MedColors.warningLight;
    return MedColors.primarySoft;
  }

  IconData _typeIcon(String type) {
    if (type == 'Emergency') return Icons.warning_rounded;
    if (type == 'Medications') return Icons.medication;
    return Icons.check_circle_outline;
  }

  List<Map<String, dynamic>> get filteredAlerts {
    if (selectedFilter == 'All') return alerts;
    return alerts.where((a) => a['type'] == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = alerts.where((a) => !a['read']).length;

    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text('Alerts',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => setState(() {
                for (var a in alerts) {
                  a['read'] = true;
                }
              }),
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final selected = selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            selected ? MedColors.primary : MedColors.slate100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : MedColors.slate500,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Alerts list
          Expanded(
            child: filteredAlerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 64, color: MedColors.success),
                        SizedBox(height: 16),
                        Text('All your patients are doing well',
                            style: TextStyle(
                                fontSize: 16, color: MedColors.slate500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, i) {
                      final alert = filteredAlerts[i];
                      final unread = !alert['read'];
                      return GestureDetector(
                        onTap: () => setState(() => alert['read'] = true),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(
                                color: unread
                                    ? _typeColor(alert['type'])
                                    : Colors.transparent,
                                width: 4,
                              ),
                              top: const BorderSide(color: MedColors.slate300),
                              right:
                                  const BorderSide(color: MedColors.slate300),
                              bottom:
                                  const BorderSide(color: MedColors.slate300),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _typeBg(alert['type']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_typeIcon(alert['type']),
                                      color: _typeColor(alert['type']),
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(alert['patient'],
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: unread
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: MedColors.slate900,
                                              )),
                                          const Spacer(),
                                          Text(alert['time'],
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: MedColors.slate500)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _typeBg(alert['type']),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(alert['type'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _typeColor(alert['type']),
                                            )),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(alert['message'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: MedColors.slate700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
