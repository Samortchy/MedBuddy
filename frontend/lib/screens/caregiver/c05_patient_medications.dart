import 'package:flutter/material.dart';
import '/constants/colors.dart';

class C05PatientMedications extends StatefulWidget {
  const C05PatientMedications({super.key});

  @override
  State<C05PatientMedications> createState() => _C05PatientMedicationsState();
}

class _C05PatientMedicationsState extends State<C05PatientMedications> {
  final List<Map<String, dynamic>> medications = [
    {
      'name': 'Metformin',
      'dose': '500mg',
      'frequency': 'Twice daily',
      'time': '8:00 AM & 8:00 PM',
      'withFood': true,
      'adherence': 92
    },
    {
      'name': 'Amlodipine',
      'dose': '5mg',
      'frequency': 'Once daily',
      'time': '2:00 PM',
      'withFood': false,
      'adherence': 78
    },
    {
      'name': 'Aspirin',
      'dose': '100mg',
      'frequency': 'Once daily',
      'time': '8:00 PM',
      'withFood': true,
      'adherence': 95
    },
    {
      'name': 'Atorvastatin',
      'dose': '20mg',
      'frequency': 'Once daily',
      'time': '9:00 PM',
      'withFood': false,
      'adherence': 88
    },
  ];

  void _showAddEditSheet(BuildContext context, {Map<String, dynamic>? med}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(med == null ? 'Add Medication' : 'Edit Medication',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MedColors.slate900)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: MedColors.slate100,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Dose',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: MedColors.slate100,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: MedColors.slate100,
                    ),
                    items: ['mg', 'ml', 'tablets']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: MedColors.slate100,
              ),
              items: [
                'Once daily',
                'Twice daily',
                'Three times daily',
                'Custom'
              ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Medication',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Color _adherenceColor(int pct) {
    if (pct >= 90) return MedColors.success;
    if (pct >= 70) return MedColors.warningMid;
    return MedColors.emergency;
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
        title: const Text('Medications — Hassan Ali',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MedColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MedColors.primaryLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: MedColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Changes you make will notify Hassan Ali immediately',
                      style: TextStyle(
                          fontSize: 13, color: MedColors.primaryDark)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ...medications.map((med) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MedColors.slate300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MedColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.medication,
                                color: MedColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${med['name']} ${med['dose']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: MedColors.slate900)),
                                Text(med['frequency'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: MedColors.slate500)),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert,
                                color: MedColors.slate500),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style: TextStyle(
                                          color: MedColors.emergency))),
                            ],
                            onSelected: (v) {
                              if (v == 'edit') {
                                _showAddEditSheet(context, med: med);
                              }
                              if (v == 'delete') {
                                setState(() => medications.remove(med));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: MedColors.slate500),
                          const SizedBox(width: 4),
                          Text(med['time'],
                              style: const TextStyle(
                                  fontSize: 13, color: MedColors.slate500)),
                          const SizedBox(width: 16),
                          if (med['withFood'])
                            const Row(children: [
                              Icon(Icons.restaurant,
                                  size: 14, color: MedColors.slate500),
                              SizedBox(width: 4),
                              Text('With food',
                                  style: TextStyle(
                                      fontSize: 13, color: MedColors.slate500)),
                            ]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Adherence: ',
                              style: TextStyle(
                                  fontSize: 13, color: MedColors.slate500)),
                          Text('${med['adherence']}%',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _adherenceColor(
                                      med['adherence'] as int))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (med['adherence'] as int) / 100,
                                backgroundColor: MedColors.slate100,
                                color: _adherenceColor(med['adherence'] as int),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context),
        backgroundColor: MedColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Medication',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
