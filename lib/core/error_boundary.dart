import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  // ignore: prefer_final_fields
  bool _hasError = false; // Not final because we change it in onError
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Flutter doesn't have a direct "componentDidCatch" equivalent for widgets in the same way React does, 
  // but we can use ErrorWidget.builder globally.
  // However, this widget can serve as a localized trap if we used a custom builder, 
  // but for global hardening, we usually set FlutterError.onError.
  // Here, we'll provide a nice fallback UI if something lower crashes and we rebuild.
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
               SizedBox(height: 16),
               Text("Something went wrong.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
               Text("We've tracked the error and are working on it."),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}

// Global Error Handler Setup
void setupGlobalErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("GLOBAL ERROR CAUGHT: ${details.exception}");
    // Here you would log to Sentry/Crashlytics
  };
}
