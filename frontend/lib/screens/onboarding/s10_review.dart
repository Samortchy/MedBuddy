import 'package:flutter/material.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';

class S10Review extends StatelessWidget {
  const S10Review({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Almost there!',
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Review Your Profile',
                      style: MedBuddyTextStyles.heading1.copyWith(
                          fontSize: 26, color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Check everything looks correct. Tap any section to edit.',
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    _ReviewCard(
                      step: '01',
                      title: 'Basic Information',
                      onEdit: () => Navigator.of(context).pushNamed('/profile/basic'),
                      children: const [
                        _ReviewRow(label: 'Name', value: 'Hassan Ali'),
                        _ReviewRow(label: 'Age', value: '72'),
                        _ReviewRow(label: 'Gender', value: 'Male'),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '02',
                      title: 'Health Conditions',
                      onEdit: () => Navigator.of(context).pushNamed('/profile/conditions'),
                      children: const [
                        _ReviewRow(
                            label: 'Conditions',
                            value: 'Diabetes, Hypertension'),
                        _ReviewRow(
                            label: 'Duration', value: 'Long-term / Chronic'),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '03',
                      title: 'Mobility & Cognitive State',
                      onEdit: () => Navigator.of(context).pushNamed('/profile/mobility'),
                      children: const [
                        _ReviewRow(label: 'Mobility', value: 'Fully Mobile'),
                        _ReviewRow(
                            label: 'Cognition', value: 'Fully Independent'),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '04',
                      title: 'Medications',
                      onEdit: () => Navigator.of(context).pushNamed('/profile/meds'),
                      children: const [
                        _ReviewRow(
                            label: 'Metformin', value: '500mg · Twice daily'),
                        _ReviewRow(
                            label: 'Amlodipine', value: '5mg · Once daily'),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '05',
                      title: 'Emergency Contacts',
                      onEdit: () => Navigator.of(context).pushNamed('/profile/contacts'),
                      children: const [
                        _ReviewRow(
                            label: 'Primary', value: 'Bakr Mohamed · Son'),
                        _ReviewRow(label: 'Phone', value: '+20 100 000 0000'),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '06',
                      title: 'Check-in Preferences',
                      onEdit: () => Navigator.of(context).pushNamed('/profile/checkin'),
                      children: const [
                        _ReviewRow(label: 'Time', value: 'Morning'),
                        _ReviewRow(label: 'Modality', value: 'Voice'),
                        _ReviewRow(label: 'Frequency', value: 'Daily'),
                        _ReviewRow(
                            label: 'Pain baseline',
                            value: '3 / 10 — Mild pain'),
                      ],
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Privacy note
                    Container(
                      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                      decoration: BoxDecoration(
                        color: MedBuddyColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(MedBuddyDimens.radiusMd),
                        border: Border.all(
                            color: MedBuddyColors.primaryLight, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: MedBuddyColors.primary, size: 18),
                          const SizedBox(width: MedBuddyDimens.spacingSm),
                          Expanded(
                            child: Text(
                              'Your data is encrypted and stored securely. We never sell your health information.',
                              style: MedBuddyTextStyles.secondary.copyWith(
                                  color: MedBuddyColors.primaryDark,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXxl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
              child: SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (route) => false);
                  },
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
                    'Confirm & Enter MedBuddy',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.pureWhite),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: MedBuddyDimens.spacingMd,
        left: MedBuddyDimens.spacingLg,
        right: MedBuddyDimens.spacingLg,
        bottom: MedBuddyDimens.spacingMd,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.slate900, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Row(
              children: List.generate(
                6,
                (_) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: MedBuddyColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String step;
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _ReviewCard({
    required this.step,
    required this.title,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: MedBuddyColors.slate300.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: MedBuddyDimens.spacingLg,
                vertical: MedBuddyDimens.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: MedBuddyColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: MedBuddyTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: MedBuddyColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MedBuddyDimens.spacingSm),
                Text(
                  title,
                  style: MedBuddyTextStyles.bodyBold
                      .copyWith(color: MedBuddyColors.slate900),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    'Edit',
                    style: MedBuddyTextStyles.secondary.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MedBuddyColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MedBuddyColors.slate300),
          Padding(
            padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: MedBuddyTextStyles.secondary
                  .copyWith(color: MedBuddyColors.slate500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MedBuddyTextStyles.secondary.copyWith(
                fontWeight: FontWeight.w600,
                color: MedBuddyColors.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
