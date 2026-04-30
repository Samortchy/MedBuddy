// lib/screens/fall_verification/widgets/verification_prompt.dart

import 'package:flutter/material.dart';

class VerificationPrompt extends StatelessWidget {
  final String text;

  const VerificationPrompt({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.4,
      ),
    );
  }
}
