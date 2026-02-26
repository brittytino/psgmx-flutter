import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ecampus_attendance.dart';
import '../models/ecampus_ca_marks.dart';
import '../models/ecampus_ca_timetable.dart';
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

  bool _isColdStartMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('spin down with inactivity') ||
        lower.contains('delay requests by 50 seconds') ||
        lower.contains('service unavailable') ||
        lower.contains('upstream request timeout') ||
        lower.contains('gateway timeout') ||
        lower.contains('bad gateway');
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 425 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        statusCode == 524 ||
        statusCode == 525 ||
        statusCode == 526;
  }

  String _friendlyErrorMessage(http.Response response) {
    final body = _tryDecodeJson(response.body);
    final detail = (body?['detail'] ?? body?['message'])?.toString();
    final raw = (detail != null && detail.isNotEmpty)
        ? detail
        : response.body.toString();

    if (_isColdStartMessage(raw) || _isRetryableStatus(response.statusCode)) {
      return 'Server is waking up. Please wait a few seconds and try again.';
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Your session has expired. Please sign in again.';
    }

    if (response.statusCode == 404) {
      return 'Academic sync service is temporarily unavailable. Please try again later.';
    }

    if (response.statusCode >= 500) {
      return 'Academic sync service is temporarily unavailable. Please try again shortly.';
    }

    return 'Unable to complete the request right now. Please try again.';
  }

  Future<void> _warmUpBackend() async {
    final uri = Uri.parse('${EcampusConfig.apiUrl}/api/ecampus/sync-all/status');
    try {
      await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Best-effort warmup only.
    }
  }

  Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
    int maxAttempts = 2,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await http.post(uri, headers: headers).timeout(timeout);
        final hasColdStart = _isColdStartMessage(response.body);
        final shouldRetry =
            attempt < maxAttempts && (_isRetryableStatus(response.statusCode) || hasColdStart);

        if (shouldRetry) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }

        return response;
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) break;
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) break;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw Exception(
      lastError is TimeoutException
          ? 'Server is taking longer than expected. Please try again.'
          : 'Unable to reach academic sync service right now. Please try again.',
    );
  }

  // ─── Trigger a sync on the backend ────────────────────────────────────────

  /// Calls the backend to scrape eCampus and store fresh data in Supabase.
  /// Returns a summary map on success, throws on error.
  Future<Map<String, dynamic>> syncUser(String rollno) async {
    final uri = Uri.parse('${EcampusConfig.apiUrl}/api/ecampus/sync')
        .replace(queryParameters: {'rollno': rollno});

    debugPrint('[EcampusService] POST $uri');
    await _warmUpBackend();
    final response = await _postWithRetry(
      uri,
      headers: _authHeaders,
      timeout: const Duration(seconds: 90),
      maxAttempts: 2,
    );

    final body = _tryDecodeJson(response.body);
    if (response.statusCode == 200) {
      if (body == null) {
        throw Exception('Unexpected response from server.');
      }
      return body;
    }

    throw Exception(_friendlyErrorMessage(response));
  }

  /// Trigger a sync for all students (placement rep only).
  Future<Map<String, dynamic>> syncAllUsers() async {
    if (_supabase.auth.currentSession?.accessToken == null) {
      throw Exception('Please sign in again to refresh all students.');
    }
    final uri = Uri.parse('${EcampusConfig.apiUrl}/api/ecampus/sync-all');

    debugPrint('[EcampusService] POST $uri');
    await _warmUpBackend();
    final response = await _postWithRetry(
      uri,
      headers: _authHeaders,
      timeout: const Duration(minutes: 6),
      maxAttempts: 2,
    );

    final body = _tryDecodeJson(response.body);
    if (response.statusCode == 200) {
      if (body == null) {
        throw Exception('Unexpected response from server.');
      }
      return body;
    }

    throw Exception(_friendlyErrorMessage(response));
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

  /// Reads CA marks data for [rollno] directly from Supabase cache.
  /// Returns null when no data has been synced yet.
  Future<EcampusCaMarks?> getCaMarks(String rollno) async {
    try {
      final result = await _supabase
          .from('ecampus_ca_marks')
          .select('reg_no, data, synced_at')
          .eq('reg_no', rollno)
          .maybeSingle();

      if (result == null) return null;
      return EcampusCaMarks.fromSupabase(result);
    } catch (e) {
      // Non-fatal: table may not exist yet (migration pending) or transient
      // network error (e.g. Cloudflare 525).  Attendance + CGPA must still load.
      debugPrint('[EcampusService] getCaMarks error (non-fatal): $e');
      return null;
    }
  }

  /// Reads CA timetable data for [rollno] directly from Supabase cache.
  /// Returns null when no data has been synced yet.
  Future<EcampusCaTimetable?> getCaTimetable(String rollno) async {
    try {
      final result = await _supabase
          .from('ecampus_ca_timetable')
          .select('reg_no, data, synced_at')
          .eq('reg_no', rollno)
          .maybeSingle();

      if (result == null) return null;
      return EcampusCaTimetable.fromSupabase(result);
    } catch (e) {
      // Non-fatal: table may not exist yet (migration pending) or transient
      // network error (e.g. Cloudflare 525).  Other data must still load.
      debugPrint('[EcampusService] getCaTimetable error (non-fatal): $e');
      return null;
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

  /// Returns a stream that emits whenever the CA marks row for [rollno] changes.
  Stream<EcampusCaMarks?> caMarksStream(String rollno) {
    return _supabase
        .from('ecampus_ca_marks')
        .stream(primaryKey: ['id'])
        .eq('reg_no', rollno)
        .map((rows) {
          if (rows.isEmpty) return null;
          return EcampusCaMarks.fromSupabase(rows.first);
        })
        .handleError((Object e) {
          // Table may not exist yet (migration pending) or SSL error.
          // Swallow silently so the stream stays alive when data appears later.
          debugPrint('[EcampusService] caMarksStream error (non-fatal): $e');
        });
  }

  /// Returns a stream that emits whenever the CA timetable row for [rollno] changes.
  Stream<EcampusCaTimetable?> caTimetableStream(String rollno) {
    return _supabase
        .from('ecampus_ca_timetable')
        .stream(primaryKey: ['id'])
        .eq('reg_no', rollno)
        .map((rows) {
          if (rows.isEmpty) return null;
          return EcampusCaTimetable.fromSupabase(rows.first);
        })
        .handleError((Object e) {
          debugPrint('[EcampusService] caTimetableStream error (non-fatal): $e');
        });
  }
}
