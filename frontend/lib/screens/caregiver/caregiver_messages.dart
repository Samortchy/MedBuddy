import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/caregiver_provider.dart';
import '../shared/conversation_screen.dart';

/// Caregiver Messages tab — lists linked patients; tap one to open the chat.
class CaregiverMessagesScreen extends ConsumerWidget {
  const CaregiverMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caregiverPatientsProvider);

    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text('Messages',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: state.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: MedColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load patients',
                  style: TextStyle(color: MedColors.emergency)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(caregiverPatientsProvider.notifier).fetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (patients) => patients.isEmpty
            ? const Center(
                child: Text('No linked patients yet.',
                    style: TextStyle(color: MedColors.slate500)))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: patients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = patients[i];
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: MedColors.slate300),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: MedColors.primarySoft,
                      child: Text(
                          p.fullName.isNotEmpty ? p.fullName[0] : '?',
                          style: const TextStyle(
                              color: MedColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MedColors.slate900)),
                    subtitle: const Text('Tap to chat',
                        style: TextStyle(color: MedColors.slate500)),
                    trailing: const Icon(Icons.chat_bubble_outline,
                        color: MedColors.primary),
                    onTap: p.linkId == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  linkId: p.linkId!,
                                  title: p.fullName,
                                ),
                              ),
                            ),
                  );
                },
              ),
      ),
    );
  }
}
