import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/verify_otp_screen.dart';
import '../ui/auth/forgot_password_screen.dart';
import '../ui/root_layout.dart';
import '../ui/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// App Router: Navigation configuration with authentication guards
class AppRouter {
  static GoRouter createRouter(UserProvider userProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: userProvider,
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
          path: '/verify_otp',
          builder: (context, state) {
            final email = state.extra as String?;
            if (email == null) {
              return const LoginScreen(); // Fallback if no email
            }
            return VerifyOtpScreen(email: email);
          },
        ),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const RootLayout(),
        ),
      ],
      redirect: (context, state) {
        final currentPath = state.uri.toString();
        debugPrint('[AppRouter] Redirect check: Path=$currentPath, Init=${userProvider.initComplete}, Auth=${userProvider.currentUser != null}');

        // 1. Still initializing - show splash screen
        if (!userProvider.initComplete) {
          if (currentPath != '/splash') {
            return '/splash';
          }
          return null; // Already at splash
        }

        // 2. After initialization is complete, route based on auth state
        final isAuthenticated = userProvider.currentUser != null;

        // Define auth screens (unauthenticated-only routes)
        final authPaths = {
          '/login',
          '/verify_otp',
          '/auth/forgot-password'
        };

        final isAuthPath = authPaths.contains(currentPath) || 
                          currentPath.startsWith('/verify_otp') ||
                          currentPath.startsWith('/auth/');

        if (isAuthenticated) {
          // If user is logged in but tries to access login/auth screens, redirect to home
          if (isAuthPath) {
            return '/';
          }
        } else {
          // If user is NOT logged in and tries to access protected screens, redirect to login
          if (!isAuthPath && currentPath != '/splash') {
            return '/login';
          }
        }

        return null;
      },
    );
  }
}
