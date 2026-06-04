import 'package:flutter/material.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import 's03_login.dart';

class S02RoleSelection extends StatefulWidget {
  const S02RoleSelection({super.key});

  @override
  State<S02RoleSelection> createState() => _S02RoleSelectionState();
}

class _S02RoleSelectionState extends State<S02RoleSelection> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Custom back bar
            Padding(
              padding: const EdgeInsets.only(
                top: MedBuddyDimens.spacingMd,
                left: MedBuddyDimens.spacingLg,
                right: MedBuddyDimens.spacingLg,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: MedBuddyColors.slate900, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(MedBuddyDimens.spacingXl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: MedBuddyDimens.spacingMd),
                    Text(
                      'Who are you?',
                      style: MedBuddyTextStyles.heading1.copyWith(
                        fontSize: 28,
                        color: MedBuddyColors.slate900,
                      ),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    Text(
                      'This determines your entire app experience.\nYou cannot change this after registration.',
                      style: MedBuddyTextStyles.body.copyWith(
                        color: MedBuddyColors.slate500,
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    // Patient card
                    _RoleCard(
                      role: 'patient',
                      icon: Icons.elderly,
                      title: 'I am a Patient',
                      description:
                          'Track your medications, complete\nwellness check-ins, and stay safe\nwith emergency monitoring.',
                      selected: selectedRole == 'patient',
                      onTap: () => setState(() => selectedRole = 'patient'),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingLg),

                    // Caregiver card
                    _RoleCard(
                      role: 'caregiver',
                      icon: Icons.medical_services,
                      title: 'I am a Caregiver / Family Member',
                      description:
                          'Monitor your patients remotely,\nmanage their medications, and\nrespond to emergency alerts.',
                      selected: selectedRole == 'caregiver',
                      onTap: () => setState(() => selectedRole = 'caregiver'),
                    ),

                    const Spacer(),

                    // Warning note
                    if (selectedRole != null) ...[
                      Container(
                        padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                        margin: const EdgeInsets.only(
                            bottom: MedBuddyDimens.spacingLg),
                        decoration: BoxDecoration(
                          color: MedBuddyColors.warningLight,
                          borderRadius:
                              BorderRadius.circular(MedBuddyDimens.radiusMd),
                          border: Border.all(
                              color: MedBuddyColors.warningMid, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: MedBuddyColors.warning, size: 18),
                            const SizedBox(width: MedBuddyDimens.spacingSm),
                            Expanded(
                              child: Text(
                                'Your role cannot be changed after registration.',
                                style: MedBuddyTextStyles.secondary.copyWith(
                                  color: MedBuddyColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Continue
                    SizedBox(
                      width: double.infinity,
                      height: MedBuddyDimens.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: selectedRole != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        S03Login(role: selectedRole!),
                                  ),
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedBuddyColors.primary,
                          disabledBackgroundColor: MedBuddyColors.slate300,
                          foregroundColor: MedBuddyColors.pureWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: MedBuddyTextStyles.bodyBold
                              .copyWith(color: MedBuddyColors.pureWhite),
                        ),
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
        decoration: BoxDecoration(
          color:
              selected ? MedBuddyColors.primarySoft : MedBuddyColors.pureWhite,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
          border: Border.all(
            color: selected ? MedBuddyColors.primary : MedBuddyColors.slate300,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: MedBuddyColors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: MedBuddyColors.slate300.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    selected ? MedBuddyColors.primary : MedBuddyColors.slate100,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
              ),
              child: Icon(
                icon,
                color: selected
                    ? MedBuddyColors.pureWhite
                    : MedBuddyColors.slate500,
                size: 30,
              ),
            ),
            const SizedBox(width: MedBuddyDimens.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MedBuddyTextStyles.bodyBold.copyWith(
                      fontSize: 17,
                      color: selected
                          ? MedBuddyColors.primaryDark
                          : MedBuddyColors.slate900,
                    ),
                  ),
                  const SizedBox(height: MedBuddyDimens.spacingXs),
                  Text(
                    description,
                    style: MedBuddyTextStyles.secondary.copyWith(
                      color: MedBuddyColors.slate500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: MedBuddyColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
