import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/sos_button.dart';

class AddEditMedication extends StatelessWidget {
  const AddEditMedication({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: MedBuddyDimens.spacingLg,
                    right: MedBuddyDimens.spacingLg,
                    top: MedBuddyDimens.spacingXl,
                    bottom: MedBuddyDimens.spacingXxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Medication Name'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      const _InputField(
                        hint: 'e.g. Metformin',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Dose'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      const _InputField(
                        hint: 'e.g. 500 mg',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Frequency'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      const _InputField(
                        hint: 'e.g. Once daily',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Time of Day'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      const _TimeOfDaySelector(),
                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Notes (optional)'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      const _InputField(
                        hint: 'e.g. Take with food',
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                      ),
                      const SizedBox(height: MedBuddyDimens.spacingXxl),
                      _SaveButton(onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SOSButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + MedBuddyDimens.spacingMd,
        left: MedBuddyDimens.spacingLg,
        right: MedBuddyDimens.spacingLg,
        bottom: MedBuddyDimens.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
          bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.primaryDark, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MEDICATIONS',
                  style: MedBuddyTextStyles.sectionHeader),
              Text(
                'Add Medication',
                style: MedBuddyTextStyles.heading2
                    .copyWith(color: MedBuddyColors.slate900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: MedBuddyTextStyles.label.copyWith(
        color: MedBuddyColors.slate500,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.hint,
    required this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate500),
        filled: true,
        fillColor: MedBuddyColors.slate100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingMd,
        ),
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
          borderSide:
              const BorderSide(color: MedBuddyColors.primaryMid, width: 1.5),
        ),
      ),
    );
  }
}

// ── Time of Day Selector ──────────────────────────────────────────────────────

class _TimeOfDaySelector extends StatefulWidget {
  const _TimeOfDaySelector();

  @override
  State<_TimeOfDaySelector> createState() => _TimeOfDaySelectorState();
}

class _TimeOfDaySelectorState extends State<_TimeOfDaySelector> {
  final Set<String> _selected = {'Morning'};

  static const _options = ['Morning', 'Afternoon', 'Evening', 'Night'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MedBuddyDimens.spacingSm,
      children: _options.map((option) {
        final isSelected = _selected.contains(option);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selected.remove(option);
            } else {
              _selected.add(option);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: MedBuddyDimens.spacingLg,
                vertical: MedBuddyDimens.spacingSm),
            decoration: BoxDecoration(
              color:
                  isSelected ? MedBuddyColors.primary : MedBuddyColors.slate100,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
              border: isSelected
                  ? null
                  : Border.all(color: MedBuddyColors.slate300, width: 0.5),
            ),
            child: Text(
              option,
              style: MedBuddyTextStyles.secondary.copyWith(
                color: isSelected
                    ? MedBuddyColors.pureWhite
                    : MedBuddyColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Save Button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MedBuddyDimens.buttonHeightPrimary,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: MedBuddyColors.primary,
          foregroundColor: MedBuddyColors.pureWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          'Save Medication',
          style: MedBuddyTextStyles.bodyBold
              .copyWith(color: MedBuddyColors.pureWhite),
        ),
      ),
    );
  }
}
