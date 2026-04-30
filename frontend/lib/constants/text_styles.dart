import 'package:flutter/material.dart';
import 'colors.dart';

/// MedBuddy Typography
/// Minimum 16sp for all readable text per the spec.
class MedBuddyTextStyles {
  MedBuddyTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: MedBuddyColors.slate900,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: MedBuddyColors.slate900,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: MedBuddyColors.primaryDark,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MedBuddyColors.slate700,
    height: 1.5,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MedBuddyColors.slate900,
  );
  static const TextStyle secondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MedBuddyColors.slate500,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: MedBuddyColors.slate500,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: MedBuddyColors.slate500,
  );
  static const TextStyle emergencyScreen = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: MedBuddyColors.pureWhite,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: MedBuddyColors.primaryDark,
    letterSpacing: 0.8,
  );
}
