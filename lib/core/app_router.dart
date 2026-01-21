import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/email_sent_screen.dart';
import '../ui/student/dashboard_screen.dart';
import '../ui/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
     GoRoute(
      path: '/email_sent',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return EmailSentScreen(email: email);
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
  redirect: (context, state) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // 1. Loading - show splash screen
    if (userProvider.isLoading) {
      if (state.uri.toString() != '/splash') {
        return '/splash';
      }
      return null;
    }

    // 2. Auth State
    final loggedIn = userProvider.currentUser != null;
    final loggingIn = state.uri.toString() == '/login';
    final emailSent = state.uri.toString() == '/email_sent';

    if (!loggedIn && !loggingIn && !emailSent) return '/login';
    if (loggedIn && (loggingIn || emailSent)) return '/';

    return null;
  },
);
