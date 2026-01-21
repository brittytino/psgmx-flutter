import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// import 'firebase_options.dart'; // User needs to generate this
import 'core/app_router.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/user_repository.dart';
import 'services/firestore_service.dart';
import 'services/quote_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Using a try-catch for demo purposes so it doesn't crash without config
  try {
     await Firebase.initializeApp(); 
  } catch (e) {
    print("Firebase not initialized (expected if no config): $e");
  }

  runApp(const PsgMxApp());
}

class PsgMxApp extends StatelessWidget {
  const PsgMxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services
    final authService = AuthService();
    final userRepo = UserRepository();
    final firestoreService = FirestoreService();
    final quoteService = QuoteService();

    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<UserRepository>.value(value: userRepo),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<QuoteService>.value(value: quoteService),
        ChangeNotifierProvider(
          create: (_) => UserProvider(authService: authService, userRepo: userRepo),
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
