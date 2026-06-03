import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/ai_provider.dart';
import '/providers/patient_provider.dart';
import 'checkin/s17_ai_buddy_chat.dart';
import '../shared/conversation_screen.dart';
import '../../widgets/shared/sos_button.dart';

/// Patient chat hub: an "AI Buddy" tab + a "Caregiver" tab (real messaging).
class PatientChatHub extends ConsumerWidget {
  const PatientChatHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: MedBuddyColors.warmWhite,
        appBar: AppBar(
          backgroundColor: MedBuddyColors.primaryDark,
          foregroundColor: Colors.white,
          title: const Text('Chat',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'AI Buddy'),
              Tab(text: 'Caregiver'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AIBuddyChatScreen(
              aiService: ref.read(aiServiceProvider),
              sttService: ref.read(sttServiceProvider),
              ttsService: ref.read(ttsServiceProvider),
            ),
            const _CaregiverTab(),
          ],
        ),
      ),
    );
  }
}

class _CaregiverTab extends ConsumerWidget {
  const _CaregiverTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCaregiversProvider);
    final list = async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: MedBuddyColors.primary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load caregivers',
                style: TextStyle(color: MedBuddyColors.emergency)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(myCaregiversProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (caregivers) => caregivers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No caregivers linked yet.\nInvite one from your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MedBuddyColors.slate500),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: caregivers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final cg = caregivers[i];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: MedBuddyColors.slate300),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: MedBuddyColors.primarySoft,
                    child: Text(cg.initials,
                        style: const TextStyle(
                            color: MedBuddyColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(cg.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MedBuddyColors.slate900)),
                  subtitle: const Text('Tap to chat',
                      style: TextStyle(color: MedBuddyColors.slate500)),
                  trailing: const Icon(Icons.chat_bubble_outline,
                      color: MedBuddyColors.primary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        linkId: cg.id,
                        title: cg.name,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
    return Stack(children: [list, const SOSButton()]);
  }
}
