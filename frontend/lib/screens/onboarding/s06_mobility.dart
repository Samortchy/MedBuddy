import 'package:flutter/material.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import 's07_medications_setup.dart';

class S06Mobility extends StatefulWidget {
  const S06Mobility({super.key});

  @override
  State<S06Mobility> createState() => _S06MobilityState();
}

class _S06MobilityState extends State<S06Mobility> {
  String selectedMobility = '';
  String selectedCognition = '';

  final mobilityOptions = <Map<String, Object>>[
    {
      'label': 'Fully Mobile',
      'desc': 'Walk independently without assistance',
      'icon': Icons.directions_walk
    },
    {
      'label': 'Limited',
      'desc': 'Walk with some difficulty or a cane',
      'icon': Icons.accessible_forward
    },
    {
      'label': 'Wheelchair',
      'desc': 'Use a wheelchair for mobility',
      'icon': Icons.wheelchair_pickup
    },
    {'label': 'Bedridden', 'desc': 'Primarily stay in bed', 'icon': Icons.bed},
  ];

  final cognitionOptions = <Map<String, Object>>[
    {
      'label': 'Fully Independent',
      'desc': 'Clear memory and decision-making',
      'icon': Icons.psychology_alt
    },
    {
      'label': 'Mild Impairment',
      'desc': 'Occasional forgetfulness or confusion',
      'icon': Icons.psychology
    },
    {
      'label': 'Needs Guidance',
      'desc': 'Requires frequent reminders and support',
      'icon': Icons.support_agent
    },
  ];

  bool get canProceed =>
      selectedMobility.isNotEmpty && selectedCognition.isNotEmpty;

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
                      'Step 3 of 6',
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Mobility & Cognitive State',
                      style: MedBuddyTextStyles.heading1.copyWith(
                          fontSize: 26, color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'This helps us calibrate fall detection sensitivity and how the app communicates with you.',
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
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
                          const Icon(Icons.privacy_tip_outlined,
                              color: MedBuddyColors.primary, size: 16),
                          const SizedBox(width: MedBuddyDimens.spacingSm),
                          Expanded(
                            child: Text(
                              'This information is private and only used to personalise your experience.',
                              style: MedBuddyTextStyles.secondary
                                  .copyWith(color: MedBuddyColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    Text(
                      'Mobility Level',
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    ...mobilityOptions.map((opt) {
                      final label = opt['label'] as String;
                      return GestureDetector(
                        onTap: () => setState(() => selectedMobility = label),
                        child: _OptionCard(
                          icon: opt['icon'] as IconData,
                          label: label,
                          desc: opt['desc'] as String,
                          selected: selectedMobility == label,
                        ),
                      );
                    }),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    Text(
                      'Cognitive State',
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    ...cognitionOptions.map((opt) {
                      final label = opt['label'] as String;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCognition = label),
                        child: _OptionCard(
                          icon: opt['icon'] as IconData,
                          label: label,
                          desc: opt['desc'] as String,
                          selected: selectedCognition == label,
                        ),
                      );
                    }),

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
                  onPressed: canProceed
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const S07MedicationsSetup()),
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
          const Expanded(child: _ProgressBar(current: 3, total: 6)),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool selected;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
      padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
      decoration: BoxDecoration(
        color: selected ? MedBuddyColors.primarySoft : MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(
          color: selected ? MedBuddyColors.primary : MedBuddyColors.slate300,
          width: selected ? 2 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  selected ? MedBuddyColors.primary : MedBuddyColors.slate100,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
            ),
            child: Icon(
              icon,
              color:
                  selected ? MedBuddyColors.pureWhite : MedBuddyColors.slate500,
              size: 22,
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: MedBuddyTextStyles.bodyBold.copyWith(
                    color: selected
                        ? MedBuddyColors.primaryDark
                        : MedBuddyColors.slate900,
                  ),
                ),
                const SizedBox(height: MedBuddyDimens.spacingXs),
                Text(
                  desc,
                  style: MedBuddyTextStyles.secondary
                      .copyWith(color: MedBuddyColors.slate500),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle,
                color: MedBuddyColors.primary, size: 20),
        ],
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
