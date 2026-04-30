// lib/screens/fall_agora/widgets/sos_countdown_card.dart

import 'package:flutter/material.dart';

class SosCountdownCard extends StatelessWidget {
  final int secondsLeft;
  final bool activated;
  final VoidCallback onCancel;

  const SosCountdownCard({
    super.key,
    required this.secondsLeft,
    required this.activated,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: activated
            ? const Color(0xFFDC2626)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activated ? Colors.white : Colors.white54,
          width: 2,
        ),
      ),
      child: activated
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_police, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  '911 Has Been Contacted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                // Main content
                Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          const TextSpan(text: '911 activates in '),
                          TextSpan(
                            text: '$secondsLeft',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' seconds'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel, size: 24),
                        label: const Text(
                          'Cancel 911',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
