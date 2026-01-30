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
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/supabase_db_service.dart';
import 'services/quote_service.dart';
import 'services/notification_service.dart';

import 'ui/widgets/error_boundary.dart';
import 'ui/widgets/modern_offline_banner.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Global Error Handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[GLOBAL ERROR] ${details.exception}');
    return GlobalErrorWidget(errorDetails: details);
  };
  
  try {
    debugPrint('[APP] Initializing NotificationService...');
    await NotificationService().init();
    
    debugPrint('[APP] Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('[APP] Supabase initialized successfully');
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
        Provider<NotificationService>.value(value: NotificationService()),
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

  @override
  void initState() {
    super.initState();
    // Access provider via context inside initState (listen: false)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = AppRouter.createRouter(userProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PSGMX - Placement Excellence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) {
        return ModernOfflineBanner(child: child ?? const SizedBox());
      },
    );
  }
}
