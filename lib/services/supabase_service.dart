import 'package:supabase_flutter/supabase_flutter.dart';

/// Core Supabase service wrapper
/// Provides centralized access to Supabase client, auth, and database
class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;
  
  /// Get the authenticated Supabase client
  SupabaseClient get supabase => client;
  
  /// Get the auth instance
  GoTrueClient get auth => client.auth;
  
  /// Get the database instance
  SupabaseQueryBuilder from(String table) => client.from(table);
  
  /// Get current user
  User? get currentUser => auth.currentUser;
  
  /// Auth state stream
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}
