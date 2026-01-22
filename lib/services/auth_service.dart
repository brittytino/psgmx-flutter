import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// AuthService: Secure OTP-based authentication using Supabase Auth
/// 
/// SECURE FLOW:
/// 1. User enters email (must be @psgtech.ac.in)
/// 2. System checks if email in whitelist/students table
/// 3. OTP sent to email via Supabase
/// 4. User verifies OTP
/// 5. User creates password
/// 6. Account activated - login with email + password
/// 
/// Features:
/// - OTP verification (email ownership proof)
/// - Whitelist validation (only authorized students)
/// - Password-based login after OTP verification
/// - Session persistence
/// - Production-level security
class AuthService {
  final SupabaseService _supabaseService;

  AuthService(this._supabaseService);

  /// Get current authenticated user
  User? get currentUser => _supabaseService.currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current session
  Session? get currentSession => _supabaseService.auth.currentSession;

  /// STEP 1: VALIDATE EMAIL & SEND OTP
  /// 
  /// Prerequisites:
  /// - Email must be @psgtech.ac.in
  /// - Email must exist in whitelist table (verified against student records)
  /// 
  /// Returns: true if OTP sent successfully, false if email not in whitelist
  /// Throws: Exception if email invalid or other error
  /// 
  /// Production Level:
  /// - Validates whitelist first
  /// - Uses OTP type email (6-digit code)
  /// - Proper error handling
  /// - Retry logic with exponential backoff for rate limits
  Future<bool> sendOtpToEmail(String email, {int retryCount = 0}) async {
    try {
      // Validate email domain
      if (!email.endsWith('@psgtech.ac.in')) {
        throw Exception('Only @psgtech.ac.in emails are allowed.');
      }

      email = email.trim().toLowerCase();
      debugPrint('[AuthService] Step 1: Validating email for OTP: $email');

      // Step 1: Check if email exists in whitelist (authorization check)
      debugPrint('[AuthService] Step 2: Checking whitelist for authorization...');
      
      final whitelistData = await _supabaseService
          .from('whitelist')
          .select('email, name, reg_no, team_id')
          .eq('email', email)
          .maybeSingle();

      if (whitelistData == null) {
        debugPrint('[AuthService] ERROR: Email not authorized (not in whitelist): $email');
        return false;
      }

      debugPrint('[AuthService] Step 3: Email authorized - ${whitelistData['name']} from team ${whitelistData['team_id']}');

      // Step 2: Send OTP via Supabase Auth with retry logic
      debugPrint('[AuthService] Step 4: Sending OTP code to: $email');
      
      try {
        await _supabaseService.auth.signInWithOtp(
          email: email,
          shouldCreateUser: true,
        );
        
        debugPrint('[AuthService] Step 5: OTP sent successfully to: $email');
        debugPrint('[AuthService] SUCCESS: Check your email for 6-digit OTP code');
        return true;
        
      } on AuthException catch (authError) {
        debugPrint('[AuthService] Auth error during OTP send: ${authError.message}');
        
        // Handle specific cases
        if (authError.message.contains('already registered')) {
          debugPrint('[AuthService] User already has account, resending OTP...');
          return true;
        }
        
        // Handle rate limiting with retry
        if (authError.message.contains('rate limit') || authError.message.contains('over_request')) {
          if (retryCount < 2) {
            // Wait before retrying (exponential backoff)
            final waitTime = Duration(seconds: 2 + (retryCount * 3));
            debugPrint('[AuthService] Rate limited. Retrying in ${waitTime.inSeconds} seconds... (Attempt ${retryCount + 1}/3)');
            
            await Future.delayed(waitTime);
            
            // Recursive retry
            return sendOtpToEmail(email, retryCount: retryCount + 1);
          } else {
            throw 'Too many OTP requests. Please wait 60 seconds before trying again.';
          }
        }
        
        throw 'Failed to send OTP: ${authError.message}';
      }
      
    } on AuthException catch (e) {
      debugPrint('[AuthService] ERROR: ${e.message}');
      throw 'Error: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// STEP 2: VERIFY OTP (without password - just verification)
  /// 
  /// Verifies OTP code sent to email
  /// Production Level:
  /// - Validates OTP format (6 digits)
  /// - Creates temporary session
  /// - Proper error handling with user-friendly messages
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      email = email.trim().toLowerCase();
      
      // Validate OTP format
      if (otp.isEmpty) {
        throw 'Please enter the OTP code';
      }
      
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        throw 'OTP must be a 6-digit code';
      }

      debugPrint('[AuthService] Verifying OTP for: $email');

      // Verify OTP with Supabase
      final response = await _supabaseService.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session == null) {
        throw 'OTP verification failed. Please try again.';
      }

