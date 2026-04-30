import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/fall_provider.dart';
import '../../../widgets/shared/countdown_ring.dart';
import 'fall_detected/widgets/cancel_button.dart';

class FallDetectedScreen extends ConsumerStatefulWidget {
  const FallDetectedScreen({super.key});

  @override
  ConsumerState<FallDetectedScreen> createState() => _FallDetectedScreenState();
}

class _FallDetectedScreenState extends ConsumerState<FallDetectedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warning,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                children: [
                  Icon(Icons.warning_rounded,
                      color: MedBuddyColors.pureWhite, size: 56),
                  SizedBox(height: 20),
                  Text(
                    'Fall Detected',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: MedBuddyColors.pureWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Are you okay?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: MedBuddyColors.pureWhite,
                    ),
                  ),
                ],
              ),
              CountdownRing(
                seconds: 10,
                isPaused: false,
                onExpired: () {
                  ref.read(fallProvider.notifier).confirm();
                  Navigator.of(context)
                      .pushReplacementNamed('/fall-verification');
                },
              ),
              Column(
                children: [
                  CancelButton(
                    onPressed: () {
                      ref.read(fallProvider.notifier).cancel();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emergency services will be contacted\nif no response is given',
                    textAlign: TextAlign.center,
                    style: MedBuddyTextStyles.secondary.copyWith(
                      color: MedBuddyColors.pureWhite.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
