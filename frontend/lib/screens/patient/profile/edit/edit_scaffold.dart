import 'package:flutter/material.dart';
import '../../../../utils/nav_helpers.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/dimens.dart';
import '../../../../constants/text_styles.dart';
import '../../../../widgets/shared/sos_button.dart';

/// Shared chrome for the profile section editors: a back app bar, a scrolling
/// body, an optional error banner, and a primary Save button.
class EditScaffold extends StatelessWidget {
  final String sectionLabel;
  final String title;
  final List<Widget> children;
  final bool isLoading;
  final bool canSave;
  final String? error;
  final VoidCallback onSave;
  final String saveLabel;

  const EditScaffold({
    super.key,
    required this.sectionLabel,
    required this.title,
    required this.children,
    required this.isLoading,
    required this.canSave,
    required this.onSave,
    this.error,
    this.saveLabel = 'Save Changes',
  });

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
                      ...children,
                      if (error != null) ...[
                        const SizedBox(height: MedBuddyDimens.spacingMd),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                          decoration: BoxDecoration(
                            color:
                                MedBuddyColors.emergency.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusMd),
                          ),
                          child: Text(
                            error!,
                            style: MedBuddyTextStyles.secondary
                                .copyWith(color: MedBuddyColors.emergency),
                          ),
                        ),
                      ],
                      const SizedBox(height: MedBuddyDimens.spacingXxl),
                      SizedBox(
                        width: double.infinity,
                        height: MedBuddyDimens.buttonHeightPrimary,
                        child: ElevatedButton(
                          onPressed: (canSave && !isLoading) ? onSave : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MedBuddyColors.primary,
                            foregroundColor: MedBuddyColors.pureWhite,
                            disabledBackgroundColor: MedBuddyColors.slate300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(MedBuddyDimens.radiusLg),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  saveLabel,
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
            onTap: () => goBack(context, fallbackRoute: '/my-profile'),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.primaryDark, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sectionLabel, style: MedBuddyTextStyles.sectionHeader),
              Text(
                title,
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

/// Field label used across the editors.
class EditFieldLabel extends StatelessWidget {
  final String text;
  const EditFieldLabel(this.text, {super.key});

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

/// Input decoration matching the rest of the app's text fields.
InputDecoration editInputDecoration(String hint) => InputDecoration(
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
        borderSide: const BorderSide(color: MedBuddyColors.primaryMid, width: 1.5),
      ),
    );
