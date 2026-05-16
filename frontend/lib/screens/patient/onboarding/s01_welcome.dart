import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/dimens.dart';
import '../../constants/text_styles.dart';
import 's02_role_selection.dart';

class S01Welcome extends StatefulWidget {
  const S01Welcome({super.key});

  @override
  State<S01Welcome> createState() => _S01WelcomeState();
}

class _S01WelcomeState extends State<S01Welcome> {
  String selectedLanguage = 'English';

  final List<Map<String, String>> languages = [
    {'name': 'English', 'flag': '🇬🇧'},
    {'name': 'العربية', 'flag': '🇸🇦'},
    {'name': 'Français', 'flag': '🇫🇷'},
    {'name': 'Español', 'flag': '🇪🇸'},
    {'name': 'Deutsch', 'flag': '🇩🇪'},
    {'name': 'Italiano', 'flag': '🇮🇹'},
    {'name': 'Türkçe', 'flag': '🇹🇷'},
    {'name': 'فارسی', 'flag': '🇮🇷'},
    {'name': 'Português', 'flag': '🇧🇷'},
    {'name': '中文', 'flag': '🇨🇳'},
  ];

  void _showDemoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MedBuddyColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Try Demo',
                style: MedBuddyTextStyles.heading3
                    .copyWith(color: MedBuddyColors.slate900)),
            const SizedBox(height: 4),
            Text('Skip sign-up and explore with a pre-filled test account.',
                style: MedBuddyTextStyles.secondary
                    .copyWith(color: MedBuddyColors.slate500)),
            const SizedBox(height: 20),
            _DemoOption(
              icon: Icons.person_outline,
              title: 'Patient — Hassan Ali',
              subtitle: 'Age 72 · Diabetes, Hypertension',
              color: MedBuddyColors.primary,
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home', (route) => false),
            ),
            const SizedBox(height: 12),
            _DemoOption(
              icon: Icons.medical_services_outlined,
              title: 'Caregiver — Bakr Mohamed',
              subtitle: '3 linked patients · Family caregiver',
              color: MedBuddyColors.success,
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/caregiver-home', (route) => false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MedBuddyDimens.spacingXl),

              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: MedBuddyColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: MedBuddyColors.pureWhite, size: 30),
              ),
              const SizedBox(height: MedBuddyDimens.spacingLg),

              Text(
                'MedBuddy',
                style: MedBuddyTextStyles.heading1.copyWith(
                  fontSize: 32,
                  color: MedBuddyColors.slate900,
                ),
              ),
              const SizedBox(height: MedBuddyDimens.spacingSm),
              Text(
                'Your AI-powered health companion.\nAlways with you, whenever you need.',
                style: MedBuddyTextStyles.body.copyWith(
                  color: MedBuddyColors.slate500,
                ),
              ),

              const SizedBox(height: MedBuddyDimens.spacingXxl),

              // Voice note
              Container(
                padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                decoration: BoxDecoration(
                  color: MedBuddyColors.primarySoft,
                  borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                  border:
                      Border.all(color: MedBuddyColors.primaryLight, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic,
                        color: MedBuddyColors.primary, size: 20),
                    const SizedBox(width: MedBuddyDimens.spacingSm),
                    Expanded(
                      child: Text(
                        'You can use your voice throughout this app',
                        style: MedBuddyTextStyles.secondary.copyWith(
                          color: MedBuddyColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MedBuddyDimens.spacingXl),

              Text(
                'Choose your language',
                style: MedBuddyTextStyles.bodyBold.copyWith(
                  color: MedBuddyColors.slate900,
                ),
              ),
              const SizedBox(height: MedBuddyDimens.spacingMd),

              // Language grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: MedBuddyDimens.spacingSm,
                  crossAxisSpacing: MedBuddyDimens.spacingSm,
                  childAspectRatio: 2.8,
                  children: languages.map((lang) {
                    final selected = selectedLanguage == lang['name'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedLanguage = lang['name']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selected
                              ? MedBuddyColors.primarySoft
                              : MedBuddyColors.pureWhite,
                          borderRadius:
                              BorderRadius.circular(MedBuddyDimens.radiusMd),
                          border: Border.all(
                            color: selected
                                ? MedBuddyColors.primary
                                : MedBuddyColors.slate300,
                            width: selected ? 2 : 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(lang['flag']!,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: MedBuddyDimens.spacingSm),
                            Text(
                              lang['name']!,
                              style: MedBuddyTextStyles.secondary.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: selected
                                    ? MedBuddyColors.primaryDark
                                    : MedBuddyColors.slate700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: MedBuddyDimens.spacingLg),

              // Get Started
              SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const S02RoleSelection()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedBuddyColors.primary,
                    foregroundColor: MedBuddyColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.pureWhite),
                  ),
                ),
              ),

              const SizedBox(height: MedBuddyDimens.spacingSm),

              // Demo shortcut
              SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: OutlinedButton(
                  onPressed: () => _showDemoSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MedBuddyColors.slate500,
                    side: const BorderSide(
                        color: MedBuddyColors.slate300, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  child: Text(
                    'Try Demo',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.slate500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DemoOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.slate900)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: MedBuddyTextStyles.secondary
                          .copyWith(color: MedBuddyColors.slate500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
