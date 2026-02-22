class SupabaseConfig {
  // Supabase Project Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ucmskbgdpnolnyrmkotz.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_FYSPL2NrQ7uby010u8hTmg_26v9e2MI',
  );
}
