import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../core/utils/responsive_helper.dart';
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if simulating - use active role permissions, not actual role
    final showReports = (userProvider.isCoordinator || userProvider.isPlacementRep) && 
                        !userProvider.isSimulating;

    // Dynamic Screen List based on ACTIVE Role (respects simulation)
    final screens = [
      const HomeScreen(),
      const TasksScreen(),
      const ComprehensiveAttendanceScreen(),
      if (showReports) const ModernReportsScreen(),
      const ProfileScreen(),
    ];

    // Dynamic Navigation Items based on ACTIVE Role (respects simulation)
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
      if (showReports)
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
    var currentIndex = navProvider.currentIndex;
    if (currentIndex >= screens.length) {
      currentIndex = 0;
      // Schedule a fix for the provider as well
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.setIndex(0);
      });
    }

    // Use NavigationRail for desktop/tablet web, BottomNavigationBar for mobile
    final useRail = ResponsiveHelper.isDesktop(context) || 
                     (ResponsiveHelper.isWeb && ResponsiveHelper.isTablet(context));

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (idx) => navProvider.setIndex(idx),
              labelType: NavigationRailLabelType.all,
              destinations: navItems.map((item) => NavigationRailDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: Text(item.label),
              )).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[currentIndex]),
          ],
        ),
      );
    }

    // Mobile layout with bottom navigation
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => navProvider.setIndex(idx),
        destinations: navItems,
      ),
    );
  }
}
