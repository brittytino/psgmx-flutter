import 'package:flutter/foundation.dart';
import '../data/student_whitelist_data.dart';
import 'supabase_service.dart';

/// Service to ensure the whitelist table is populated with student data
class DataSeedService {
  final SupabaseService _supabaseService;
  
  DataSeedService(this._supabaseService);
  
  /// Check if whitelist is empty and seed it if needed
  Future<void> ensureWhitelistSeeded() async {
    try {
      // Check current count by fetching all emails
      final countResponse = await _supabaseService.client
          .from('whitelist')
          .select('email');
      
      final count = (countResponse as List).length;
      
      debugPrint('[Seeder] Whitelist has $count entries');
      
      // If we have fewer than 50 students, reseed (threshold to detect empty/incomplete DB)
      if (count < 50) {
        debugPrint('[Seeder] 🌱 Whitelist appears empty or incomplete. Seeding ${kStudentWhitelistData.length} students...');
        
        // Batch upsert all students
        await _supabaseService.client
            .from('whitelist')
            .upsert(kStudentWhitelistData);
        
        debugPrint('[Seeder] ✅ Seeding complete! Added ${kStudentWhitelistData.length} students.');
      } else {
        debugPrint('[Seeder] ✅ Whitelist already populated ($count students)');
      }
    } catch (e) {
      debugPrint('[Seeder] ❌ Error seeding whitelist: $e');
      // Don't rethrow - this is a best-effort operation
    }
  }
}
