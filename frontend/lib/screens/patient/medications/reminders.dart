import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';

class ReminderActive extends StatelessWidget {
  const ReminderActive({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MedBuddyDimens.spacingXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Medication icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: MedBuddyColors.primarySoft,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: MedBuddyColors.primaryLight, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.medication,
                      color: MedBuddyColors.primaryDark, size: 40),
                ),
              ),
              const SizedBox(height: MedBuddyDimens.spacingXl),
              Text(
                'Time to take',
                style: MedBuddyTextStyles.body.copyWith(
                  color: MedBuddyColors.slate500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MedBuddyDimens.spacingXs),
              Text(
                'Metformin',
                style: MedBuddyTextStyles.heading1.copyWith(
                  fontSize: 32,
                  color: MedBuddyColors.slate900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MedBuddyDimens.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: MedBuddyDimens.spacingLg,
                    vertical: MedBuddyDimens.spacingSm),
                decoration: BoxDecoration(
                  color: MedBuddyColors.primarySoft,
                  borderRadius:
                      BorderRadius.circular(MedBuddyDimens.radiusPill),
                ),
                child: Text(
                  '500 mg · Once daily',
                  style: MedBuddyTextStyles.secondary.copyWith(
                    color: MedBuddyColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Escalation timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined,
                      color: MedBuddyColors.slate500, size: 16),
                  const SizedBox(width: MedBuddyDimens.spacingXs),
                  Text(
                    'Escalation in: 15:00',
                    style: MedBuddyTextStyles.secondary.copyWith(
                      color: MedBuddyColors.slate500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MedBuddyDimens.spacingXl),
              // Primary action — I Took It
              SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedBuddyColors.success,
                    foregroundColor: MedBuddyColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    'I Took It',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.pureWhite),
                  ),
                ),
              ),
              const SizedBox(height: MedBuddyDimens.spacingMd),
              // Secondary action — Snooze
              SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MedBuddyColors.slate700,
                    side: const BorderSide(
                        color: MedBuddyColors.slate300, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.snooze, size: 20),
                  label: Text(
                    'Remind me in 10 minutes',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.slate700),
                  ),
                ),
              ),
              const SizedBox(height: MedBuddyDimens.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }
}
