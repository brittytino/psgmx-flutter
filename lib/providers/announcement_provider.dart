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
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 30)) {
       return;
    }
  
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabaseService.client
          .from('announcements')
          .select()
          .order('is_priority', ascending: false)
          .order('created_at', ascending: false);

      _announcements = (response as List)
          .map((e) => Announcement.fromMap(e))
          .where((a) => a.expiryDate == null || a.expiryDate!.isAfter(DateTime.now()))
          .toList();
          
      _lastFetchTime = DateTime.now();
          
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      await fetchAnnouncements();
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      rethrow;
    }
  }
}
