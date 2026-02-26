import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ecampus_attendance.dart';
import '../models/ecampus_cgpa.dart';

/// Configuration for the PSG eCampus API backend.
/// Set ECAMPUS_API_URL and ECAMPUS_API_SECRET via --dart-define at build time
/// or override the defaults below for development.
class EcampusConfig {
  static const String apiUrl = String.fromEnvironment(
    'ECAMPUS_API_URL',
    defaultValue: 'https://psgmx-ecampus-api.onrender.com', // change to your Render URL
  );
  static const String apiSecret = String.fromEnvironment(
    'ECAMPUS_API_SECRET',
    defaultValue: 'change-me-to-a-long-random-string', // must match API_SECRET env var on server
  );
}

/// Service that communicates with the PSG FastAPI backend and reads
/// cached data directly from Supabase.
class EcampusService {
  static final EcampusService _instance = EcampusService._internal();
  factory EcampusService() => _instance;
  EcampusService._internal();

  final _supabase = Supabase.instance.client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Api-Secret': EcampusConfig.apiSecret,
      };

  Map<String, String> get _authHeaders {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      return _headers;
    }
    return {
      ..._headers,
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Trigger a sync on the backend ────────────────────────────────────────

  /// Calls the backend to scrape eCampus and store fresh data in Supabase.
  /// Returns a summary map on success, throws on error.
  Future<Map<String, dynamic>> syncUser(String rollno) async {
    final uri = Uri.parse('${EcampusConfig.apiUrl}/api/ecampus/sync')
        .replace(queryParameters: {'rollno': rollno});

    debugPrint('[EcampusService] POST $uri');
    final response = await http
        .post(uri, headers: _authHeaders)
        .timeout(const Duration(seconds: 60));

    final body = _tryDecodeJson(response.body);
    if (response.statusCode == 200) {
      if (body == null) {
        throw Exception('Unexpected response from server.');
      }
      return body;
    }

    final detail = body?['detail'] ?? body?['message'];
    final message = detail ??
        (response.body.isNotEmpty
            ? response.body
            : 'Sync failed (HTTP ${response.statusCode})');
    throw Exception(message);
  }

  /// Trigger a sync for all students (placement rep only).
  Future<Map<String, dynamic>> syncAllUsers() async {
    if (_supabase.auth.currentSession?.accessToken == null) {
      throw Exception('Please sign in again to refresh all students.');
    }
    final uri = Uri.parse('${EcampusConfig.apiUrl}/api/ecampus/sync-all');

    debugPrint('[EcampusService] POST $uri');
    final response = await http
        .post(uri, headers: _authHeaders)
        .timeout(const Duration(minutes: 5));

    final body = _tryDecodeJson(response.body);
    if (response.statusCode == 200) {
      if (body == null) {
        throw Exception('Unexpected response from server.');
      }
      return body;
    }

    final detail = body?['detail'] ?? body?['message'];
    final message = detail ??
        (response.body.isNotEmpty
            ? response.body
            : 'Sync failed (HTTP ${response.statusCode})');
    throw Exception(message);
  }

  // ─── Read from Supabase cache ─────────────────────────────────────────────

  /// Reads attendance data for [rollno] directly from the Supabase cache.
  /// Returns null when no data has been synced yet.
  Future<EcampusAttendance?> getAttendance(String rollno) async {
    try {
      final result = await _supabase
          .from('ecampus_attendance')
          .select('reg_no, data, synced_at')
          .eq('reg_no', rollno)
          .maybeSingle();

      if (result == null) return null;
      return EcampusAttendance.fromSupabase(result);
    } catch (e) {
      debugPrint('[EcampusService] getAttendance error: $e');
      rethrow;
    }
  }

  /// Reads CGPA data for [rollno] directly from the Supabase cache.
  /// Returns null when no data has been synced yet.
  Future<EcampusCgpa?> getCgpa(String rollno) async {
    try {
      final result = await _supabase
          .from('ecampus_cgpa')
          .select('reg_no, data, synced_at')
          .eq('reg_no', rollno)
          .maybeSingle();

      if (result == null) return null;
      return EcampusCgpa.fromSupabase(result);
    } catch (e) {
      debugPrint('[EcampusService] getCgpa error: $e');
      rethrow;
    }
  }

  /// Convenience: sync and then immediately return the fresh attendance data.
  Future<EcampusAttendance?> syncAndGetAttendance(String rollno) async {
    await syncUser(rollno);
    return getAttendance(rollno);
  }

  /// Convenience: sync and then immediately return the fresh CGPA data.
  Future<EcampusCgpa?> syncAndGetCgpa(String rollno) async {
    await syncUser(rollno);
    return getCgpa(rollno);
  }

  // ─── Realtime subscription ────────────────────────────────────────────────

  /// Returns a stream that emits whenever the attendance row for [rollno]
  /// changes in Supabase (e.g. after a server-side sync-all cron runs).
  Stream<EcampusAttendance?> attendanceStream(String rollno) {
    return _supabase
        .from('ecampus_attendance')
        .stream(primaryKey: ['id'])
        .eq('reg_no', rollno)
        .map((rows) {
          if (rows.isEmpty) return null;
          return EcampusAttendance.fromSupabase(rows.first);
        });
  }

  /// Returns a stream that emits whenever the CGPA row for [rollno] changes.
  Stream<EcampusCgpa?> cgpaStream(String rollno) {
    return _supabase
        .from('ecampus_cgpa')
        .stream(primaryKey: ['id'])
        .eq('reg_no', rollno)
        .map((rows) {
          if (rows.isEmpty) return null;
          return EcampusCgpa.fromSupabase(rows.first);
        });
  }
}
