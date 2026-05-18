import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import '/providers/onboarding_provider.dart';

class S10Review extends ConsumerStatefulWidget {
  const S10Review({super.key});

  @override
  ConsumerState<S10Review> createState() => _S10ReviewState();
}

class _S10ReviewState extends ConsumerState<S10Review> {
  bool _submitting = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(onboardingProvider.notifier).submit();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);

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
                      onEdit: () =>
                          Navigator.of(context).pushNamed('/profile/basic'),
                      children: [
                        _ReviewRow(
                            label: 'Name',
                            value: data.fullName.isEmpty ? '—' : data.fullName),
                        _ReviewRow(label: 'Age', value: '${data.age}'),
                        _ReviewRow(
                            label: 'Gender',
                            value: data.gender.isEmpty ? '—' : data.gender),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '02',
                      title: 'Health Conditions',
                      onEdit: () =>
                          Navigator.of(context).pushNamed('/profile/conditions'),
                      children: [
                        _ReviewRow(
                          label: 'Conditions',
                          value: data.conditions.isEmpty
                              ? 'None'
                              : data.conditions.join(', '),
                        ),
                        _ReviewRow(
                          label: 'Duration',
                          value: data.conditionDuration == 'chronic'
                              ? 'Long-term / Chronic'
                              : 'New',
                        ),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '03',
                      title: 'Mobility & Cognitive State',
                      onEdit: () =>
                          Navigator.of(context).pushNamed('/profile/mobility'),
                      children: [
                        _ReviewRow(label: 'Mobility', value: data.mobilityLevel),
                        _ReviewRow(
                            label: 'Cognition', value: data.cognitiveState),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '04',
                      title: 'Medications',
                      onEdit: () =>
                          Navigator.of(context).pushNamed('/profile/meds'),
                      children: data.medications.isEmpty
                          ? [const _ReviewRow(label: 'None added', value: '')]
                          : data.medications
                              .map((m) => _ReviewRow(
                                    label: m.name,
                                    value:
                                        '${m.dosage} · ${m.frequency}',
                                  ))
                              .toList(),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '05',
                      title: 'Emergency Contacts',
                      onEdit: () =>
                          Navigator.of(context).pushNamed('/profile/contacts'),
                      children: data.contacts.isEmpty
                          ? [const _ReviewRow(label: 'None added', value: '')]
                          : data.contacts
                              .map((c) => _ReviewRow(
                                    label: c.priority == 1
                                        ? 'Primary'
                                        : 'Secondary',
                                    value: '${c.name} · ${c.relation}',
                                  ))
                              .toList(),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),

                    _ReviewCard(
                      step: '06',
                      title: 'Check-in Preferences',
                      onEdit: () =>
                          Navigator.of(context).pushNamed('/profile/checkin'),
                      children: [
                        _ReviewRow(label: 'Time', value: data.checkinTime),
                        _ReviewRow(
                            label: 'Frequency', value: data.checkinFrequency),
                        _ReviewRow(
                          label: 'Pain baseline',
                          value:
                              '${data.painBaseline.toStringAsFixed(1)} / 10',
                        ),
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

                    if (_error != null) ...[
                      const SizedBox(height: MedBuddyDimens.spacingMd),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                        decoration: BoxDecoration(
                          color: MedBuddyColors.emergency.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(MedBuddyDimens.radiusMd),
                        ),
                        child: Text(
                          _error!,
                          style: MedBuddyTextStyles.secondary
                              .copyWith(color: MedBuddyColors.emergency),
                        ),
                      ),
                    ],

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
                  onPressed: _submitting ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedBuddyColors.primary,
                    foregroundColor: MedBuddyColors.pureWhite,
                    disabledBackgroundColor:
                        MedBuddyColors.primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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
