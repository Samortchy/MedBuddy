import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ── Constants ─────────────────────────────────────────────────────────────────
import 'constants/colors.dart';

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
import 'screens/patient/checkin/s17_ai_buddy_chat.dart';
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

// ── Caregiver ─────────────────────────────────────────────────────────────────
import 'screens/caregiver/c01_patient_list.dart';
import 'screens/caregiver/c03_alerts_feed.dart';
import 'screens/caregiver/c08_caregiver_chat.dart';
import 'screens/caregiver/c11_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tcyrehuatbtlfvnttkgc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjeXJlaHVhdGJ0bGZ2bnR0a2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODI3NzUsImV4cCI6MjA5MzE1ODc3NX0.MJsuJRl0GDqKo1a-eVBYNEjrD98DHG2g0F6Pcz5RkC8',
  );
  runApp(const ProviderScope(child: MedBuddyApp()));
}

class MedBuddyApp extends StatelessWidget {
  const MedBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedBuddy',
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
      home: const S01Welcome(),
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
        '/sos-confirmation': (context) => SOSConfirmationScreen(
              onSOSConfirmed: () =>
                  Navigator.of(context).pushReplacementNamed('/fall-agora'),
              onCancelled: () => Navigator.of(context).pop(),
            ),

        // ── Caregiver home ─────────────────────────────────────────────
        '/caregiver-home': (_) => const CaregiverShell(),

        // ── Patient Core ───────────────────────────────────────────────
        '/home': (_) => const Home(),
        '/medication-schedule': (_) => const MedicationSchedule(),
        '/add-medication': (_) => const AddEditMedication(),
        '/appointments': (_) => const AppointmentsScreen(),
        '/reminder-active': (_) => const ReminderActive(),

        // ── Patient Check-in & AI ──────────────────────────────────────
        '/ai-chat': (_) => const AIBuddyChatScreen(),
        '/checkin': (_) => const WellnessCheckInScreen(),

        // ── Patient History ────────────────────────────────────────────
        '/wellness-history': (_) => const WellnessHistoryScreen(),
        '/med-adherence': (_) => const MedicationAdherenceScreen(),
        '/emergency-log': (_) => const EmergencyEventLogScreen(),
        '/symptom-log': (_) => const SymptomLogScreen(),
        '/visit-summary': (_) => const VisitSummaryScreen(),

        // ── Patient Profile ────────────────────────────────────────────
        '/my-profile': (_) => const MyProfileScreen(),
        '/chat': (_) => const PatientChatScreen(),
        '/settings': (_) => const AppSettingsScreen(),
      },
    );
  }
}

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
    const C08CaregiverChat(),
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
