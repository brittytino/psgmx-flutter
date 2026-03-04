import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Background service that schedules "All the best!" push notifications for every
/// CA exam present in the shared [ca_timetable_global] table.
///
/// Lifecycle
/// ──────────
/// • [init] is called once in [main.dart] after [NotificationService.init].
/// • On startup it reads the current timetable and schedules/fires notifications.
/// • A Supabase realtime stream re-triggers [_reschedule] whenever the placement
///   rep updates the timetable (new sync).
/// • A daily midnight timer re-evaluates past/future exams so stale entries are
///   pruned automatically.
///
/// Notification IDs 500-598 are exclusively reserved for CA exam alerts —
/// they are cancelled and recreated in bulk on every reschedule.
class CaExamNotificationService {
  static final CaExamNotificationService _instance =
      CaExamNotificationService._internal();
  factory CaExamNotificationService() => _instance;
  CaExamNotificationService._internal();

  Timer? _midnightTimer;
  StreamSubscription? _timetableSub;
  bool _isInitialized = false;

  // Track the last synced_at timestamp we scheduled from, to avoid redundant work.
  String? _lastScheduledSyncedAt;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Initialise the service.  Safe to call multiple times.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    debugPrint('[CaExamService] Initializing…');

    // 1. Immediate check from current Supabase data.
    await _reschedule(source: 'init');

    // 2. Watch for timetable updates pushed by the placement rep.
    _timetableSub = Supabase.instance.client
        .from('ca_timetable_global')
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .listen(
          (rows) {
            if (rows.isEmpty) return;
            final syncedAt = rows.first['synced_at'] as String? ?? '';
            if (syncedAt == _lastScheduledSyncedAt) return; // no change
            debugPrint('[CaExamService] Timetable updated — rescheduling notifications');
            _reschedule(
              source: 'realtime',
              overrideData: rows.first['data'],
              syncedAt: syncedAt,
            );
          },
          onError: (Object e) {
            debugPrint('[CaExamService] Realtime error (non-fatal): $e');
          },
          cancelOnError: false,
        );

    // 3. Reschedule at midnight every day (past exams are pruned automatically).
    _scheduleMidnightRefresh();

    debugPrint('[CaExamService] ✅ Initialized');
  }

  /// Force a manual reschedule (e.g. called after the placement rep triggers a sync).
  Future<void> refreshNow() => _reschedule(source: 'manual');

  /// Dispose timers and subscriptions.
  void dispose() {
    _midnightTimer?.cancel();
    _timetableSub?.cancel();
    _isInitialized = false;
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<void> _reschedule({
    required String source,
    dynamic overrideData,
    String? syncedAt,
  }) async {
    try {
      debugPrint('[CaExamService] Rescheduling CA exam notifications (source: $source)…');

      List<Map<String, String>> rows = [];

      if (overrideData != null) {
        rows = _parseRows(overrideData);
      } else {
        // Fetch from Supabase directly.
        final result = await Supabase.instance.client
            .from('ca_timetable_global')
            .select('data, synced_at')
            .eq('id', 1)
            .maybeSingle();

        if (result == null) {
          debugPrint('[CaExamService] No global timetable row found — nothing to schedule');
          return;
        }
        syncedAt ??= result['synced_at'] as String? ?? '';
        rows = _parseRows(result['data']);
      }

      if (rows.isEmpty) {
        debugPrint('[CaExamService] Timetable is empty — cancelling any old notifications');
        await NotificationService().cancelCaExamNotifications();
        return;
      }

      await NotificationService().rescheduleCaExamNotifications(rows);
      _lastScheduledSyncedAt = syncedAt;
    } catch (e, st) {
      // Non-fatal — never let this crash the app.
      debugPrint('[CaExamService] ❌ Reschedule failed: $e\n$st');
    }
  }

  /// Parse raw `data` JSONB from Supabase into a flat list of rows.
  List<Map<String, String>> _parseRows(dynamic rawData) {
    if (rawData == null) return [];
    Map<String, dynamic> data = {};
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else {
      return [];
    }

    final rawRows = (data['rows'] as List<dynamic>? ?? []);
    return rawRows.whereType<Map>().map((r) {
      return r.map(
        (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
      );
    }).toList();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    // Fire just after midnight (00:05) to prune past exams.
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
    final delay = nextMidnight.difference(now);

    debugPrint(
        '[CaExamService] Next midnight refresh in ${delay.inHours}h ${delay.inMinutes % 60}m');

    _midnightTimer = Timer(delay, () {
      _reschedule(source: 'midnight');
      _scheduleMidnightRefresh(); // arm for next midnight
    });
  }
}
