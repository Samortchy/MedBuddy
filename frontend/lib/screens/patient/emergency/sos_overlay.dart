import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class SOSOverlay extends StatelessWidget {
  const SOSOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 100,
                color: Colors.white,
              ),

              const SizedBox(height: 20),

              const Text(
                "SOS EMERGENCY",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                "Hold to confirm emergency alert",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // 🔴 Confirm Button (later will be HOLD)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  // TODO: Navigate to SOS Active (S-18 later)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("SOS Triggered")),
                  );
                },
                child: const Text(
                  "CONFIRM SOS",
                  style: TextStyle(color: AppColors.emergency),
                ),
              ),

              const SizedBox(height: 15),

              // ❌ Cancel Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black26,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
