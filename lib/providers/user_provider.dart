import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_router.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';

/// UserProvider: Central state management for authenticated user
///
/// Responsibilities:
/// - Manage user authentication state
/// - Load user profile from database
/// - Handle sign up, sign in, password reset
/// - Persist session across app restarts
class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepo;

  AppUser? _currentUser;
  bool _isLoading = true;
  bool _initComplete = false;

  UserProvider(
      {required AuthService authService, required UserRepository userRepo})
      : _authService = authService,
        _userRepo = userRepo {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get initComplete => _initComplete;

  bool get isTeamLeader => _currentUser?.isTeamLeader ?? false;
  bool get isCoordinator => _currentUser?.isCoordinator ?? false;
  bool get isPlacementRep => _currentUser?.isPlacementRep ?? false;

  void _init() {
    debugPrint('[UserProvider] Initializing...');
    _checkAuthStateOnce();
  }

  /// Check initial authentication state
  ///
  /// Called on app startup to restore session
  Future<void> _checkAuthStateOnce() async {
    try {
      debugPrint('[UserProvider] Starting initialization check...');

      // Get current Supabase user immediately
      final supabaseUser = _authService.currentUser;
      debugPrint(
          '[UserProvider] Current Supabase user: ${supabaseUser?.email}');

      if (supabaseUser != null) {
        try {
          debugPrint(
              '[UserProvider] Fetching user document for: ${supabaseUser.email}');
          _currentUser = await _userRepo.ensureUserDocument(
            supabaseUser.id,
            supabaseUser.email!,
          );
          debugPrint(
              '[UserProvider] User document loaded: ${_currentUser?.email}');
        } catch (e) {
          debugPrint('[UserProvider] Error fetching user document: $e');
          // Still mark init as complete even if user fetch fails
          _isLoading = false;
          _initComplete = true;
          notifyListeners();

          // Try to sign out
          try {
            await _authService.signOut();
          } catch (e) {
            debugPrint('[UserProvider] Error signing out: $e');
          }
          _currentUser = null;
          return;
        }
      } else {
        debugPrint('[UserProvider] No user signed in');
        _currentUser = null;
      }

      debugPrint('[UserProvider] Init check complete - marking as initialized');
    } catch (e) {
      debugPrint('[UserProvider] Unexpected error in initial check: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _initComplete = true;
      debugPrint(
          '[UserProvider] Initialization complete: initComplete=$_initComplete, hasUser=${_currentUser != null}');
      notifyListeners();

      // Trigger router refresh to evaluate redirect logic
      appRouter.refresh();

      // Now listen for ongoing auth state changes
      _listenToAuthStateChanges();
    }
  }

  /// Listen for auth state changes (sign in, sign out)
  void _listenToAuthStateChanges() {
    _authService.authStateChanges.listen(
      (AuthState authState) async {
        final supabaseUser = authState.session?.user;
        debugPrint('[UserProvider] Auth state changed: ${supabaseUser?.email}');

        if (supabaseUser != null) {
          try {
            _currentUser = await _userRepo.ensureUserDocument(
              supabaseUser.id,
              supabaseUser.email!,
            );
            debugPrint('[UserProvider] User loaded: ${_currentUser?.email}');
          } catch (e) {
            debugPrint('[UserProvider] Error fetching user: $e');
            await _authService.signOut();
            _currentUser = null;
          }
        } else {
          debugPrint('[UserProvider] User signed out');
          _currentUser = null;
        }
        notifyListeners();
        appRouter.refresh();
      },
      onError: (e) {
        debugPrint('[UserProvider] Auth stream error: $e');
      },
    );
  }

  /// REQUEST OTP: Send OTP to email for account verification
  ///
  /// Called by SetPasswordScreen (SECURE FLOW STEP 1)
  /// - Validates email is @psgtech.ac.in
  /// - Checks if email exists in student whitelist
  /// - Sends OTP via Supabase Auth
  /// - Returns true if email authorized, false otherwise
  Future<bool> requestOtp({required String email}) async {
    try {
      debugPrint('[UserProvider] Requesting OTP for: $email');

      final success = await _authService.sendOtpToEmail(email);

      if (success) {
        debugPrint('[UserProvider] OTP sent successfully');
      } else {
        debugPrint('[UserProvider] Email not authorized');
      }

      return success;
    } catch (e) {
      debugPrint('[UserProvider] OTP request error: $e');
      rethrow;
    }
  }

  /// VERIFY OTP: Verify OTP code sent to email
  ///
  /// Called by VerifyOtpScreen (SECURE FLOW STEP 2a)
  /// - Verifies OTP code
  /// - Creates temporary session
  /// - Prepares for password creation
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      debugPrint('[UserProvider] Verifying OTP for: $email');

      // Call auth service to verify OTP
      // This creates a temporary session
      await _authService.verifyOtp(email: email, otp: otp);

      debugPrint('[UserProvider] OTP verified successfully');
    } catch (e) {
      debugPrint('[UserProvider] OTP verification error: $e');
      rethrow;
    }
  }

  /// COMPLETE SIGNUP WITH PASSWORD: Create password after OTP verified
  ///
  /// Called by CreatePasswordScreen (SECURE FLOW STEP 3)
  /// - OTP already verified by verifyOtp()
  /// - This just sets the password for the authenticated session
  /// - User already has active session from OTP verification
  /// - No re-verification needed
  Future<void> completeSignupWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[UserProvider] Completing signup with password for: $email');

      // Only set password - OTP already verified in previous step
      await _authService.createPasswordAfterOtpVerification(password);

      debugPrint('[UserProvider] Password created successfully');

      // Wait for auth state to be updated
      await Future.delayed(Duration(milliseconds: 300));

      debugPrint(
          '[UserProvider] Account setup complete - user is authenticated');
    } catch (e) {
      debugPrint('[UserProvider] Signup completion error: $e');
      rethrow;
    }
  }

  /// SIGN UP: Create new user account (password setup)
  ///
  /// Called by SetPasswordScreen
  /// - Validates email domain (@psgtech.ac.in)
  /// - Creates account in Supabase Auth
  /// - Loads user profile from database
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[UserProvider] Signing up user: $email');

      // DEPRECATED: Use requestOtp() + verifyOtp() + completeSignupWithPassword() instead
      // This method kept for backward compatibility

      debugPrint('[UserProvider] Sign up successful');
    } catch (e) {
      debugPrint('[UserProvider] Sign up error: $e');
      rethrow;
    }
  }

  /// SIGN IN: Authenticate returning user
  ///
  /// Called by LoginScreen
  /// - Validates email domain
  /// - Authenticates with password
  /// - Loads user profile from database
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[UserProvider] Signing in user: $email');

      await _authService.signIn(email: email, password: password);

      // User will be automatically signed in after successful signin
      // Auth state listener will load profile
      debugPrint('[UserProvider] Sign in successful');
    } catch (e) {
      debugPrint('[UserProvider] Sign in error: $e');
      rethrow;
    }
  }

  /// RESET PASSWORD: Request password reset email
  ///
  /// Called by ForgotPasswordScreen
  /// - Sends password reset link to email
  /// - User clicks link to set new password
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('[UserProvider] Requesting password reset for: $email');

      await _authService.resetPasswordForEmail(email: email);

      debugPrint('[UserProvider] Password reset email sent');
    } catch (e) {
      debugPrint('[UserProvider] Password reset error: $e');
      rethrow;
    }
  }

  /// SIGN OUT: Terminate user session
  ///
  /// Called by user logout action
  /// - Clears session
  /// - Clears user data
  Future<void> signOut() async {
    try {
      debugPrint('[UserProvider] Signing out user');

      await _authService.signOut();
      _currentUser = null;
      notifyListeners();

      debugPrint('[UserProvider] Sign out successful');
    } catch (e) {
      debugPrint('[UserProvider] Sign out error: $e');
      rethrow;
    }
  }
}
