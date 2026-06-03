import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ── Constants ─────────────────────────────────────────────────────────────────
import 'constants/colors.dart';
import 'services/fcm_service.dart';
import 'screens/caregiver/caregiver_emergency_call.dart';

// ── Onboarding ────────────────────────────────────────────────────────────────
import 'screens/onboarding/s01_welcome.dart';
import 'screens/onboarding/s02_role_selection.dart';
import 'screens/onboarding/s03_login.dart';
import 'screens/onboarding/s04_basic_info.dart';
import 'screens/onboarding/s05_conditions.dart';
import 'screens/onboarding/s06_mobility.dart';
import 'screens/onboarding/s07_medications_setup.dart';
import 'screens/onboarding/s08_emergency_contacts.dart';
import 'screens/onboarding/s09_checkin_prefs.dart';
import 'screens/onboarding/s10_review.dart';

// ── Auth guard ────────────────────────────────────────────────────────────────
import 'providers/ai_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/fall_provider.dart';
import 'providers/history_providers.dart';
import 'providers/medication_provider.dart';
import 'providers/patient_provider.dart';
import 'services/api_service.dart';
import 'services/service_interfaces.dart';

// ── Patient: Home & Meds ──────────────────────────────────────────────────────
import 'screens/patient/home/home.dart';
import 'screens/patient/medications/med_schedule.dart';
import 'screens/patient/medications/add_edit.dart';
import 'screens/patient/medications/appointments.dart';
import 'screens/patient/medications/reminders.dart';

// ── Patient: Emergency ────────────────────────────────────────────────────────
import 'screens/patient/emergency/sos_confirmation_screen.dart';
import 'screens/patient/emergency/fall_detected_screen.dart';
import 'screens/patient/emergency/fall_verification_screen.dart';
import 'screens/patient/emergency/fall_agora_screen.dart';

// ── Patient: Check-in & AI ────────────────────────────────────────────────────
import 'screens/patient/checkin/s17b_wellness_checkin.dart';

// ── Patient: History ─────────────────────────────────────────────────────────
import 'screens/patient/history/s22_wellness_history.dart';
import 'screens/patient/history/s23_medication_adherence.dart';
import 'screens/patient/history/s24_emergency_log.dart';
import 'screens/patient/history/s28_symptom_log.dart';
import 'screens/patient/history/s29_visit_summary.dart';

// ── Patient: Profile & Settings ───────────────────────────────────────────────
import 'screens/patient/profile/s25_my_profile.dart';
import 'screens/patient/profile/s26_patient_chat.dart';
import 'screens/patient/profile/s27_app_settings.dart';
import 'screens/patient/profile/edit/edit_basic_info.dart';
import 'screens/patient/profile/edit/edit_conditions.dart';
import 'screens/patient/profile/edit/edit_medications.dart';
import 'screens/patient/profile/edit/edit_contacts.dart';
import 'screens/patient/profile/edit/edit_checkin_prefs.dart';

// ── Caregiver ─────────────────────────────────────────────────────────────────
import 'screens/caregiver/c01_patient_list.dart';
import 'screens/caregiver/c03_alerts_feed.dart';
import 'screens/caregiver/caregiver_messages.dart';
import 'screens/caregiver/c11_settings.dart';
import 'screens/patient/patient_chat_hub.dart';

/// Global navigator key so push-notification handlers can navigate.
final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Required to be registered; nothing to do in the background for now.
}

/// Opens the caregiver emergency call screen when an emergency push arrives.
void _handleEmergencyMessage(RemoteMessage message) {
  final data = message.data;
  final channel = data['agora_channel'];
  if (data['type'] == 'emergency' && channel != null && channel.isNotEmpty) {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => CaregiverEmergencyCallScreen(channelName: channel),
    ));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tcyrehuatbtlfvnttkgc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjeXJlaHVhdGJ0bGZ2bnR0a2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODI3NzUsImV4cCI6MjA5MzE1ODc3NX0.MJsuJRl0GDqKo1a-eVBYNEjrD98DHG2g0F6Pcz5RkC8',
  );

  // Firebase / FCM — don't let init failure crash the app.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleEmergencyMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleEmergencyMessage);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleEmergencyMessage(initial);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(const ProviderScope(child: MedBuddyApp()));
}

