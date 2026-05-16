import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class C10PendingLinkApproval extends StatelessWidget {
  const C10PendingLinkApproval({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text('Access Request',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MedColors.slate300),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: MedColors.primarySoft,
                    child: Text('B',
                        style: TextStyle(
                            fontSize: 28,
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
                  const Text('Family Member',
                      style:
                          TextStyle(fontSize: 14, color: MedColors.slate500)),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MedColors.warningLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Requesting Access to Your Profile',
                        style: TextStyle(
                            fontSize: 13,
                            color: MedColors.warning,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('What this person will be able to do:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MedColors.slate900)),

            const SizedBox(height: 12),

            const _PermissionTile(
              icon: Icons.visibility,
              text: 'View your medication schedule and health history',
              allowed: true,
            ),
            const _PermissionTile(
              icon: Icons.notifications,
              text: 'Receive alerts if you miss a dose or need help',
              allowed: true,
            ),
            const _PermissionTile(
              icon: Icons.edit,
              text: 'Edit your medication schedule on your behalf',
              allowed: true,
            ),
            const _PermissionTile(
              icon: Icons.call,
              text: 'Be contacted during emergency events',
              allowed: true,
            ),
            const _PermissionTile(
              icon: Icons.lock,
              text: 'Access your personal account or password',
              allowed: false,
            ),

            const Spacer(),

            // Approve button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: MedColors.success,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Approve Access',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),

            const SizedBox(height: 12),

            // Deny button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: MedColors.emergencyLight,
                foregroundColor: MedColors.emergency,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Deny',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text('You can revoke access at any time from your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: MedColors.slate500)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool allowed;

  const _PermissionTile({
    required this.icon,
    required this.text,
    required this.allowed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  allowed ? MedColors.successLight : MedColors.emergencyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              allowed ? Icons.check : Icons.close,
              color: allowed ? MedColors.success : MedColors.emergency,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 14, color: MedColors.slate700)),
          ),
        ],
      ),
    );
  }
}
