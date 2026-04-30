import 'package:flutter/material.dart';
import '../../../../../constants/colors.dart';

class CancelButton extends StatefulWidget {
  final VoidCallback onPressed;

  const CancelButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<CancelButton> {
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        const double thumbWidth = 80.0;

        return Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: MedBuddyColors.pureWhite.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Swipe to Cancel",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color:
                              MedBuddyColors.pureWhite.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {},
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue > trackWidth - thumbWidth) {
                        _dragValue = trackWidth - thumbWidth;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragValue > trackWidth - thumbWidth - 10) {
                      widget.onPressed();
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbWidth,
                    height: 80,
                    decoration: BoxDecoration(
                      color: MedBuddyColors.pureWhite,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: MedBuddyColors.warning,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