class MedBuddyApp extends StatelessWidget {
  const MedBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedBuddy',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: MedBuddyColors.primary,
        scaffoldBackgroundColor: MedBuddyColors.warmWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MedBuddyColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(),
      routes: {
        // ── Onboarding ────────────────────────────────────────────────
        '/welcome': (_) => const S01Welcome(),
        '/role-select': (_) => const S02RoleSelection(),
        '/login': (_) => const S03Login(),
        '/profile/basic': (_) => const S04BasicInfo(),
        '/profile/conditions': (_) => const S05Conditions(),
        '/profile/mobility': (_) => const S06Mobility(),
        '/profile/meds': (_) => const S07MedicationsSetup(),
        '/profile/contacts': (_) => const S08EmergencyContacts(),
        '/profile/checkin': (_) => const S09CheckinPrefs(),
        '/profile/review': (_) => const S10Review(),

        // ── Patient Emergency ──────────────────────────────────────────
        '/fall-detected': (_) => const FallDetectedScreen(),
        '/fall-verification': (_) => const FallVerificationScreen(),
        '/fall-agora': (_) => const FallAgoraScreen(),
        '/fall-resolved': (_) => const _PlaceholderScreen(
            label: 'Fall Resolved ✅', color: Color(0xFF16A34A)),
        '/sos-confirmation': (_) => const _SosConfirmationRoute(),

        // ── Caregiver home ─────────────────────────────────────────────
        '/caregiver-home': (_) => const CaregiverShell(),

        // ── Patient Core ───────────────────────────────────────────────
        '/home': (_) => const Home(),
        '/medication-schedule': (_) => const MedicationSchedule(),
        '/add-medication': (_) => const AddEditMedication(),
        '/appointments': (_) => const AppointmentsScreen(),
        '/reminder-active': (_) => const ReminderActive(),

        // ── Patient Check-in & AI ──────────────────────────────────────
        '/ai-chat': (_) => const PatientChatHub(),
        '/checkin': (_) => const _CheckInRoute(),

        // ── Patient History ────────────────────────────────────────────
        '/wellness-history': (_) => const _WellnessHistoryRoute(),
        '/med-adherence': (_) => const _MedicationAdherenceRoute(),
        '/emergency-log': (_) => const _EmergencyLogRoute(),
        '/symptom-log': (_) => const _SymptomLogRoute(),
        '/visit-summary': (_) => const VisitSummaryScreen(),

        // ── Patient Profile ────────────────────────────────────────────
        '/my-profile': (_) => const _MyProfileRoute(),
        '/chat': (_) => const PatientChatScreen(),
        '/settings': (_) => const AppSettingsScreen(),
      },
    );
  }
}

// ── History route wrappers ────────────────────────────────────────────────────

class _WellnessHistoryRoute extends ConsumerWidget {
  const _WellnessHistoryRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessCheckInsProvider);
    return WellnessHistoryScreen(
      checkIns: state.valueOrNull ?? [],
    );
  }
}

class _EmergencyLogRoute extends ConsumerWidget {
  const _EmergencyLogRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyEventsProvider);
    return EmergencyEventLogScreen(
      events: state.valueOrNull ?? [],
    );
  }
}

class _SymptomLogRoute extends ConsumerWidget {
  const _SymptomLogRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomLogProvider);
    return SymptomLogScreen(
      entries: state.valueOrNull ?? [],
      onAddEntry: (description) =>
          ref.read(symptomLogProvider.notifier).add(description),
    );
  }
}

class _MyProfileRoute extends ConsumerWidget {
  const _MyProfileRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState    = ref.watch(patientProfileProvider);
    final conditionsState = ref.watch(healthConditionsProvider);
    final contactsState   = ref.watch(emergencyContactsProvider);
    final medState        = ref.watch(medicationProvider);
    final caregiversState = ref.watch(myCaregiversProvider);

    final data = profileState.valueOrNull;

