import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/app_user.dart';

/// AuthService: Secure OTP-based authentication using Supabase Auth
///
/// FLOW:
/// 1. User enters email (must be @psgtech.ac.in)
/// 2. System checks if email in whitelist
/// 3. OTP sent to email via Supabase
/// 4. User enters OTP -> Session created
/// 5. If new user, profile created from whitelist automatically
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
  Future<bool> sendOtpToEmail(String email) async {
    try {
      // 1. Validate domain
      if (!email.endsWith('@psgtech.ac.in')) {
        throw Exception('Only @psgtech.ac.in emails are allowed.');
      }

      email = email.trim().toLowerCase();
      debugPrint('[AuthService] Sending OTP to: $email');

      // 2. Check Whitelist
      final whitelistData = await _supabaseService
          .from('whitelist')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (whitelistData == null) {
        throw Exception('Email not authorized. Please contact administrator.');
      }

      // 3. Send OTP Token
      // Note: Users MUST exist in auth.users (created via SQL script with matching UUIDs)
      await _supabaseService.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Users pre-exist with matching UUIDs
      );

      debugPrint('[AuthService] ✅ OTP sent to $email');
      return true;

    } on AuthException catch (e) {
      debugPrint('[AuthService] Auth Error: ${e.message}');
      
      // If user doesn't exist, provide clear error
      if (e.message.contains('Database error finding user') || 
          e.message.contains('User not found')) {
        throw 'User not found. Please contact administrator to add your account.';
      }
      
      if (e.message.contains('rate limit')) {
        throw 'Too many requests. Please wait a moment.';
      }
      throw e.message;
    } catch (e) {
      debugPrint('[AuthService] Error: $e');
      throw e.toString();
    }
  }

  /// STEP 2: VERIFY OTP (Magic Link Token)
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      email = email.trim().toLowerCase();
      
      if (otp.length != 6) {
        throw 'OTP must be 6 digits';
      }

      debugPrint('[AuthService] Verifying OTP for $email');

      // Verify OTP with Supabase (using magic link token)
      final response = await _supabaseService.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session == null) {
        throw 'Verification failed. Please try again.';
      }

      final user = response.user;
      if (user == null) {
        throw 'User data not available.';
      }

      debugPrint('[AuthService] ✅ OTP verified successfully');
      debugPrint('[AuthService] User authenticated: ${user.email}');
      debugPrint('[AuthService] User ID: ${user.id}');

      // Profile should already exist with matching UUID
      // No need to create or check - UserProvider will fetch it
      debugPrint('[AuthService] ✅ Login complete for: $email');

    } on AuthException catch (e) {
      debugPrint('[AuthService] Auth error: ${e.message}');
      if (e.message.contains('Invalid') || e.message.contains('expired')) {
        throw 'Invalid or expired OTP. Please request a new one.';
      }
      throw e.message;
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      throw e.toString();
    }
  }

  /// Internal: Create user profile if it doesn't exist
  Future<void> _ensureUserProfile(String userId, String email) async {
    try {
      debugPrint('[AuthService] Checking if profile exists for $userId...');
      
      // Check if user already exists by ID
      final existingProfileById = await getUserProfile(userId);
      if (existingProfileById != null) {
        debugPrint('[AuthService] ✅ Profile already exists (by ID).');
        return;
      }

      // Also check by email (in case trigger created it)
      final existingProfileByEmail = await _supabaseService.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (existingProfileByEmail != null) {
        debugPrint('[AuthService] ✅ Profile already exists (by email). Updating id if needed.');

        final existingId = existingProfileByEmail['id']?.toString();
        if (existingId != null && existingId != userId) {
          await _supabaseService.client
              .from('users')
              .update({'id': userId})
              .eq('email', email);
          debugPrint('[AuthService] ✅ Profile id updated to match auth user.');
        }
        return;
      }

      debugPrint('[AuthService] Profile does not exist. Fetching from whitelist...');
      
      // Fetch whitelist data
      final whitelistData = await _supabaseService.client
          .from('whitelist')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (whitelistData == null) {
        debugPrint('[AuthService] ⚠️ User not found in whitelist: $email');
        debugPrint('[AuthService] Creating profile with defaults...');
        
        // Create minimal profile if not in whitelist (fallback)
        await _createMinimalProfile(userId, email);
        return;
      }

      debugPrint('[AuthService] Whitelist data found: ${whitelistData.toString()}');

      // Parse roles safely
      dynamic rolesData = whitelistData['roles'];
      Map<String, dynamic> roles;
      
      if (rolesData == null) {
        roles = {
          'isStudent': true,
          'isTeamLeader': false,
          'isCoordinator': false,
          'isPlacementRep': false,
        };
      } else if (rolesData is Map) {
        roles = Map<String, dynamic>.from(rolesData);
      } else {
        roles = {
          'isStudent': true,
          'isTeamLeader': false,
          'isCoordinator': false,
          'isPlacementRep': false,
        };
      }

      // Extract reg_no from email if not provided
      String regNo = whitelistData['reg_no']?.toString() ?? 
                     email.split('@')[0].toUpperCase();
      
      // Ensure reg_no is unique by checking if it already exists
      final existingRegNo = await _supabaseService.client
          .from('users')
          .select('id')
          .eq('reg_no', regNo)
          .maybeSingle();
      
      if (existingRegNo != null && existingRegNo['id'] != userId) {
        // Add a suffix to make it unique
        regNo = '${regNo}_${userId.substring(0, 4)}';
        debugPrint('[AuthService] Reg_no already exists, using: $regNo');
      }

      // Create user with proper null handling
      final userData = {
        'id': userId,
        'email': email,
        'reg_no': regNo,
        'name': whitelistData['name']?.toString() ?? 'Student',
        'batch': whitelistData['batch']?.toString() ?? 'G1',
        'team_id': whitelistData['team_id']?.toString(),
        'roles': roles,
        'dob': whitelistData['dob']?.toString(),
        'leetcode_username': whitelistData['leetcode_username']?.toString(),
        'birthday_notifications_enabled': true,
        'leetcode_notifications_enabled': true,
      };

      debugPrint('[AuthService] Creating profile for: ${userData['email']} - ${userData['name']}');
      
      try {
        final result = await _supabaseService.client
            .from('users')
            .insert(userData)
            .select()
            .single();
            
        debugPrint('[AuthService] ✅ Profile created successfully: $result');
      } on PostgrestException catch (e) {
        // If duplicate key error, profile already exists (created by trigger)
        if (e.code == '23505') {
          debugPrint('[AuthService] ✅ Profile already exists (duplicate key). This is OK - trigger created it.');
          return;
        }
        rethrow;
      }
      
    } catch (e, stackTrace) {
      // If it's a duplicate key error, that's actually success (profile exists)
      if (e.toString().contains('duplicate') || 
          e.toString().contains('unique') ||
          e.toString().contains('23505')) {
        debugPrint('[AuthService] ✅ Profile already exists (caught duplicate). Continuing...');
        return; // Success - profile exists
      }
      
      debugPrint('[AuthService] ❌ Error ensuring profile: $e');
      debugPrint('[AuthService] Stack trace: $stackTrace');
      
      // Try to provide more specific error information
      if (e.toString().contains('foreign key')) {
        debugPrint('[AuthService] Foreign key constraint violation');
      } else if (e.toString().contains('null value')) {
        debugPrint('[AuthService] Null value in required field');
      }
      
      rethrow;
    }
  }

  /// Create minimal profile as fallback
  Future<void> _createMinimalProfile(String userId, String email) async {
    try {
      final regNo = email.split('@')[0].toUpperCase();
      
      // Check if reg_no exists
      final existingRegNo = await _supabaseService.client
          .from('users')
          .select('id')
          .eq('reg_no', regNo)
          .maybeSingle();
      
      String finalRegNo = regNo;
      if (existingRegNo != null && existingRegNo['id'] != userId) {
        finalRegNo = '${regNo}_${userId.substring(0, 4)}';
      }

      final userData = {
        'id': userId,
        'email': email,
        'reg_no': finalRegNo,
        'name': email.split('@')[0].toUpperCase(),
        'batch': 'G1',
        'team_id': null,
        'roles': {
          'isStudent': true,
          'isTeamLeader': false,
          'isCoordinator': false,
          'isPlacementRep': false,
        },
        'birthday_notifications_enabled': true,
        'leetcode_notifications_enabled': true,
      };

      await _supabaseService.client
          .from('users')
          .insert(userData)
          .select()
          .single();
          
      debugPrint('[AuthService] ✅ Minimal profile created');
    } catch (e) {
      debugPrint('[AuthService] ❌ Failed to create minimal profile: $e');
      rethrow;
    }
  }

  /// Fetch user profile
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      debugPrint('[AuthService] Fetching profile for user ID: $userId');
      
      final response = await _supabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[AuthService] ❌ No profile found for user ID: $userId');
        return null;
      }
      
      debugPrint('[AuthService] ✅ Profile found: ${response['email']} - ${response['name']}');
      return AppUser.fromJson(response);
    } catch (e) {
      debugPrint('[AuthService] ❌ Error fetching profile: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabaseService.auth.signOut();
  }
}
