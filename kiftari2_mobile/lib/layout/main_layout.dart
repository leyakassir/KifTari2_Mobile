import 'package:flutter/material.dart';

import '../../features/home/home_screen.dart';
import '../../features/reports/my_reports/my_reports_screen.dart';
import '../../features/reports/create/create_report_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/field_operator/home/field_operator_home_screen.dart';
import '../../features/field_operator/overview/field_operator_overview_screen.dart';
import '../../features/field_operator/resolved/field_operator_resolved_screen.dart';
import '../../core/services/token_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await TokenService.getRole();
    if (!mounted) return;
    setState(() {
      _role = role ?? "citizen";
      _currentIndex = 0;
    });
  }

  // 🔹 Helper for cuter / softer nav icons (LOGIC SAFE)
  BottomNavigationBarItem _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final bool isActive = _currentIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Container(
        padding: EdgeInsets.all(isCenter ? 10 : 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: isCenter ? 28 : 24,
        ),
      ),
      activeIcon: Container(
        padding: EdgeInsets.all(isCenter ? 12 : 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          activeIcon,
          size: isCenter ? 30 : 26,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  List<Widget> _screensForRole(String role) {
    if (role == "field_operator") {
      return const [
        FieldOperatorOverviewScreen(),
        FieldOperatorHomeScreen(),
        FieldOperatorResolvedScreen(),
        ProfileScreen(),
        SettingsScreen(),
      ];
    }

    return const [
      HomeScreen(),
      MyReportsScreen(),
      CreateReportScreen(),
      ProfileScreen(),
      SettingsScreen(),
    ];
  }

  List<_NavItemData> _navItemsForRole(String role) {
    if (role == "field_operator") {
      return const [
        _NavItemData(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: "Overview",
        ),
        _NavItemData(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_turned_in_rounded,
          label: "Assigned",
        ),
        _NavItemData(
          icon: Icons.check_circle_outline,
          activeIcon: Icons.check_circle,
          label: "Resolved",
        ),
        _NavItemData(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: "Profile",
        ),
        _NavItemData(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          label: "Settings",
        ),
      ];
    }

    return const [
      _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: "Home",
      ),
      _NavItemData(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: "My Reports",
      ),
      _NavItemData(
        icon: Icons.add_rounded,
        activeIcon: Icons.add_rounded,
        label: "Report",
        isCenter: true,
      ),
      _NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: "Profile",
      ),
      _NavItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: "Settings",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _screensForRole(_role!);
    final navItems = _navItemsForRole(_role!);
    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: screens[safeIndex],

      // ✅ IMPROVED NAV BAR (UI ONLY — LOGIC KEPT)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.outline,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,

          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface,

          selectedFontSize: 12,
          unselectedFontSize: 11,

          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          items: [
            for (var i = 0; i < navItems.length; i++)
              _navItem(
                icon: navItems[i].icon,
                activeIcon: navItems[i].activeIcon,
                label: navItems[i].label,
                index: i,
                isCenter: navItems[i].isCenter,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}