    // Don't show fake placeholder data — show a loading/error state until the
    // real profile is available.
    if (data == null) {
      return Scaffold(
        backgroundColor: MedBuddyColors.warmWhite,
        body: Center(
          child: profileState.isLoading
              ? const CircularProgressIndicator(color: MedBuddyColors.primary)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: MedBuddyColors.slate500, size: 40),
                      const SizedBox(height: 12),
                      const Text('Could not load your profile.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(patientProfileProvider.notifier).fetch(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final conditions = conditionsState.valueOrNull ?? [];
    final contacts   = contactsState.valueOrNull ?? [];
    final primaryContact = contacts.isNotEmpty ? contacts.first : null;

    // Map medication provider items → PatientProfile.medications (dedup by name)
    final medSeen = <String>{};
    final medications = medState.medications
        .where((m) => medSeen.add(m.name.toLowerCase()))
        .map((m) => MedicationEntry(
              id: m.id,
              name: m.name,
              dose: m.dosage,
              frequency: m.frequency,
              status: MedicationStatus.pending,
            ))
        .toList();

    // Calculate completeness based on what's filled
    int completeness = 0;
    if (data.fullName.isNotEmpty) completeness += 20;
    if (data.dateOfBirth != null) completeness += 15;
    if (conditions.isNotEmpty) completeness += 20;
    if (medications.isNotEmpty) completeness += 15;
    if (contacts.isNotEmpty) completeness += 15;
    if (data.checkinTime != null) completeness += 15;

    final profile = PatientProfile(
      id: data.id,
      fullName: data.fullName,
      age: _ageFromDob(data.dateOfBirth),
      gender: data.gender ?? '',
      language: _languageDisplay(data.preferredLanguage),
      conditions: conditions,
      medications: medications,
      primaryContactName: primaryContact?.name ?? '',
      primaryContactPhone: primaryContact?.phone ?? '',
      primaryContactRelationship: primaryContact?.relationship ?? '',
      checkInHour: _hourFromTime(data.checkinTime),
      checkInVoiceMode: false,
      painBaseline: data.painBaseline ?? 0,
      caregivers: caregiversState.valueOrNull ?? const [],
      profileCompleteness: completeness,
    );

    return MyProfileScreen(
      profile: profile,
      onEditSection: (section) => _handleEditSection(context, ref, section),
      onGenerateInvite: () async {
        final dio = ref.read(apiServiceProvider);
        final response = await dio.post('/caregiver/invite');
        ref.invalidate(myCaregiversProvider);
        return response.data['code'] as String;
      },
      onLogout: () async {
        await ref.read(authProvider.notifier).signOut();
        if (context.mounted) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      onRevokeCaregiver: (linkId) async {
        final dio = ref.read(apiServiceProvider);
        try {
          await dio.delete('/caregiver/links/$linkId');
        } finally {
          ref.invalidate(myCaregiversProvider);
        }
      },
    );
  }

  /// Routes a profile section edit to its dedicated editor screen.
  /// 'all' opens a small edit hub (bottom sheet) listing every section.
  Future<void> _handleEditSection(
      BuildContext context, WidgetRef ref, String section) async {
    if (section == 'all') {
      final chosen = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: MedBuddyColors.pureWhite,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _EditHubTile(section: 'basic_info', icon: Icons.person_outline, label: 'Basic Info'),
              _EditHubTile(section: 'conditions', icon: Icons.monitor_heart_outlined, label: 'Health Conditions'),
              _EditHubTile(section: 'medications', icon: Icons.medication_outlined, label: 'Medications'),
              _EditHubTile(section: 'emergency_contacts', icon: Icons.phone_outlined, label: 'Emergency Contacts'),
              _EditHubTile(section: 'checkin_prefs', icon: Icons.schedule_outlined, label: 'Check-in Preferences'),
            ],
          ),
        ),
      );
      if (chosen != null && context.mounted) {
        await _handleEditSection(context, ref, chosen);
      }
      return;
    }

