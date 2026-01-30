import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'attendance/comprehensive_attendance_screen.dart';
import 'reports/modern_reports_screen.dart';
import 'profile/profile_screen.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Dynamic Screen List based on Role
    final screens = [
      const HomeScreen(),
      const TasksScreen(),
      const ComprehensiveAttendanceScreen(),
      if (userProvider.isCoordinator || userProvider.isPlacementRep || userProvider.hasActualAdminAccess) 
        const ModernReportsScreen(),
      const ProfileScreen(),
    ];

    // Dynamic Navigation Items
    final navItems = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined), 
        selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary), 
        label: 'Home'
      ),
      NavigationDestination(
        icon: const Icon(Icons.check_circle_outline), 
        selectedIcon: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary), 
        label: 'Tasks'
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_today_outlined), 
        selectedIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary), 
        label: 'Attendance'
      ),
      if (userProvider.isCoordinator || userProvider.isPlacementRep || userProvider.hasActualAdminAccess)
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined), 
          selectedIcon: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary), 
          label: 'Reports'
        ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline), 
        selectedIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary), 
        label: 'Profile'
      ),
    ];

    // Safety check for index
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    // Root Scaffolding (BottomNav Only)
    // Child screens provide their own Scaffold + AppBar
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: navItems,
      ),
    );
  }
}
