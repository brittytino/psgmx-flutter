import '../models/app_user.dart';
import 'supabase_service.dart';

class UserRepository {
  final SupabaseService _supabaseService;

  UserRepository(this._supabaseService);

  Future<AppUser?> getUser(String uid) async {
    try {
      final response = await _supabaseService
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response == null) return null;
      
      return AppUser.fromMap(uid, response);
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<AppUser> ensureUserDocument(String uid, String email) async {
    try {
      // First check if user exists
      final existingUser = await getUser(uid);
      if (existingUser != null) {
        return existingUser;
      }

      // User doesn't exist, check whitelist
      final whitelistResponse = await _supabaseService
          .from('whitelist')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (whitelistResponse == null) {
        throw Exception('User not authorized in whitelist');
      }

      // Create user from whitelist data
      final userData = {
        'id': uid,
        'email': email,
        'reg_no': whitelistResponse['reg_no'],
        'name': whitelistResponse['name'],
        'team_id': whitelistResponse['team_id'],
        'roles': whitelistResponse['roles'],
      };

      await _supabaseService.from('users').insert(userData);
      
      return AppUser.fromMap(uid, userData);
    } catch (e) {
      throw Exception('Error ensuring user document: $e');
    }
  }
}