    Widget? screen;
    switch (section) {
      case 'basic_info':
        screen = const EditBasicInfoScreen();
      case 'conditions':
        screen = const EditConditionsScreen();
      case 'medications':
        screen = const EditMedicationsScreen();
      case 'emergency_contacts':
        screen = const EditContactsScreen();
      case 'checkin_prefs':
        screen = const EditCheckinPrefsScreen();
    }
    final target = screen;
    if (target == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => target),
    );

    // Refresh everything the profile reads so it reflects any edits.
    ref.read(patientProfileProvider.notifier).fetch();
    ref.invalidate(healthConditionsProvider);
    ref.invalidate(emergencyContactsProvider);
    ref.read(medicationProvider.notifier).refresh();
  }

  int _hourFromTime(String? time) {
    if (time == null || time.length < 2) return 9;
    return int.tryParse(time.substring(0, 2)) ?? 9;
  }

  int _ageFromDob(String? dob) {
    if (dob == null) return 0;
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) age--;
      return age;
    } catch (_) {
      return 0;
    }
  }

  String _languageDisplay(String? code) {
    switch (code) {
      case 'ar': return 'Arabic';
      case 'en': return 'English';
      case 'fr': return 'French';
      case null: return 'English';
      default:   return code!;
    }
  }
}

class _MedicationAdherenceRoute extends ConsumerWidget {
  const _MedicationAdherenceRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medState = ref.watch(medicationProvider);

    final medications = medState.medications
        .map((m) => MedicationEntry(
              id: m.id,
              name: m.name,
              dose: m.dosage,
              frequency: m.frequency,
              status: MedicationStatus.pending,
            ))
        .toList();

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    MedicationStatus? todayOverall;
    if (medState.todayDoses.isNotEmpty) {
      final taken = medState.todayDoses.where((d) => d.status == 'taken').length;
      final missed = medState.todayDoses.where((d) => d.status == 'missed').length;
      final total = medState.todayDoses.length;
      if (taken == total) {
        todayOverall = MedicationStatus.taken;
      } else if (missed > 0) {
        todayOverall = MedicationStatus.missed;
      } else {
        todayOverall = MedicationStatus.pending;
      }
    }
    final calendarData = todayOverall != null
        ? {todayKey: todayOverall}
        : <DateTime, MedicationStatus>{};

    final total = medState.totalCount;
    final taken = medState.takenCount;
    final missed =
        medState.todayDoses.where((d) => d.status == 'missed').length;
    final adherence = total > 0 ? (taken * 100 ~/ total) : 0;

    return MedicationAdherenceScreen(
      medications: medications,
      calendarData: calendarData,
      adherencePercent: adherence,
      takenOnTime: taken,
      takenLate: 0,
      missed: missed,
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const S03Login(startInLogin: true),
      data: (user) {
        if (user == null) return const S03Login(startInLogin: true);
        // Register this device for push notifications (once per session).
        if (!_fcmRegistered) {
          _fcmRegistered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(fcmServiceProvider).registerToken();
          });
        }
        if (user.role == 'caregiver') return const CaregiverShell();
        return const Home();
      },
    );
  }
}

bool _fcmRegistered = false;

