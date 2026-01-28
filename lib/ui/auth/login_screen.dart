import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

/// Modern Login Screen - Dark Black + Orange Theme
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate email
  bool _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    }

    if (!email.endsWith('@psgtech.ac.in')) {
      setState(() => _emailError = 'Use your college email (@psgtech.ac.in)');
      return false;
    }

    setState(() => _emailError = null);
    return true;
  }

  /// Validate password
  bool _validatePassword() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return false;
    }

    setState(() => _passwordError = null);
    return true;
  }

  /// Handle sign in with first-time user detection
  Future<void> _handleSignIn() async {
    setState(() => _generalError = null);

    if (!_validateEmail()) return;

    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isLoading = true);
    
    try {
      // Try to detect if first time user (optional - if auth service has this method)
      final authService = context.read<UserProvider>().authService;
      
      // Check if user exists
      bool isFirstTime = false;
      try {
        isFirstTime = await authService.isFirstTimeUser(email);
      } catch (e) {
        // If method doesn't exist, assume not first time
        isFirstTime = false;
      }
      
      if (!mounted) return;
      
      if (isFirstTime) {
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome! Let\'s set up your account with an OTP.'),
              backgroundColor: Color(0xFFFF6600),
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to OTP signup
          final success = await context.read<UserProvider>().requestOtp(email: email);
          if (success && mounted) {
            context.push('/verify_otp', extra: email);
          } else if (mounted) {
            setState(() => _generalError = 'Email not found in student records.');
          }
        }
        return;
      }
      
      // Returning user - validate password
      if (!_validatePassword()) {
        setState(() => _isLoading = false);
        return;
      }
      
      final password = _passwordController.text;

      await Provider.of<UserProvider>(context, listen: false).signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          String error = e.toString();
          // Clean up error messages
          if (error.contains('Invalid login credentials')) {
            error = 'Invalid email or password. Please try again.';
          } else if (error.contains('Email not confirmed')) {
            error = 'Please verify your email first.';
          }
          _generalError = error;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6600),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'PSG MCA Prep',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Sign in to continue your progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB3B3B3),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Login Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF222222),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Field
                      Text(
                        'College Email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'john.doe@psgtech.ac.in',
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF666666)),
                          errorText: _emailError,
                        ),
                        onChanged: (_) {
                          if (_emailError != null) _validateEmail();
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Password Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/auth/forgot-password'),
                            child: const Text('Forgot?', style: TextStyle(color: Color(0xFFFF6600))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF666666)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF666666),
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                          errorText: _passwordError,
                        ),
                        onChanged: (_) {
                          if (_passwordError != null) _validatePassword();
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Error Message
                      if (_generalError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _generalError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () async {
                            // Navigate to signup flow
                            if (_validateEmail()) {
                              setState(() => _isLoading = true);
                              try {
                                final email = _emailController.text.trim().toLowerCase();
                                final success = await context.read<UserProvider>().requestOtp(email: email);
                                if (mounted) {
                                  if (success) {
                                    context.push('/verify_otp', extra: email);
                                  } else {
                                    setState(() => _generalError = 'Email not found in student records.');
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _generalError = e.toString());
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                          child: const Text('Sign Up (First Time)'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Footer
                Text(
                  '© 2025 PSG College of Technology',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
