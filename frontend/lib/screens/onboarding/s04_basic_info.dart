import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import '/providers/onboarding_provider.dart';
import 's05_conditions.dart';

class S04BasicInfo extends ConsumerStatefulWidget {
  const S04BasicInfo({super.key});

  @override
  ConsumerState<S04BasicInfo> createState() => _S04BasicInfoState();
}

class _S04BasicInfoState extends ConsumerState<S04BasicInfo> {
  final _nameController = TextEditingController();
  int selectedAge = 65;
  String selectedGender = '';

  final genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get canProceed =>
      _nameController.text.trim().isNotEmpty && selectedGender.isNotEmpty;

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
                      'Step 1 of 6',
                      style: MedBuddyTextStyles.label.copyWith(
                        color: MedBuddyColors.slate500,
                      ),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Basic Information',
                      style: MedBuddyTextStyles.heading1.copyWith(
                        fontSize: 26,
                        color: MedBuddyColors.slate900,
                      ),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Your full name is used for safety verification during emergencies.',
                      style: MedBuddyTextStyles.body.copyWith(
                        color: MedBuddyColors.slate500,
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    // Full name
                    const _FieldLabel('Full Name'),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            onChanged: (_) => setState(() {}),
                            style: MedBuddyTextStyles.body.copyWith(
                              color: MedBuddyColors.slate900,
                            ),
                            decoration: _inputDecoration('e.g. Hassan Ali'),
                          ),
                        ),
                        const SizedBox(width: MedBuddyDimens.spacingSm),
                        const _MicButton(),
                      ],
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    Container(
                      padding: const EdgeInsets.all(MedBuddyDimens.spacingSm),
                      decoration: BoxDecoration(
                        color: MedBuddyColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(MedBuddyDimens.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: MedBuddyColors.primary, size: 16),
                          const SizedBox(width: MedBuddyDimens.spacingSm),
                          Expanded(
                            child: Text(
                              'Used for liveness verification: the app will ask you to say your name during emergencies.',
                              style: MedBuddyTextStyles.secondary.copyWith(
                                color: MedBuddyColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Age
                    const _FieldLabel('Age'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            if (selectedAge > 1) selectedAge--;
                          }),
                          child: const _AgeButton(icon: Icons.remove),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$selectedAge',
                              style: MedBuddyTextStyles.heading1.copyWith(
                                fontSize: 36,
                                color: MedBuddyColors.slate900,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            if (selectedAge < 120) selectedAge++;
                          }),
                          child: const _AgeButton(icon: Icons.add),
                        ),
                      ],
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Gender
                    const _FieldLabel('Gender'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    ...genders.map((g) {
                      final selected = selectedGender == g;
                      return GestureDetector(
                        onTap: () => setState(() => selectedGender = g),
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: MedBuddyDimens.spacingSm),
                          padding:
                              const EdgeInsets.all(MedBuddyDimens.spacingLg),
                          decoration: BoxDecoration(
                            color: selected
                                ? MedBuddyColors.primarySoft
                                : MedBuddyColors.pureWhite,
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                            border: Border.all(
                              color: selected
                                  ? MedBuddyColors.primary
                                  : MedBuddyColors.slate300,
                              width: selected ? 2 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                g,
                                style: MedBuddyTextStyles.body.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? MedBuddyColors.primaryDark
                                      : MedBuddyColors.slate700,
                                ),
                              ),
                              const Spacer(),
                              if (selected)
                                const Icon(Icons.check_circle,
                                    color: MedBuddyColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    // Next
                    SizedBox(
                      width: double.infinity,
                      height: MedBuddyDimens.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: canProceed
                            ? () {
                                ref.read(onboardingProvider.notifier).setBasicInfo(
                                      fullName: _nameController.text.trim(),
                                      age: selectedAge,
                                      gender: selectedGender,
                                    );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const S05Conditions()),
                                );
                              }
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
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
          const Expanded(child: _WizardProgressBar(current: 1, total: 6)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate500),
      filled: true,
      fillColor: MedBuddyColors.slate100,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingLg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        borderSide: const BorderSide(color: MedBuddyColors.primary, width: 2),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _WizardProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _WizardProgressBar({required this.current, required this.total});

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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: MedBuddyTextStyles.label.copyWith(
        fontWeight: FontWeight.w600,
        color: MedBuddyColors.slate700,
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: MedBuddyDimens.micButtonSize,
        height: MedBuddyDimens.micButtonSize,
        decoration: BoxDecoration(
          color: MedBuddyColors.primarySoft,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
          border: Border.all(color: MedBuddyColors.primaryLight, width: 1),
        ),
        child: const Icon(Icons.mic, color: MedBuddyColors.primary, size: 24),
      ),
    );
  }
}

class _AgeButton extends StatelessWidget {
  final IconData icon;
  const _AgeButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
      ),
      child: Icon(icon, color: MedBuddyColors.slate700, size: 22),
    );
  }
}
