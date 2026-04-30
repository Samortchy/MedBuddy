// lib/screens/fall_verification/widgets/factor_overlay.dart

import 'package:flutter/material.dart';
import 'mic_indicator.dart';
import 'verification_prompt.dart';

class FactorOverlay extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFailed;

  const FactorOverlay({
    super.key,
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  State<FactorOverlay> createState() => _FactorOverlayState();
}

class _FactorOverlayState extends State<FactorOverlay> {
  int _secondsLeft = 30;
  // ignore: unused_field
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Stream.periodic(const Duration(seconds: 1), (i) => i).take(30).listen(
      (i) {
        if (!mounted) return;
        setState(() => _secondsLeft = 29 - i);
      },
      onDone: () {
        if (mounted) widget.onFailed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 48,
              ),
              const SizedBox(height: 16),
              const VerificationPrompt(
                text: "We didn't catch that.\nPlease say your full name again.",
              ),
              const SizedBox(height: 32),
              const MicIndicator(isListening: true),
              const SizedBox(height: 16),
              Text(
                '$_secondsLeft seconds remaining',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onFailed,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        foregroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Call Emergency'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSuccess,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("I'm Okay"),
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
