import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/set_password_screen.dart';
import '../ui/auth/verify_otp_screen.dart';
import '../ui/auth/forgot_password_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// App Router: Navigation configuration with authentication guards
///
/// SECURE AUTH FLOW:
/// 1. User starts at /set_password (email verification)
/// 2. Requests OTP → OTP sent to email
/// 3. Redirects to /verify_otp (with email as extra parameter)
/// 4. User enters OTP and creates password
/// 5. Account created and auto-logged in
/// 6. Redirects to /dashboard
///
/// Routes:
/// - / (root): Dashboard (authenticated only)
/// - /login: Sign in screen (existing users)
/// - /set_password: Email verification & OTP request (new users)
/// - /verify_otp: OTP entry & password creation (new users after OTP sent)
/// - /forgot_password: Password reset request
/// - /splash: Loading screen during auth check
///
/// Redirect Logic:
/// - If not authenticated → /login
/// - If authenticated → /
/// - If initializing → /splash
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
      path: '/set_password',
      builder: (context, state) => const SetPasswordScreen(),
    ),
    GoRoute(
      path: '/verify_otp',
      builder: (context, state) {
        final email = state.extra as String?;
        if (email == null) {
          return const SetPasswordScreen(); // Fallback if no email
        }
        return VerifyOtpScreen(email: email);
      },
    ),
    GoRoute(
      path: '/forgot_password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  redirect: (context, state) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentPath = state.uri.toString();

    debugPrint(
        '[Router] Redirect check - Current path: $currentPath, InitComplete: ${userProvider.initComplete}, HasUser: ${userProvider.currentUser != null}');

    // 1. Still initializing - show splash screen
    if (!userProvider.initComplete) {
      debugPrint('[Router] Still initializing, showing splash');
      // Only redirect to splash if not already there
      if (currentPath != '/splash') {
        return '/splash';
      }
      return null;
    }

    // 2. After initialization is complete, route based on auth state
    final isAuthenticated = userProvider.currentUser != null;

    // Define auth screens (unauthenticated-only routes)
    final authPaths = {
      '/login',
      '/set_password',
      '/verify_otp',
      '/forgot_password'
    };

    debugPrint(
        '[Router] Initialized. Authenticated: $isAuthenticated, Current path: $currentPath');

    // If user is authenticated
    if (isAuthenticated) {
      // On splash or auth screen while authenticated - redirect to dashboard
      if (currentPath == '/splash' || authPaths.contains(currentPath)) {
        debugPrint(
            '[Router] User authenticated but on splash/auth screen, redirecting to /');
        return '/';
      }

      // On dashboard or protected route - allow it
      debugPrint('[Router] User authenticated, on correct path: $currentPath');
      return null;
    } else {
      // User is not authenticated
      // On splash, dashboard or other protected route - redirect to login
      if (currentPath == '/splash' ||
          (currentPath == '/' ||
              (currentPath != '/' && !authPaths.contains(currentPath)))) {
        debugPrint('[Router] User not authenticated, redirecting to /login');
        return '/login';
      }

      // On auth screen - allow it
      debugPrint(
          '[Router] User not authenticated, on auth screen $currentPath, allowing');
      return null;
    }
  },
);
