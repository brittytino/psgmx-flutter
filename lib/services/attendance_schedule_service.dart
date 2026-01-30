import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scheduled_date.dart';

class AttendanceScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // SCHEDULED DATES MANAGEMENT
  // ========================================

  /// Check if a date is scheduled for attendance
  Future<bool> isDateScheduled(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('scheduled_attendance_dates')
          .select('id')
          .eq('date', dateString)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check scheduled date: ${e.toString()}');
    }
  }

  /// Get all scheduled dates
  Future<List<ScheduledDate>> getScheduledDates() async {
    try {
      final response = await _supabase
          .from('scheduled_attendance_dates')
          .select()
          .order('date', ascending: true);

      return (response as List)
          .map((data) => ScheduledDate.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get scheduled dates: ${e.toString()}');
    }
  }

  /// Get scheduled dates in a range
  Future<List<ScheduledDate>> getScheduledDatesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startString = startDate.toIso8601String().split('T')[0];
      final endString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('scheduled_attendance_dates')
          .select()
          .gte('date', startString)
          .lte('date', endString)
          .order('date', ascending: true);

      return (response as List)
          .map((data) => ScheduledDate.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception(
          'Failed to get scheduled dates in range: ${e.toString()}');
    }
  }

  /// Add a scheduled date (Placement Rep only)
  Future<ScheduledDate> addScheduledDate({
    required DateTime date,
    required String scheduledBy,
    String? notes,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('scheduled_attendance_dates')
          .insert({
            'date': dateString,
            'scheduled_by': scheduledBy,
            'notes': notes,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return ScheduledDate.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add scheduled date: ${e.toString()}');
    }
  }

  /// Update a scheduled date
  Future<ScheduledDate> updateScheduledDate({
    required String id,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (date != null) {
        updates['date'] = date.toIso8601String().split('T')[0];
      }
      if (notes != null) {
        updates['notes'] = notes;
      }

      final response = await _supabase
          .from('scheduled_attendance_dates')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return ScheduledDate.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update scheduled date: ${e.toString()}');
    }
  }

  /// Delete a scheduled date
  Future<void> deleteScheduledDate(String id) async {
    try {
      await _supabase.from('scheduled_attendance_dates').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete scheduled date: ${e.toString()}');
    }
  }

  /// Get upcoming scheduled dates (next 30 days)
  Future<List<ScheduledDate>> getUpcomingScheduledDates() async {
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));

      return await getScheduledDatesInRange(
        startDate: now,
        endDate: thirtyDaysLater,
      );
    } catch (e) {
      throw Exception('Failed to get upcoming scheduled dates: ${e.toString()}');
    }
  }

  /// Check if today is scheduled
  Future<bool> isTodayScheduled() async {
    return await isDateScheduled(DateTime.now());
  }
}
