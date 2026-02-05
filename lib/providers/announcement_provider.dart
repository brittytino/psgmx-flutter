import 'package:flutter/foundation.dart';
import '../models/announcement.dart';
import '../services/supabase_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;

  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  DateTime? _lastFetchTime;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AnnouncementProvider(this._supabaseService);

  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    // Cache Check: If data is fresh (< 30 mins) and not forced, return immediately.
    if (!forceRefresh &&
        _announcements.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(minutes: 30)) {
      return;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final response = await _supabaseService.client
          .from('announcements')
          .select()
          .order('is_priority', ascending: false)
          .order('created_at', ascending: false);

      _announcements = (response as List)
          .map((e) => Announcement.fromMap(e))
          .where((a) =>
              a.expiryDate == null || a.expiryDate!.isAfter(DateTime.now()))
          .toList();

      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String message,
    required bool isPriority,
    required DateTime? expiry,
  }) async {
    final user = _supabaseService.client.auth.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.client.from('announcements').insert({
        'title': title,
        'message': message,
        'is_priority': isPriority,
        'expiry_date': expiry?.toIso8601String(),
        'created_by': user.id,
      });

      // Refresh list
      await fetchAnnouncements(forceRefresh: true);
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      rethrow;
    }
  }

  /// Delete an announcement by ID
  /// Only placement reps and coordinators can delete
  Future<void> deleteAnnouncement(String announcementId) async {
    final user = _supabaseService.client.auth.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.client
          .from('announcements')
          .delete()
          .eq('id', announcementId);

      // Remove from local list immediately
      _announcements.removeWhere((a) => a.id == announcementId);
      notifyListeners();

      debugPrint('Announcement deleted: $announcementId');
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      rethrow;
    }
  }

  /// Check if current user can manage announcements
  Future<bool> canManageAnnouncements() async {
    final user = _supabaseService.client.auth.currentUser;
    if (user == null) return false;

    try {
      final userData = await _supabaseService.client
          .from('users')
          .select('roles')
          .eq('email', user.email!)
          .maybeSingle();

      if (userData == null) return false;

      final roles = userData['roles'] as Map<String, dynamic>?;
      return (roles?['isPlacementRep'] ?? false) ||
          (roles?['isCoordinator'] ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Safely notify listeners (prevents setState during build)
  void _safeNotifyListeners() {
    // Use addPostFrameCallback to ensure we're not in the build phase
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
