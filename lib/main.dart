/// PSGMX - Placement Excellence Program
/// 
/// A comprehensive placement preparation platform for PSG Technology - MCA
/// 
/// Author: Tino Britty J
/// GitHub: https://github.com/brittytino
/// Portfolio: https://tinobritty.me
/// 
/// Copyright (c) 2026 Tino Britty J
/// Licensed under the MIT License

library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/supabase_config.dart';
import 'core/app_router.dart';
import 'providers/user_provider.dart';
import 'providers/leetcode_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/supabase_db_service.dart';
import 'services/quote_service.dart';
import 'services/notification_service.dart';
import 'services/birthday_notification_service.dart';
import 'services/leetcode_auto_refresh_service.dart';
import 'services/update_service.dart';

import 'ui/widgets/error_boundary.dart';
import 'ui/widgets/modern_offline_banner.dart';
import 'ui/widgets/notification_listener_wrapper.dart';
import 'ui/update/update_gate.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Global Error Handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[GLOBAL ERROR] ${details.exception}');
    return GlobalErrorWidget(errorDetails: details);
  };

  try {
    debugPrint('[APP] Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('[APP] Supabase initialized successfully');

    debugPrint('[APP] Initializing NotificationService...');
    await NotificationService().init();
    debugPrint('[APP] NotificationService initialized successfully');

    debugPrint('[APP] Initializing BirthdayNotificationService...');
    await BirthdayNotificationService().init();
    debugPrint('[APP] BirthdayNotificationService initialized successfully');

    debugPrint('[APP] Initializing UpdateService...');
    await UpdateService().initialize();
    debugPrint('[APP] UpdateService initialized successfully');
  } catch (e) {
    debugPrint('[APP ERROR] Initialization failed: $e');
    rethrow;
  }

  runApp(const PsgMxApp());
}

class PsgMxApp extends StatelessWidget {
  const PsgMxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services
    final supabaseService = SupabaseService();
    final supabaseDbService = SupabaseDbService();
    final authService = AuthService(supabaseService);
    final quoteService = QuoteService();

    return MultiProvider(
      providers: [
        Provider<SupabaseService>.value(value: supabaseService),
        Provider<SupabaseDbService>.value(value: supabaseDbService),
        Provider<AuthService>.value(value: authService),
        Provider<QuoteService>.value(value: quoteService),
        ChangeNotifierProvider<NotificationService>.value(value: NotificationService()),
        ChangeNotifierProvider<UpdateService>.value(value: UpdateService()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => UserProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => LeetCodeProvider(supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementProvider(supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const PsgMxAppInner(),
    );
  }
}

class PsgMxAppInner extends StatefulWidget {
  const PsgMxAppInner({super.key});

  @override
  State<PsgMxAppInner> createState() => _PsgMxAppInnerState();
}

class _PsgMxAppInnerState extends State<PsgMxAppInner> {
  late final GoRouter _router;
  LeetCodeAutoRefreshService? _autoRefreshService;

  @override
  void initState() {
    super.initState();
    // Access provider via context inside initState (listen: false)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = AppRouter.createRouter(userProvider);

    // Initialize LeetCode auto-refresh service for daily updates
    _initAutoRefresh();
  }

  void _initAutoRefresh() {
    // Schedule after build to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leetCodeProvider =
          Provider.of<LeetCodeProvider>(context, listen: false);
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      _autoRefreshService =
          LeetCodeAutoRefreshService(leetCodeProvider, supabaseService);
      _autoRefreshService!.start();
      debugPrint('[APP] LeetCode auto-refresh service started');
    });
  }

  @override
  void dispose() {
    _autoRefreshService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      title: 'PSGMX - Placement Excellence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        // Wrap with UpdateGate to enforce version checks
        // Then NotificationListenerWrapper for in-app notifications
        // Then ModernOfflineBanner for connectivity status
        return UpdateGate(
          child: NotificationListenerWrapper(
            child: ModernOfflineBanner(child: child ?? const SizedBox())
          ),
        );
      },
    );
  }
}