// ── App Launcher (role selection entry) ───────────────────────────────────────
class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(children: [
              const SizedBox(height: 20),
              // App logo / title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: MedBuddyColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 48),
                    SizedBox(height: 12),
                    Text('MedBuddy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('AI-Powered Medical Companion',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Onboarding ──────────────────────────────────────────────
              _sectionHeader('ONBOARDING (S-01 → S-10)'),
              _routeButton(context, 'S-01 Welcome & Language', '/welcome'),
              _routeButton(context, 'S-02 Role Selection', '/role-select'),
              _routeButton(context, 'S-03 Login / Register', '/login'),
              _routeButton(context, 'S-04 Basic Info', '/profile/basic'),
              _routeButton(
                  context, 'S-05 Health Conditions', '/profile/conditions'),
              _routeButton(
                  context, 'S-06 Mobility & Cognitive', '/profile/mobility'),
              _routeButton(context, 'S-07 Medications Setup', '/profile/meds'),
              _routeButton(
                  context, 'S-08 Emergency Contacts', '/profile/contacts'),
              _routeButton(
                  context, 'S-09 Check-in Preferences', '/profile/checkin'),
              _routeButton(context, 'S-10 Review & Confirm', '/profile/review'),
              const SizedBox(height: 24),

              // ── Patient Core ─────────────────────────────────────────────
              _sectionHeader('PATIENT CORE'),
              _routeButton(context, 'S-11 Home Dashboard', '/home'),
              _routeButton(
                  context, 'S-12 SOS Confirmation', '/sos-confirmation'),
              _routeButton(
                  context, 'S-13 Medication Schedule', '/medication-schedule'),
              _routeButton(
                  context, 'S-14 Add / Edit Medication', '/add-medication'),
              _routeButton(
                  context, 'S-15 Appointment Reminders', '/appointments'),
              _routeButton(context, 'S-16 Reminder Active', '/reminder-active'),
              const SizedBox(height: 24),

              // ── Patient AI & Check-in ─────────────────────────────────────
              _sectionHeader('AI BUDDY & CHECK-INS'),
              _routeButton(context, 'S-17 AI Buddy Chat', '/ai-chat'),
              _routeButton(context, 'S-17b Wellness Check-in', '/checkin'),
              const SizedBox(height: 24),

              // ── Patient Emergency ──────────────────────────────────────────
              _sectionHeader('EMERGENCY & FALL DETECTION'),
              _routeButton(context, 'S-19 Fall Detected', '/fall-detected',
                  color: const Color(0xFFD97706)),
              _routeButton(
                  context, 'S-20 Fall Verification', '/fall-verification',
                  color: const Color(0xFFDC2626)),
              _routeButton(
                  context, 'S-21 Agora Channel (Factor 2)', '/fall-agora',
                  color: const Color(0xFFDC2626)),
              const SizedBox(height: 24),

              // ── Patient History ────────────────────────────────────────────
              _sectionHeader('HISTORY & LOGS'),
              _routeButton(
                  context, 'S-22 Wellness History', '/wellness-history'),
              _routeButton(
                  context, 'S-23 Medication Adherence', '/med-adherence'),
              _routeButton(
                  context, 'S-24 Emergency Event Log', '/emergency-log'),
              _routeButton(context, 'S-28 Symptom Log', '/symptom-log'),
              _routeButton(context, 'S-29 Visit Summary', '/visit-summary'),
              const SizedBox(height: 24),

              // ── Patient Profile ────────────────────────────────────────────
              _sectionHeader('PROFILE & SETTINGS'),
              _routeButton(context, 'S-25 My Profile', '/my-profile'),
              _routeButton(context, 'S-26 Patient Chat', '/chat'),
              _routeButton(context, 'S-27 App Settings', '/settings'),
              const SizedBox(height: 24),

              // ── Caregiver shell ──────────────────────────────────────────
              _sectionHeader('CAREGIVER (C-01 → C-11)'),
              _routeButton(context, 'Open Caregiver Shell', null, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CaregiverShell(),
                ));
              }, color: MedBuddyColors.primaryDark),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MedBuddyColors.slate500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _routeButton(BuildContext context, String label, String? route,
      {Color? color, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? MedBuddyColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: onTap ??
              (route != null
                  ? () => Navigator.of(context).pushNamed(route)
                  : null),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── Caregiver Shell ───────────────────────────────────────────────────────────
class CaregiverShell extends StatefulWidget {
  const CaregiverShell({super.key});

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const C01PatientList(),
    const C03AlertsFeed(),
    const CaregiverMessagesScreen(),
    const C11Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: MedBuddyColors.primary,
        unselectedItemColor: MedBuddyColors.slate500,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ── SOS confirmation route (triggers a manual emergency) ─────────────────────

class _SosConfirmationRoute extends ConsumerWidget {
  const _SosConfirmationRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SOSConfirmationScreen(
      onSOSConfirmed: () async {
        await ref
            .read(fallProvider.notifier)
            .triggerEmergency(eventType: 'manual_sos');
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/fall-agora');
        }
      },
      onCancelled: () => Navigator.of(context).pop(),
    );
  }
}

// ── AI route wrappers (inject providers) ─────────────────────────────────────

class _CheckInRoute extends ConsumerWidget {
  const _CheckInRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WellnessCheckInScreen(
      aiService: ref.read(aiServiceProvider),
      sttService: ref.read(sttServiceProvider),
      ttsService: ref.read(ttsServiceProvider),
    );
  }
}

// ── Edit hub tile (used by the "edit all" bottom sheet) ──────────────────────
class _EditHubTile extends StatelessWidget {
  final String section;
  final IconData icon;
  final String label;

  const _EditHubTile({
    required this.section,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: MedBuddyColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: MedBuddyColors.slate500),
      onTap: () => Navigator.pop(context, section),
    );
  }
}

// ── Generic Placeholder ───────────────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final Color color;

  const _PlaceholderScreen({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
