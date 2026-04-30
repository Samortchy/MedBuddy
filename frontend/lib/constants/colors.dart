import 'package:flutter/material.dart';

/// MedBuddy Color System
/// Single source of truth — never hardcode hex values in screens.
/// All colors match the Color Palette PDF v1.0.
class MedBuddyColors {
  MedBuddyColors._();

  // ─── Primary Teal ────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF0F766E); // Headers, active nav
  static const Color primary = Color(0xFF0D9488); // Buttons, links
  static const Color primaryMid = Color(0xFF14B8A6); // Hover, icons
  static const Color primaryLight = Color(0xFF99F6E4); // Chips, tags
  static const Color primarySoft = Color(0xFFF0FDFA); // Card backgrounds

  // ─── Emergency Red ───────────────────────────────────────────────
  static const Color emergency = Color(0xFFDC2626); // SOS screens, Factor 2
  static const Color emergencyMid = Color(0xFFEF4444); // Alert badges
  static const Color emergencyLight =
      Color(0xFFFEE2E2); // Alert card backgrounds

  // ─── Warning Amber ───────────────────────────────────────────────
  static const Color warning = Color(0xFFD97706); // Overdue badges
  static const Color warningMid = Color(0xFFF59E0B); // Icons, indicators
  static const Color warningLight = Color(0xFFFEF3C7); // Card backgrounds

  // ─── Success Green ───────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A); // Confirmed actions
  static const Color successMid = Color(0xFF22C55E); // Icons, checkmarks
  static const Color successLight = Color(0xFFDCFCE7); // Card backgrounds

  // ─── Neutrals ────────────────────────────────────────────────────
  static const Color slate900 = Color(0xFF0F172A); // Primary text
  static const Color slate700 = Color(0xFF334155); // Body text
  static const Color slate500 = Color(0xFF64748B); // Secondary text
  static const Color slate300 = Color(0xFFCBD5E1); // Dividers
  static const Color slate100 = Color(0xFFF1F5F9); // Input fields
  static const Color warmWhite = Color(0xFFFAFAF9); // App background
  static const Color pureWhite = Color(0xFFFFFFFF); // Cards, nav bar
}

/// Alias used by patient screens. Maps semantic names to MedBuddyColors.
class AppColors {
  AppColors._();

  static const Color background = MedBuddyColors.warmWhite;
  static const Color primaryDark = MedBuddyColors.primaryDark;
  static const Color primary = MedBuddyColors.primary;
  static const Color primarySoft = MedBuddyColors.primarySoft;
  static const Color inputBg = MedBuddyColors.slate100;
  static const Color textPrimary = MedBuddyColors.slate900;
  static const Color textHint = MedBuddyColors.slate500;
  static const Color warning = MedBuddyColors.warning;
  static const Color success = MedBuddyColors.success;
  static const Color emergency = MedBuddyColors.emergency;
  static const Color emergencyMid = MedBuddyColors.emergencyMid;
}

/// Legacy alias used by onboarding and caregiver screens.
/// Identical values to MedBuddyColors — use MedBuddyColors for new screens.
class MedColors {
  static const primary = MedBuddyColors.primary;
  static const primaryDark = MedBuddyColors.primaryDark;
  static const primaryLight = MedBuddyColors.primaryLight;
  static const primarySoft = MedBuddyColors.primarySoft;
  static const success = MedBuddyColors.success;
  static const successLight = MedBuddyColors.successLight;
  static const warning = MedBuddyColors.warning;
  static const warningMid = MedBuddyColors.warningMid;
  static const warningLight = MedBuddyColors.warningLight;
  static const emergency = MedBuddyColors.emergency;
  static const emergencyMid = MedBuddyColors.emergencyMid;
  static const emergencyLight = MedBuddyColors.emergencyLight;
  static const slate100 = MedBuddyColors.slate100;
  static const slate300 = MedBuddyColors.slate300;
  static const slate500 = MedBuddyColors.slate500;
  static const slate700 = MedBuddyColors.slate700;
  static const slate900 = MedBuddyColors.slate900;
  static const warmWhite = MedBuddyColors.warmWhite;
}
