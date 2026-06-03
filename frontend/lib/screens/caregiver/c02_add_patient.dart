import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/caregiver_provider.dart';

class C02AddPatient extends ConsumerStatefulWidget {
  const C02AddPatient({super.key});

  @override
  ConsumerState<C02AddPatient> createState() => _C02AddPatientState();
}

class _C02AddPatientState extends ConsumerState<C02AddPatient> {
  final List<String> code = ['', '', '', '', '', ''];
  int currentIndex = 0;
  bool _isLoading = false;
  String? _error;

  void _onKeyPress(String digit) {
    if (currentIndex < 6) {
      setState(() {
        code[currentIndex] = digit;
        currentIndex++;
      });
    }
  }

  void _onDelete() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        code[currentIndex] = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text('Add Patient',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.person_add, size: 64, color: MedColors.primary),
            const SizedBox(height: 16),
            const Text('Enter Invite Code',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MedColors.slate900)),
            const SizedBox(height: 8),
            const Text(
                'Ask your patient to generate a 6-digit code from their profile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: MedColors.slate500)),
            const SizedBox(height: 32),

            // Code boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: code[i].isNotEmpty
                        ? MedColors.primarySoft
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: i == currentIndex
                          ? MedColors.primary
                          : MedColors.slate300,
                      width: i == currentIndex ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(code[i],
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: MedColors.slate900)),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Number keypad
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((d) =>
                    _KeypadButton(label: d, onTap: () => _onKeyPress(d))),
                const SizedBox(),
                _KeypadButton(label: '0', onTap: () => _onKeyPress('0')),
                _KeypadButton(
                  label: '⌫',
                  onTap: _onDelete,
                  color: MedColors.slate500,
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: currentIndex == 6 && !_isLoading
                  ? () async {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(caregiverPatientsProvider.notifier)
                            .acceptInvite(code.join());
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Patient linked successfully.')));
                        if (mounted) nav.pop();
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                          _error = e.toString();
                        });
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedColors.primary,
                disabledBackgroundColor: MedColors.slate300,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Link Patient',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: MedColors.emergency),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
                'You will be linked to the patient as soon as the code is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: MedColors.slate500)),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.color = MedColors.slate900,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MedColors.slate300),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}
