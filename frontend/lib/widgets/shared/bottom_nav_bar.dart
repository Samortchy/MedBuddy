import 'package:flutter/material.dart';
import '../../constants/colors.dart';

enum PatientNavTab { home, chat, meds, history, profile }

class PatientBottomNavBar extends StatelessWidget {
  final PatientNavTab activeTab;

  /// Called when user taps a tab.
  /// Wire to your navigation solution (GoRouter, Navigator, etc).
  final ValueChanged<PatientNavTab> onTabSelected;

  const PatientBottomNavBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
          top: BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isActive: activeTab == PatientNavTab.home,
                onTap: () => onTabSelected(PatientNavTab.home),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                isActive: activeTab == PatientNavTab.chat,
                onTap: () => onTabSelected(PatientNavTab.chat),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Meds',
                isActive: activeTab == PatientNavTab.meds,
                onTap: () => onTabSelected(PatientNavTab.meds),
              ),
              _NavItem(
                icon: Icons.show_chart,
                label: 'History',
                isActive: activeTab == PatientNavTab.history,
                onTap: () => onTabSelected(PatientNavTab.history),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isActive: activeTab == PatientNavTab.profile,
                onTap: () => onTabSelected(PatientNavTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? MedBuddyColors.primaryDark : MedBuddyColors.slate300;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
