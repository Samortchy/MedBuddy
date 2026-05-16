import 'package:flutter/material.dart';
import '/constants/colors.dart';

class C07EmergencyActive extends StatefulWidget {
  const C07EmergencyActive({super.key});

  @override
  State<C07EmergencyActive> createState() => _C07EmergencyActiveState();
}

class _C07EmergencyActiveState extends State<C07EmergencyActive>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool alarmMuted = false;
  bool handled = false;
  String connectionStatus = 'connecting'; // connecting, connected, fallback

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate Agora connecting then connected
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => connectionStatus = 'connected');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      alarmMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => setState(() => alarmMuted = !alarmMuted),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Pulsing emergency icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded,
                      color: Colors.white, size: 56),
                ),
              ),

              const SizedBox(height: 20),

              // Emergency label
              const Text('EMERGENCY',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  )),
              const SizedBox(height: 8),
              const Text('Fall Detected — Hassan Ali',
                  style: TextStyle(fontSize: 18, color: Colors.white70)),
              const Text('Apr 4, 2026 • 2:10 AM',
                  style: TextStyle(fontSize: 14, color: Colors.white54)),

              const SizedBox(height: 24),

              // Agora connection status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          connectionStatus == 'connected'
                              ? Icons.mic
                              : connectionStatus == 'fallback'
                                  ? Icons.sms
                                  : Icons.connecting_airports,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          connectionStatus == 'connected'
                              ? 'Audio Connected — You can hear Hassan'
                              : connectionStatus == 'fallback'
                                  ? 'Audio failed — SMS sent to Hassan'
                                  : 'Connecting to Hassan Ali...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (connectionStatus == 'connected') ...[
                      const SizedBox(height: 12),
                      // Waveform animation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(12, (i) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300 + (i * 50)),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4,
                            height: (i % 3 == 0)
                                ? 24.0
                                : (i % 2 == 0)
                                    ? 16.0
                                    : 10.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // GPS location card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last Known Location',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                          Text('14 Tahrir St, Cairo, Egypt',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, color: Colors.white70, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Fall event details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Details',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _EventDetailRow(
                        label: 'Detection time', value: '2:10:04 AM'),
                    _EventDetailRow(
                        label: 'Factor 1 (Name)', value: 'No response'),
                    _EventDetailRow(
                        label: 'Factor 1.5 (Retry)', value: 'No response'),
                    _EventDetailRow(
                        label: 'Factor 2 (Agora)', value: 'Triggered'),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              if (!handled) ...[
                ElevatedButton.icon(
                  onPressed: () => setState(() => handled = true),
                  icon:
                      const Icon(Icons.check_circle, color: MedColors.success),
                  label: const Text("I'm Handling It",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MedColors.success,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text('Call 911',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    elevation: 0,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MedColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: MedColors.success),
                      SizedBox(width: 8),
                      Text('Emergency Acknowledged',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: MedColors.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Outcome logging
                const Text('Log outcome:',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    _OutcomeButton(
                        label: 'False Alarm', color: MedColors.warningMid),
                    SizedBox(width: 8),
                    _OutcomeButton(label: 'Handled', color: MedColors.success),
                    SizedBox(width: 8),
                    _OutcomeButton(
                        label: '911 Called', color: MedColors.emergency),
                  ],
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _EventDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  final String label;
  final Color color;

  const _OutcomeButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}
