import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';

/// S-12 — SOS Confirmation Overlay
///
/// Full-screen red overlay shown immediately after SOS button tap.
/// User must hold the confirm button for 3 seconds to trigger SOS.
/// Cancel dismisses without any action.
///
/// Backend hooks:
/// - [onSOSConfirmed] → EmergencyService.triggerSOS() — called after 3s hold
/// - [onCancelled]    → Dismiss overlay, no action taken
///
/// Note: This screen is shown as a full-screen route pushed on top of
/// whatever screen the user is on. Use MaterialPageRoute with
/// fullscreenDialog: true.
class SOSConfirmationScreen extends StatefulWidget {
  final VoidCallback? onSOSConfirmed;
  final VoidCallback? onCancelled;

  const SOSConfirmationScreen({
    super.key,
    this.onSOSConfirmed,
    this.onCancelled,
  });

  @override
  State<SOSConfirmationScreen> createState() => _SOSConfirmationScreenState();
}

class _SOSConfirmationScreenState extends State<SOSConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _countdownController;
  late Animation<double> _progressAnimation;

  // Hold duration in seconds per spec
  static const int _holdDurationSeconds = 3;
  int _remainingSeconds = _holdDurationSeconds;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _holdDurationSeconds),
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _countdownController.addListener(() {
      final elapsed =
          (_countdownController.value * _holdDurationSeconds).ceil();
      final remaining = _holdDurationSeconds - elapsed + 1;
      if (remaining != _remainingSeconds && mounted) {
        setState(
            () => _remainingSeconds = remaining.clamp(0, _holdDurationSeconds));
      }
    });

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSOSTiggered();
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  void _startHolding() {
    setState(() => _isHolding = true);
    _countdownController.forward();
  }

  void _stopHolding() {
    if (_countdownController.isCompleted) return;
    setState(() {
      _isHolding = false;
      _remainingSeconds = _holdDurationSeconds;
    });
    _countdownController.reset();
  }

  void _onSOSTiggered() {
    // TODO: await EmergencyService.triggerSOS()
    widget.onSOSConfirmed?.call();
    // Navigate to S-18 SOS Active screen
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
    // );
  }

  void _cancel() {
    widget.onCancelled?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MedBuddyDimens.spacingXl,
            vertical: MedBuddyDimens.spacingXxl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopSection(),
              _buildCountdownRing(),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: MedBuddyColors.pureWhite.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_outlined,
              color: MedBuddyColors.pureWhite, size: 32),
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        const Text(
          'SOS Alert',
          style: MedBuddyTextStyles.emergencyScreen,
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Text(
          'Hold the button for $_holdDurationSeconds seconds to confirm\nand alert your emergency contacts.',
          style: MedBuddyTextStyles.body.copyWith(
            color: MedBuddyColors.pureWhite.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCountdownRing() {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startHolding(),
          onLongPressEnd: (_) => _stopHolding(),
          onLongPressCancel: _stopHolding,
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    color: MedBuddyColors.pureWhite.withValues(alpha: 0.2),
                  ),
                ),
                // Progress ring
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (_, __) => SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: 1.0 - _progressAnimation.value,
                      strokeWidth: 8,
                      color: MedBuddyColors.pureWhite,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                // Countdown number
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_remainingSeconds',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: MedBuddyColors.pureWhite,
                        height: 1,
                      ),
                    ),
                    Text(
                      'seconds',
                      style: MedBuddyTextStyles.label.copyWith(
                        color: MedBuddyColors.pureWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Text(
          _isHolding ? 'Keep holding to confirm SOS' : 'Hold the button above',
          style: MedBuddyTextStyles.label.copyWith(
            color: MedBuddyColors.pureWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: MedBuddyDimens.buttonHeightPrimary,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MedBuddyColors.pureWhite,
              foregroundColor: MedBuddyColors.emergency,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
              ),
              elevation: 0,
            ),
            onPressed: _cancel,
            child: Text(
              'Cancel',
              style: MedBuddyTextStyles.bodyBold
                  .copyWith(color: MedBuddyColors.emergency, fontSize: 17),
            ),
          ),
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Text(
          'Release to cancel · SMS will NOT be sent',
          style: MedBuddyTextStyles.caption
              .copyWith(color: MedBuddyColors.pureWhite.withValues(alpha: 0.6)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
