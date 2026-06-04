import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/dimens.dart';

/// Persistent SOS floating button.
/// Place inside a Stack as the last child so it floats above all content.
/// Positioned above the bottom nav bar.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: Stack(
///     children: [
///       YourScreenContent(),
///       const SOSButton(),
///     ],
///   ),
/// )
/// ```
class SOSButton extends StatefulWidget {
  /// Called when SOS is confirmed (after 3-second hold).
  /// Wire this to EmergencyService.triggerSOS() when ready.
  final VoidCallback? onSOSConfirmed;

  /// Distance from the bottom of the enclosing Stack. Defaults to
  /// [MedBuddyDimens.sosBottomOffset]; override on screens with a bottom
  /// input bar (e.g. chat) so the button clears it.
  final double? bottom;

  const SOSButton({super.key, this.onSOSConfirmed, this.bottom});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSOSTap() {
    Navigator.of(context).pushNamed('/sos-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottom ?? MedBuddyDimens.sosBottomOffset,
      right: MedBuddyDimens.spacingLg,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: _onSOSTap,
          child: Container(
            width: MedBuddyDimens.sosButtonSize,
            height: MedBuddyDimens.sosButtonSize,
            decoration: BoxDecoration(
              color: MedBuddyColors.emergency,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MedBuddyColors.emergency.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: MedBuddyColors.pureWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