      debugPrint('[AuthService] OTP verified successfully for: $email');
    } on AuthException catch (e) {
      debugPrint('[AuthService] OTP verification error: ${e.message}');
      
      // User-friendly error messages
      if (e.message.contains('invalid') || e.message.contains('expired')) {
        throw 'Invalid or expired OTP. Please request a new one.';
      }
      
      throw 'OTP verification failed: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// STEP 2b: CREATE PASSWORD AFTER OTP VERIFIED
  /// 
  /// Called after OTP is verified and session created
  /// Sets password for the authenticated user
  /// Production Level:
  /// - Validates password strength
  /// - Secure password update
  /// - Proper error handling
  /// 
  /// Prerequisites:
  /// - OTP already verified (verifyOtp called successfully)
  /// - User has active temporary session
  /// - Password meets security requirements (min 8 chars)
  Future<void> createPasswordAfterOtpVerification(String password) async {
    try {
      // Validate password
      if (password.isEmpty) {
        throw 'Please enter a password';
      }
      
      if (!isPasswordStrong(password)) {
        throw 'Password must be at least 8 characters';
      }

      debugPrint('[AuthService] Creating password after OTP verification');

      // Set password for current authenticated user
      await _supabaseService.auth.updateUser(
        UserAttributes(password: password),
      );

      debugPrint('[AuthService] Password created successfully');
    } on AuthException catch (e) {
      debugPrint('[AuthService] Password creation error: ${e.message}');
      throw 'Password creation failed: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// STEP 2 COMBINED: VERIFY OTP & CREATE PASSWORD
  /// 
  /// Combines OTP verification and password creation in one call
  /// Production Level:
  /// - Full validation of both OTP and password
  /// - Transaction-like flow
  /// - Proper error handling at each step
  /// 
  /// Prerequisites:
  /// - User received OTP via email (6-digit code)
  /// - Password meets security requirements (min 8 chars)
  /// 
  /// Returns: AuthResponse (contains session if successful)
  /// This creates the account and signs user in immediately
  Future<AuthResponse> verifyOtpAndCreatePassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      email = email.trim().toLowerCase();
      
      // Validate inputs
      if (otp.isEmpty) {
        throw 'Please enter the OTP code';
      }
      
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        throw 'OTP must be a 6-digit code';
      }
      
      if (password.isEmpty) {
        throw 'Please enter a password';
      }
      
      if (!isPasswordStrong(password)) {
        throw 'Password must be at least 8 characters';
      }

      debugPrint('[AuthService] Step 1: Verifying OTP and creating account for: $email');

      // Step 1: Verify OTP
      debugPrint('[AuthService] Step 2: Verifying 6-digit OTP code...');
      final otpResponse = await _supabaseService.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (otpResponse.session == null) {
        throw 'OTP verification failed. Session not created.';
      }

      debugPrint('[AuthService] Step 3: OTP verified successfully');

      // Step 2: Create password for authenticated user
      debugPrint('[AuthService] Step 4: Setting account password...');
      await _supabaseService.auth.updateUser(
        UserAttributes(password: password),
      );

      debugPrint('[AuthService] Step 5: Password created successfully');
      debugPrint('[AuthService] SUCCESS: Account created and user logged in');

      // Return the auth response with active session
      return otpResponse;
      
    } on AuthException catch (e) {
      debugPrint('[AuthService] Auth error during signup: ${e.message}');
      
      // User-friendly error messages
      if (e.message.contains('invalid') || e.message.contains('expired')) {
        throw 'Invalid or expired OTP. Please request a new one.';
      }
      
      if (e.message.contains('duplicate')) {
        throw 'This email already has an account. Please log in instead.';
      }
      
      throw 'Signup failed: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Error during signup: $e');
      rethrow;
    }
  }

  /// SIGN IN: Returning user logs in with email and password
  /// 
  /// Returns: AuthResponse (contains session if successful)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Validate email domain
      if (!email.endsWith('@psgtech.ac.in')) {
        throw Exception('Only @psgtech.ac.in emails are allowed.');
      }

      email = email.trim().toLowerCase();

      debugPrint('[AuthService] Signing in user: $email');

      final response = await _supabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('[AuthService] Sign in successful: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      debugPrint('[AuthService] Sign in error: ${e.message}');
      // Return user-friendly error messages
      if (e.message.contains('Invalid login credentials')) {
        throw 'Invalid email or password.';
      }
      throw 'Sign in failed: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// FORGOT PASSWORD: Request password reset email
  /// 
  /// Sends reset link to email. User clicks link to set new password.
  /// For institutional use, deep linking can open reset screen in app.
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectUrl,
  }) async {
    try {
      if (!email.endsWith('@psgtech.ac.in')) {
        throw Exception('Only @psgtech.ac.in emails are allowed.');
      }

      email = email.trim().toLowerCase();

      debugPrint('[AuthService] Sending password reset email to: $email');

      await _supabaseService.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );

      debugPrint('[AuthService] Password reset email sent successfully');
    } on AuthException catch (e) {
      debugPrint('[AuthService] Password reset error: ${e.message}');
      throw 'Password reset failed: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// UPDATE PASSWORD: Set new password for authenticated user
  /// 
  /// Used after password reset flow or account management
  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('[AuthService] Updating password for user');

      await _supabaseService.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      debugPrint('[AuthService] Password updated successfully');
    } on AuthException catch (e) {
      debugPrint('[AuthService] Password update error: ${e.message}');
      throw 'Password update failed: ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// SIGN OUT: Terminate user session
  /// 
  /// Clears all local session data
  Future<void> signOut() async {
    try {
      debugPrint('[AuthService] Signing out user');
      await _supabaseService.auth.signOut();
      debugPrint('[AuthService] User signed out successfully');
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
      rethrow;
    }
  }

  /// Validate password strength
  /// 
  /// Institutional requirements:
  /// - Minimum 8 characters
  /// - Can include letters, numbers, special characters
  static bool isPasswordStrong(String password) {
    return password.length >= 8;
  }

  /// Get password strength feedback
  static String getPasswordStrengthFeedback(String password) {
    if (password.isEmpty) {
      return 'Enter a password';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return 'Password is strong';
  }
}
