// lib/screens/fall_verification/widgets/waveform_animator.dart

import 'package:flutter/material.dart';
import 'dart:math';

class WaveformAnimator extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const WaveformAnimator({
    super.key,
    required this.isPlaying,
    this.color = Colors.white,
  });

  @override
  State<WaveformAnimator> createState() => _WaveformAnimatorState();
}

class _WaveformAnimatorState extends State<WaveformAnimator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int _barCount = 7;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(400)),
      )..repeat(reverse: true);
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 8,
        end: 48 + _random.nextDouble() * 24,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void didUpdateWidget(WaveformAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      for (var c in _controllers) {
        if (!c.isAnimating) c.repeat(reverse: true);
      }
    } else {
      for (var c in _controllers) {
        c.stop();
        c.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: widget.isPlaying ? _animations[i].value : 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
