import 'package:flutter/material.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import 's10_review.dart';

class S09CheckinPrefs extends StatefulWidget {
  const S09CheckinPrefs({super.key});

  @override
  State<S09CheckinPrefs> createState() => _S09CheckinPrefsState();
}

class _S09CheckinPrefsState extends State<S09CheckinPrefs> {
  String selectedTime = 'Morning';
  String selectedModality = 'Voice';
  String selectedFreq = 'Daily';
  double painBaseline = 3.0;

  final times = ['Morning', 'Midday', 'Evening', 'Custom'];
  final modalities = ['Voice', 'Text'];
  final freqs = ['Daily', 'Twice daily', 'Custom'];

  String get painLabel {
    if (painBaseline <= 2) return 'Minimal pain';
    if (painBaseline <= 4) return 'Mild pain';
    if (painBaseline <= 6) return 'Moderate pain';
    if (painBaseline <= 8) return 'Severe pain';
    return 'Extreme pain';
  }

  Color get painColor {
    if (painBaseline <= 3) return MedBuddyColors.success;
    if (painBaseline <= 6) return MedBuddyColors.warningMid;
    return MedBuddyColors.emergency;
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
                      'Step 6 of 6',
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Check-in Preferences',
                      style: MedBuddyTextStyles.heading1.copyWith(
                          fontSize: 26, color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Personalise when and how your AI buddy checks in with you.',
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    // Time of day
                    const _SectionLabel('Preferred check-in time'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    Row(
                      children: times.map((t) {
                        final sel = selectedTime == t;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTime = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(
                                  vertical: MedBuddyDimens.spacingMd),
                              decoration: BoxDecoration(
                                color: sel
                                    ? MedBuddyColors.primary
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
                              child: Text(
                                t,
                                textAlign: TextAlign.center,
                                style: MedBuddyTextStyles.secondary.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? MedBuddyColors.pureWhite
                                      : MedBuddyColors.slate700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Modality
                    const _SectionLabel('How would you like to check in?'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    Row(
                      children: modalities.map((m) {
                        final sel = selectedModality == m;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedModality = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: MedBuddyDimens.spacingXs),
                              padding: const EdgeInsets.all(
                                  MedBuddyDimens.spacingLg),
                              decoration: BoxDecoration(
                                color: sel
                                    ? MedBuddyColors.primarySoft
                                    : MedBuddyColors.pureWhite,
                                borderRadius: BorderRadius.circular(
                                    MedBuddyDimens.radiusLg),
                                border: Border.all(
                                  color: sel
                                      ? MedBuddyColors.primary
                                      : MedBuddyColors.slate300,
                                  width: sel ? 2 : 0.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    m == 'Voice' ? Icons.mic : Icons.keyboard,
                                    color: sel
                                        ? MedBuddyColors.primary
                                        : MedBuddyColors.slate500,
                                    size: 28,
                                  ),
                                  const SizedBox(
                                      height: MedBuddyDimens.spacingSm),
                                  Text(
                                    m,
                                    style: MedBuddyTextStyles.bodyBold.copyWith(
                                      color: sel
                                          ? MedBuddyColors.primaryDark
                                          : MedBuddyColors.slate700,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: MedBuddyDimens.spacingXs),
                                  Text(
                                    m == 'Voice'
                                        ? 'Speak your answers'
                                        : 'Type your answers',
                                    textAlign: TextAlign.center,
                                    style: MedBuddyTextStyles.secondary
                                        .copyWith(
                                            color: MedBuddyColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Frequency
                    const _SectionLabel('Check-in frequency'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    Row(
                      children: freqs.map((f) {
                        final sel = selectedFreq == f;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedFreq = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(
                                  vertical: MedBuddyDimens.spacingMd),
                              decoration: BoxDecoration(
                                color: sel
                                    ? MedBuddyColors.primary
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
                              child: Text(
                                f,
                                textAlign: TextAlign.center,
                                style: MedBuddyTextStyles.secondary.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? MedBuddyColors.pureWhite
                                      : MedBuddyColors.slate700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Pain baseline
                    const _SectionLabel('Your typical pain level (baseline)'),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'The AI uses this to detect when your pain is higher than usual.',
                      style: MedBuddyTextStyles.secondary
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingLg),
                    Container(
                      padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
                      decoration: BoxDecoration(
                        color: MedBuddyColors.pureWhite,
                        borderRadius:
                            BorderRadius.circular(MedBuddyDimens.radiusLg),
                        border: Border.all(
                            color: MedBuddyColors.slate300, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                MedBuddyColors.slate300.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${painBaseline.round()} / 10',
                                style: MedBuddyTextStyles.heading1
                                    .copyWith(fontSize: 28, color: painColor),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: MedBuddyDimens.spacingMd,
                                    vertical: MedBuddyDimens.spacingXs),
                                decoration: BoxDecoration(
                                  color: painColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      MedBuddyDimens.radiusPill),
                                ),
                                child: Text(
                                  painLabel,
                                  style: MedBuddyTextStyles.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: painColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: painColor,
                              thumbColor: painColor,
                              inactiveTrackColor: MedBuddyColors.slate300,
                            ),
                            child: Slider(
                              value: painBaseline,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              onChanged: (v) =>
                                  setState(() => painBaseline = v),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'No pain',
                                style: MedBuddyTextStyles.secondary
                                    .copyWith(color: MedBuddyColors.slate500),
                              ),
                              Text(
                                'Extreme pain',
                                style: MedBuddyTextStyles.secondary
                                    .copyWith(color: MedBuddyColors.slate500),
                              ),
                            ],
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const S10Review()),
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
                    'Review Profile',
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
          const Expanded(child: _ProgressBar(current: 6, total: 6)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          MedBuddyTextStyles.bodyBold.copyWith(color: MedBuddyColors.slate700),
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
