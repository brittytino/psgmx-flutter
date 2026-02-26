import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ecampus_attendance.dart';
import '../models/ecampus_ca_marks.dart';
import '../models/ecampus_cgpa.dart';
import '../services/ecampus_service.dart';

enum EcampusStatus { initial, loading, syncing, loaded, error }

/// Provider managing PSG eCampus attendance and CGPA state.
/// Add it in your MultiProvider in main.dart:
///   ChangeNotifierProvider(create: (_) => EcampusProvider()),
class EcampusProvider extends ChangeNotifier {
  final EcampusService _service = EcampusService();

  // ─── State ─────────────────────────────────────────────────────────────────
  EcampusStatus _status = EcampusStatus.initial;
  EcampusAttendance? _attendance;
  EcampusCgpa? _cgpa;
  EcampusCaMarks? _caMarks;
  String? _errorMessage;
  String? _currentRollno;
  DateTime? _lastSyncedAt;

  StreamSubscription<EcampusAttendance?>? _attSub;
  StreamSubscription<EcampusCgpa?>? _cgpaSub;
  StreamSubscription<EcampusCaMarks?>? _caSub;

  // ─── Getters ───────────────────────────────────────────────────────────────
  EcampusStatus get status => _status;
  EcampusAttendance? get attendance => _attendance;
  EcampusCgpa? get cgpa => _cgpa;
  EcampusCaMarks? get caMarks => _caMarks;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isLoading => _status == EcampusStatus.loading;
  bool get isSyncing => _status == EcampusStatus.syncing;
  bool get hasData =>
      _attendance != null || _cgpa != null || _caMarks != null;

  // ─── Initialise & load cached data ────────────────────────────────────────

  /// Call this once after the user logs in.
  /// Loads whatever is already cached in Supabase, then subscribes to
  /// real-time updates so the UI stays fresh without manual refresh.
  Future<void> init(String rollno) async {
    if (_currentRollno == rollno && _status == EcampusStatus.loaded) return;
    _currentRollno = rollno;
    _setStatus(EcampusStatus.loading);

    try {
      final results = await Future.wait([
        _service.getAttendance(rollno),
        _service.getCgpa(rollno),
        _service.getCaMarks(rollno),
      ]);

      _attendance = results[0] as EcampusAttendance?;
      _cgpa = results[1] as EcampusCgpa?;
      _caMarks = results[2] as EcampusCaMarks?;
      _lastSyncedAt = _attendance?.syncedAt ?? _cgpa?.syncedAt;
      _setStatus(EcampusStatus.loaded);

      // Subscribe to real-time updates
      _cancelSubscriptions();
      _attSub = _service.attendanceStream(rollno).listen((a) {
        _attendance = a;
        _lastSyncedAt = a?.syncedAt;
        notifyListeners();
      });
      _cgpaSub = _service.cgpaStream(rollno).listen((c) {
        _cgpa = c;
        notifyListeners();
      });
      _caSub = _service.caMarksStream(rollno).listen((ca) {
        _caMarks = ca;
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load data: $e');
    }
  }

  // ─── Sync (triggers backend scrape) ───────────────────────────────────────

  /// Tells the backend to scrape eCampus and refresh Supabase, then reads
  /// fresh local data.  The real-time stream will update the UI automatically,
  /// but we also do an explicit read to be safe.
  Future<void> sync() async {
    if (_currentRollno == null) return;
    _setStatus(EcampusStatus.syncing);
    _errorMessage = null;

    try {
      await _service.syncUser(_currentRollno!);
      // Real-time stream handles the update; explicit read as fallback:
      final results = await Future.wait([
        _service.getAttendance(_currentRollno!),
        _service.getCgpa(_currentRollno!),
        _service.getCaMarks(_currentRollno!),
      ]);
      _attendance = results[0] as EcampusAttendance?;
      _cgpa = results[1] as EcampusCgpa?;
      _caMarks = results[2] as EcampusCaMarks?;
      _lastSyncedAt = _attendance?.syncedAt ?? _cgpa?.syncedAt;
      _setStatus(EcampusStatus.loaded);
    } catch (e) {
      _setError('Sync failed: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setStatus(EcampusStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = _toUserFriendlyError(msg);
    _status = EcampusStatus.error;
    debugPrint('[EcampusProvider] $msg');
    notifyListeners();
  }

  String _toUserFriendlyError(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('invalid api secret') || text.contains('401')) {
      return 'Service authentication failed. Please contact admin.';
    }
    if (text.contains('attendance table not found')) {
      return 'Unable to read attendance from the academic portal right now. Please try again later.';
    }
    if (text.contains('login may have failed') || text.contains('login failed')) {
      return 'Academic portal login failed. Verify your DOB is set correctly and try again later.';
    }
    if (text.contains('failed to load data')) {
      return 'Unable to load academic data right now. Please try again.';
    }
    if (text.contains('sync failed')) {
      return 'Unable to refresh academic data right now. Please try again later.';
    }
    return 'Something went wrong while loading academic data.';
  }

  void _cancelSubscriptions() {
    _attSub?.cancel();
    _cgpaSub?.cancel();
    _caSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  /// Reset provider state (e.g. on logout).
  void reset() {
    _cancelSubscriptions();
    _attendance = null;
    _cgpa = null;
    _caMarks = null;
    _errorMessage = null;
    _currentRollno = null;
    _lastSyncedAt = null;
    _status = EcampusStatus.initial;
    notifyListeners();
  }
}
