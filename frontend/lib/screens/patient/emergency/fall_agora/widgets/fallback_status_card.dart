// lib/screens/fall_agora/widgets/fallback_status_card.dart

import 'package:flutter/material.dart';

class FallbackStatusCard extends StatelessWidget {
  final bool smsSent;
  final bool callInitiated;

  const FallbackStatusCard({
    super.key,
    required this.smsSent,
    required this.callInitiated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.sms,
            label: 'SMS sent to caregiver',
            done: smsSent,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.phone,
            label: 'Automated call initiated',
            done: callInitiated,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? const Color(0xFF16A34A) : Colors.white38,
          size: 20,
        ),
        const SizedBox(width: 10),
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: done ? Colors.white : Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
