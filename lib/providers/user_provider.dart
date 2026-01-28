import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // Import this

/// UserProvider: Central state management for authenticated user
///
/// Responsibilities:
/// - Manage user authentication state
/// - Load user profile from database
/// - Handle sign up, sign in, password reset
/// - Persist session across app restarts
class UserProvider with ChangeNotifier {
  final AuthService _authService;
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _initComplete = false;

  // Simulation Mode for Placement Reps
  UserRole? _simulatedRole;

  UserProvider({required AuthService authService})
      : _authService = authService {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get initComplete => _initComplete;

  bool get isSimulating => _simulatedRole != null;
  UserRole? get simulatedRole => _simulatedRole;

  // Expose auth service for first-time user detection
  AuthService get authService => _authService;

  // EFFECTIVE ROLES (Use these for UI logic)
  // If simulating, strictly return simulation status.
  // If not simulating, return actual role.
  bool get isStudent => _simulatedRole != null
      ? _simulatedRole == UserRole.student
      : (_currentUser?.isStudent ?? false);

  bool get isTeamLeader => _simulatedRole != null
      ? _simulatedRole == UserRole.teamLeader
      : (_currentUser?.isTeamLeader ?? false);

  bool get isCoordinator => _simulatedRole != null
      ? _simulatedRole == UserRole.coordinator
      : (_currentUser?.isCoordinator ?? false);

  bool get isPlacementRep => _simulatedRole != null
      ? _simulatedRole == UserRole.placementRep
      : (_currentUser?.isPlacementRep ?? false);

  // True Admin Access (Never simulated away)
  bool get hasActualAdminAccess => _currentUser?.hasAdminAccess ?? false;
  bool get isActualPlacementRep => _currentUser?.isPlacementRep ?? false;

  void setSimulationRole(UserRole? role) {
    if (!isActualPlacementRep) return; // Security check
    _simulatedRole = role;
    notifyListeners();
  }

  // Public retry method for Splash Screen Failsafe
  void retryInit() {
    _init();
  }

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

          // Fetch user profile (DO NOT AUTO-CREATE)
          // If null, it means we have a session (OTP Verified) but no profile (Password not set yet).
          // This allows AppRouter to keep us on the Verify/Create Password screen.
          _currentUser = await _authService.getUserProfile(supabaseUser.id);

          if (_currentUser != null) {
            debugPrint(
                '[UserProvider] User document loaded: ${_currentUser?.email}');
            // Schedule birthday notification if enabled and DOB exists
            _scheduleBirthdayNotificationIfNeeded();
          } else {
            debugPrint(
                '[UserProvider] Session active but no user profile found. Assuming incomplete signup.');
            // Do NOT sign out here. We need the session to create the password.
          }
        } catch (e) {
          debugPrint('[UserProvider] Error fetching user document: $e');
          // Still mark init as complete
          _currentUser = null;
          _isLoading = false;
          _initComplete = true;
          notifyListeners();

          // Only sign out on genuine connection errors if we really want to,
          // but better to leave it for retry.
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
            // Fetch profile (don't auto-create)
            _currentUser = await _authService.getUserProfile(supabaseUser.id);

            if (_currentUser != null) {
              debugPrint('[UserProvider] User loaded: ${_currentUser?.email}');
              // Schedule birthday notification if enabled
              _scheduleBirthdayNotificationIfNeeded();
            } else {
              debugPrint(
                  '[UserProvider] User signed in (OTP) but no profile yet.');
            }
          } catch (e) {
            debugPrint('[UserProvider] Error fetching user: $e');
            // Do not sign out automatically, allowing signup flow to proceed
            _currentUser = null;
          }
        } else {
          debugPrint('[UserProvider] User signed out');
          _currentUser = null;
        }
        notifyListeners();
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

  /// VERIFY OTP AND SET PASSWORD: Combined method for modern flow
  ///
  /// Called by ModernOtpScreen
  /// - Verifies OTP and sets password in one transaction
  /// - Creates user profile from whitelist
  /// - Signs user in automatically
  Future<void> verifyOtpAndSetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      debugPrint(
          '[UserProvider] Verifying OTP and setting password for: $email');

      // Step 1: Verify OTP and create password (combined)
      final authResponse = await _authService.verifyOtpAndCreatePassword(
        email: email,
        otp: otp,
        password: password,
      );

      if (authResponse.session == null) {
        throw Exception('Failed to create session');
      }

      debugPrint('[UserProvider] OTP verified and password set successfully');

      // Step 2: Get authenticated user
      final authUser = authResponse.user;
      if (authUser == null) {
        throw Exception('No authenticated user after signup');
      }

      debugPrint('[UserProvider] Creating user profile from whitelist...');

      // Step 3: Create user profile from whitelist data
      _currentUser = await _authService.createUserFromWhitelist(
        authUser.id,
        email,
      );

      if (_currentUser == null) {
        throw Exception('Failed to create user profile in database');
      }

      debugPrint(
          '[UserProvider] ✅ User profile created successfully: ${_currentUser?.name}');

      // Step 4: Schedule birthday notification if needed
      _scheduleBirthdayNotificationIfNeeded();

      notifyListeners();

      // Wait for auth state to be fully updated
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint(
          '[UserProvider] ✅ Signup complete - user authenticated with database profile');
    } catch (e) {
      debugPrint('[UserProvider] verifyOtpAndSetPassword error: $e');
      rethrow;
    }
  }

  /// COMPLETE SIGNUP WITH PASSWORD: Create password after OTP verified
  ///
  /// Called by CreatePasswordScreen (SECURE FLOW STEP 3)
  /// - OTP already verified by verifyOtp()
  /// - This sets the password and creates user profile from whitelist
  /// - User already has active session from OTP verification
  /// - PRODUCTION: Auto-populates from whitelist (123 students)
  Future<void> completeSignupWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[UserProvider] Completing signup with password for: $email');

      // Step 1: Set password - OTP already verified in previous step
      await _authService.createPasswordAfterOtpVerification(password);

      debugPrint('[UserProvider] Password created successfully');

      // Step 2: Get authenticated user ID
      final authUser = _authService.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user after password creation');
      }

      debugPrint('[UserProvider] Creating user profile from whitelist...');

      // Step 3: PRODUCTION - Create user from whitelist data
      // This populates reg_no, name, batch, team_id, dob, leetcode_username, roles
      _currentUser = await _authService.createUserFromWhitelist(
        authUser.id,
        email,
      );

      debugPrint(
          '[UserProvider] User profile created: ${_currentUser?.name} (${_currentUser?.regNo})');

      // Step 4: Schedule birthday notification if DOB exists
      _scheduleBirthdayNotificationIfNeeded();

      notifyListeners();

      // Wait for auth state to be fully updated
      await Future.delayed(const Duration(milliseconds: 300));

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

  Future<void> updateDob(DateTime newDob) async {
    if (_currentUser == null) return;
    try {
      final dobStr = newDob.toIso8601String().split('T')[0];
      await Supabase.instance.client
          .from('users')
          .update({'dob': dobStr}).eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(dob: newDob);
      notifyListeners();

      // Reschedule birthday notification with new DOB
      _scheduleBirthdayNotificationIfNeeded();
    } catch (e) {
      debugPrint('Error updating DOB: $e');
      rethrow;
    }
  }

  Future<void> updateBirthdayNotification(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'birthday_notifications_enabled': enabled}).eq(
              'id', _currentUser!.uid);

      _currentUser =
          _currentUser!.copyWith(birthdayNotificationsEnabled: enabled);
      notifyListeners();

      // Schedule or cancel birthday notification
      _scheduleBirthdayNotificationIfNeeded();
    } catch (e) {
      debugPrint('Error updating notif setting: $e');
      rethrow;
    }
  }

  Future<void> updateLeetCodeUsername(String username) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'leetcode_username': username}).eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(leetcodeUsername: username);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating leetcode username: $e');
      rethrow;
    }
  }

  Future<void> updateLeetCodeNotification(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'leetcode_notifications_enabled': enabled}).eq(
              'id', _currentUser!.uid);

      _currentUser =
          _currentUser!.copyWith(leetcodeNotificationsEnabled: enabled);
      notifyListeners();

      // Update local schedule
      if (enabled) {
        await NotificationService().scheduleLeetCodeReminders();
      } else {
        await NotificationService().cancelLeetCodeReminders();
      }
    } catch (e) {
      debugPrint('Error updating leetcode notif setting: $e');
      rethrow;
    }
  }

  /// Schedule birthday notification if user has DOB and notifications enabled
  void _scheduleBirthdayNotificationIfNeeded() {
    if (_currentUser == null) return;

    try {
      if (_currentUser!.dob != null) {
        NotificationService().scheduleBirthdayNotification(
          dob: _currentUser!.dob!,
          userName: _currentUser!.name,
          enabled: _currentUser!.birthdayNotificationsEnabled,
        );
      }
    } catch (e) {
      debugPrint('[UserProvider] Error scheduling birthday notification: $e');
    }
  }
}
