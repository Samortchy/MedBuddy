import 'package:flutter/material.dart';
import '/constants/colors.dart';
import 'c02_add_patient.dart';

class C09CaregiverProfile extends StatelessWidget {
  const C09CaregiverProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text('My Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedColors.slate300),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: MedColors.primarySoft,
                  child: Text('B',
                      style: TextStyle(
                          fontSize: 32,
                          color: MedColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                const Text('Bakr Mohamed',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MedColors.slate900)),
                const SizedBox(height: 4),
                const Text('bakr@email.com',
                    style: TextStyle(fontSize: 14, color: MedColors.slate500)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: MedColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Caregiver',
                      style: TextStyle(
                          fontSize: 13,
                          color: MedColors.primaryDark,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Linked patients
          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Linked Patients',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: MedColors.primaryDark,
                    letterSpacing: 0.5)),
          ),

          const _LinkedPatientTile(name: 'Hassan Ali', relation: 'Father'),
          const _LinkedPatientTile(name: 'Fatma Khaled', relation: 'Mother'),
          const _LinkedPatientTile(name: 'Mohamed Samir', relation: 'Uncle'),

          const SizedBox(height: 8),

          // Add patient button
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const C02AddPatient()),
            ),
            icon: const Icon(Icons.person_add, color: MedColors.primary),
            label: const Text('Add New Patient',
                style: TextStyle(color: MedColors.primary, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: MedColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          // Account section
          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Account',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: MedColors.primaryDark,
                    letterSpacing: 0.5)),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedColors.slate300),
            ),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.lock_outline, color: MedColors.primary),
                  title: const Text('Change Password',
                      style:
                          TextStyle(fontSize: 16, color: MedColors.slate900)),
                  trailing: const Icon(Icons.chevron_right,
                      color: MedColors.slate500),
                  onTap: () {},
                ),
                const Divider(height: 1, color: MedColors.slate300),
                ListTile(
                  leading:
                      const Icon(Icons.fingerprint, color: MedColors.primary),
                  title: const Text('Biometric Login',
                      style:
                          TextStyle(fontSize: 16, color: MedColors.slate900)),
                  trailing: const Icon(Icons.chevron_right,
                      color: MedColors.slate500),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedPatientTile extends StatelessWidget {
  final String name;
  final String relation;

  const _LinkedPatientTile({required this.name, required this.relation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedColors.slate300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: MedColors.primarySoft,
            child: Text(name[0],
                style: const TextStyle(
                    color: MedColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        color: MedColors.slate900,
                        fontWeight: FontWeight.w500)),
                Text(relation,
                    style: const TextStyle(
                        fontSize: 13, color: MedColors.slate500)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Unlink',
                style: TextStyle(color: MedColors.emergency, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
