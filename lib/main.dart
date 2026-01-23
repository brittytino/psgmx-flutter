import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/supabase_config.dart';
import 'core/app_router.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/quote_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const PsgMxApp());
}

class PsgMxApp extends StatelessWidget {
  const PsgMxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services
    final supabaseService = SupabaseService();
    final authService = AuthService(supabaseService);
    final quoteService = QuoteService();

    return MultiProvider(
      providers: [
        Provider<SupabaseService>.value(value: supabaseService),
        Provider<AuthService>.value(value: authService),
        Provider<QuoteService>.value(value: quoteService),
        ChangeNotifierProvider(
          create: (_) => UserProvider(authService: authService),
        ),
      ],
      child: MaterialApp.router(
        title: 'PSG MCA Prep',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
