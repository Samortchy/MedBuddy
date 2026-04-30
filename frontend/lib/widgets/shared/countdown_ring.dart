import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class CountdownRing extends StatefulWidget {
  final int seconds;
  final VoidCallback onExpired;
  final Color color;
  final bool isPaused;
  final double size;
  final bool enableColorTween;

  const CountdownRing({
    super.key,
    this.seconds = 10,
    required this.onExpired,
    this.color = MedBuddyColors.warning,
    this.isPaused = false,
    this.size = 160.0,
    this.enableColorTween = true,
  });

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onExpired();
        }
      });

    _colorAnimation = ColorTween(
      begin: MedBuddyColors.pureWhite,
      end: MedBuddyColors.emergency,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0,
          curve: Curves.easeIn), // More aggressive transition
    ));

    if (!widget.isPaused) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _remainingSeconds =>
      ((1.0 - _controller.value) * widget.seconds).ceil();

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.enableColorTween
        ? (_colorAnimation.value ?? MedBuddyColors.pureWhite)
        : MedBuddyColors.pureWhite;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: widget.size > 100 ? 8 : 4,
              color: MedBuddyColors.pureWhite.withValues(alpha: 0.2),
            ),
          ),
          // Countdown ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: _animation.value,
              strokeWidth: widget.size > 100 ? 8 : 4,
              color: ringColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Seconds text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_remainingSeconds',
                style: TextStyle(
                  fontSize: widget.size > 100 ? 48 : 24,
                  fontWeight: FontWeight.bold,
                  color: ringColor,
                ),
              ),
              if (widget.size > 100)
                Text(
                  'sec',
                  style: TextStyle(
                    fontSize: 14,
                    color: MedBuddyColors.pureWhite.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
