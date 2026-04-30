// lib/screens/fall_agora/widgets/connection_status_card.dart

import 'package:flutter/material.dart';

enum AgoraConnectionState { connecting, connected, fallback }

class ConnectionStatusCard extends StatefulWidget {
  final AgoraConnectionState state;
  final String caregiverName;

  const ConnectionStatusCard({
    super.key,
    required this.state,
    required this.caregiverName,
  });

  @override
  State<ConnectionStatusCard> createState() => _ConnectionStatusCardState();
}

class _ConnectionStatusCardState extends State<ConnectionStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    switch (widget.state) {
      case AgoraConnectionState.connecting:
        return _StatusCard(
          key: const ValueKey('connecting'),
          icon: _buildConnectingDots(),
          title: 'Connecting to ${widget.caregiverName}...',
          subtitle: 'Please stay still',
          borderColor: Colors.white54,
        );
      case AgoraConnectionState.connected:
        return _StatusCard(
          key: const ValueKey('connected'),
          icon: const Icon(Icons.check_circle,
              color: Color(0xFF16A34A), size: 40),
          title: 'Connected',
          subtitle: '${widget.caregiverName} can hear you',
          borderColor: const Color(0xFF16A34A),
        );
      case AgoraConnectionState.fallback:
        return _StatusCard(
          key: const ValueKey('fallback'),
          icon: const Icon(Icons.signal_wifi_connected_no_internet_4,
              color: Color(0xFFD97706), size: 40),
          title: 'Could not reach ${widget.caregiverName}',
          subtitle: 'Contacting emergency services',
          borderColor: const Color(0xFFD97706),
        );
    }
  }

  Widget _buildConnectingDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = (((_dotController.value + delay) % 1.0));
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity.clamp(0.2, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Color borderColor;

  const _StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
