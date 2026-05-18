import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import '/providers/onboarding_provider.dart';
import 's06_mobility.dart';

class S05Conditions extends ConsumerStatefulWidget {
  const S05Conditions({super.key});

  @override
  ConsumerState<S05Conditions> createState() => _S05ConditionsState();
}

class _S05ConditionsState extends ConsumerState<S05Conditions> {
  final Set<String> selectedConditions = {};
  String duration = '';
  final _otherController = TextEditingController();
  bool showOther = false;

  final conditions = <Map<String, Object>>[
    {'name': 'Diabetes', 'icon': Icons.water_drop},
    {'name': 'Hypertension', 'icon': Icons.favorite},
    {'name': 'Heart Disease', 'icon': Icons.monitor_heart},
    {'name': "Alzheimer's", 'icon': Icons.psychology},
    {'name': 'COPD', 'icon': Icons.air},
    {'name': 'Post-Surgery', 'icon': Icons.healing},
    {'name': 'Arthritis', 'icon': Icons.accessibility_new},
    {'name': 'Kidney Disease', 'icon': Icons.science},
    {'name': 'Diabetes Type 2', 'icon': Icons.bloodtype},
    {'name': 'Osteoporosis', 'icon': Icons.fitness_center},
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

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
                      'Step 2 of 6',
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Health Conditions',
                      style: MedBuddyTextStyles.heading1.copyWith(
                          fontSize: 26, color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Select all that apply. This helps personalise your check-in questions and reminders.',
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Condition grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: MedBuddyDimens.spacingSm,
                      crossAxisSpacing: MedBuddyDimens.spacingSm,
                      childAspectRatio: 2.2,
                      children: [
                        ...conditions.map((c) {
                          final name = c['name'] as String;
                          final icon = c['icon'] as IconData;
                          final sel = selectedConditions.contains(name);
                          return GestureDetector(
                            onTap: () => setState(() {
                              sel
                                  ? selectedConditions.remove(name)
                                  : selectedConditions.add(name);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: sel
                                    ? MedBuddyColors.primarySoft
                                    : MedBuddyColors.pureWhite,
                                borderRadius: BorderRadius.circular(
                                    MedBuddyDimens.radiusMd),
                                border: Border.all(
                                  color: sel
                                      ? MedBuddyColors.primary
                                      : MedBuddyColors.slate300,
                                  width: sel ? 2 : 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icon,
                                      color: sel
                                          ? MedBuddyColors.primary
                                          : MedBuddyColors.slate500,
                                      size: 18),
                                  const SizedBox(
                                      width: MedBuddyDimens.spacingSm),
                                  Flexible(
                                    child: Text(
                                      name,
                                      style:
                                          MedBuddyTextStyles.secondary.copyWith(
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: sel
                                            ? MedBuddyColors.primaryDark
                                            : MedBuddyColors.slate700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Other chip
                        GestureDetector(
                          onTap: () => setState(() => showOther = !showOther),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: showOther
                                  ? MedBuddyColors.primarySoft
                                  : MedBuddyColors.pureWhite,
                              borderRadius: BorderRadius.circular(
                                  MedBuddyDimens.radiusMd),
                              border: Border.all(
                                color: showOther
                                    ? MedBuddyColors.primary
                                    : MedBuddyColors.slate300,
                                width: showOther ? 2 : 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: showOther
                                        ? MedBuddyColors.primary
                                        : MedBuddyColors.slate500,
                                    size: 18),
                                const SizedBox(width: MedBuddyDimens.spacingXs),
                                Text(
                                  'Other',
                                  style: MedBuddyTextStyles.secondary.copyWith(
                                    fontWeight: showOther
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: showOther
                                        ? MedBuddyColors.primaryDark
                                        : MedBuddyColors.slate700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (showOther) ...[
                      const SizedBox(height: MedBuddyDimens.spacingMd),
                      TextField(
                        controller: _otherController,
                        style: MedBuddyTextStyles.body
                            .copyWith(color: MedBuddyColors.slate900),
                        decoration: InputDecoration(
                          hintText: 'Describe your condition...',
                          hintStyle: MedBuddyTextStyles.body
                              .copyWith(color: MedBuddyColors.slate500),
                          filled: true,
                          fillColor: MedBuddyColors.slate100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                            borderSide: const BorderSide(
                                color: MedBuddyColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    Text(
                      'How long have you had this / these conditions?',
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.slate700),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    Row(
                      children: [
                        _DurationChip(
                          label: 'Newly diagnosed',
                          selected: duration == 'new',
                          onTap: () => setState(() => duration = 'new'),
                        ),
                        const SizedBox(width: MedBuddyDimens.spacingSm),
                        _DurationChip(
                          label: 'Long-term / Chronic',
                          selected: duration == 'chronic',
                          onTap: () => setState(() => duration = 'chronic'),
                        ),
                      ],
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
                    final condList = [
                      ...selectedConditions,
                      if (showOther && _otherController.text.trim().isNotEmpty)
                        _otherController.text.trim(),
                    ];
                    ref.read(onboardingProvider.notifier).setConditions(
                          conditions: condList,
                          duration: duration.isEmpty ? 'chronic' : duration,
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const S06Mobility()),
                    );
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
                    'Next',
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
          const Expanded(child: _ProgressBar(current: 2, total: 6)),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(vertical: MedBuddyDimens.spacingMd),
          decoration: BoxDecoration(
            color: selected
                ? MedBuddyColors.primarySoft
                : MedBuddyColors.pureWhite,
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
            border: Border.all(
              color:
                  selected ? MedBuddyColors.primary : MedBuddyColors.slate300,
              width: selected ? 2 : 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: MedBuddyTextStyles.secondary.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? MedBuddyColors.primaryDark
                  : MedBuddyColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        total,
        (i) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i < current
                  ? MedBuddyColors.primary
                  : MedBuddyColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
