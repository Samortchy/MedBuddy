import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/auth_provider.dart';
import 'c09_caregiver_profile.dart';

class C11Settings extends ConsumerStatefulWidget {
  const C11Settings({super.key});

  @override
  ConsumerState<C11Settings> createState() => _C11SettingsState();
}

class _C11SettingsState extends ConsumerState<C11Settings> {
  bool emergencyAlarm = true;
  bool vibration = true;
  bool lowPriorityAlerts = false;
  bool biometricLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'Emergency Alerts'),
          _SettingsTile(
            icon: Icons.volume_up,
            title: 'Emergency Alarm Sound',
            subtitle: 'Play loud alarm when emergency occurs',
            value: emergencyAlarm,
            onChanged: (v) => setState(() => emergencyAlarm = v),
          ),
          _SettingsTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrate on emergency alerts',
            value: vibration,
            onChanged: (v) => setState(() => vibration = v),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_off,
            title: 'Mute Low-Priority Alerts',
            subtitle: 'Only get notified for emergencies',
            value: lowPriorityAlerts,
            onChanged: (v) => setState(() => lowPriorityAlerts = v),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Account'),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedColors.slate300),
            ),
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: MedColors.primary),
              title: const Text('My Profile',
                  style: TextStyle(
                      fontSize: 16,
                      color: MedColors.slate900,
                      fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right, color: MedColors.slate500),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const C09CaregiverProfile()),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            subtitle: 'Use Face ID or fingerprint to log in',
            value: biometricLogin,
            onChanged: (v) => setState(() => biometricLogin = v),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Support'),
          const _InfoTile(
              icon: Icons.info_outline, title: 'App Version', value: '2.0.0'),
          const _InfoTile(
              icon: Icons.email_outlined,
              title: 'Support Email',
              value: 'support@medbuddy.app'),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/welcome',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MedColors.emergencyLight,
                foregroundColor: MedColors.emergency,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Delete Account',
                style: TextStyle(color: MedColors.slate500, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: MedColors.primaryDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedColors.slate300),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: MedColors.primary),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              color: MedColors.slate900,
              fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: MedColors.slate500),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: MedColors.primary,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedColors.slate300),
      ),
      child: ListTile(
        leading: Icon(icon, color: MedColors.primary),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              color: MedColors.slate900,
              fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 14, color: MedColors.slate500),
        ),
      ),
    );
  }
}
