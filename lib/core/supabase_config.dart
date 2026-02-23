class SupabaseConfig {
  // Supabase Project Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dsucqgrwyimtuhebvmpx.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_0Xf74Qb5kGsF9qvOHL4nAA_m31d69DK',
  );
}
