import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // OpenRouter API configuration
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKey = 'YOUR_OPENROUTER_API_KEY'; // Set via environment
  
  // Model to use (fast and cost-effective)
  static const String _model = 'anthropic/claude-3-haiku';

  // ========================================
  // NOTIFICATION GENERATION
  // ========================================

  Future<String> generateMotivationMessage({
    required NotificationTone tone,
  }) async {
    final prompt = _buildMotivationPrompt(tone);
    return await _generateWithAI(prompt);
  }

  Future<String> generateLeetCodeReminder({
    required NotificationTone tone,
    String? todaysProblem,
  }) async {
    final prompt = _buildLeetCodeReminderPrompt(tone, todaysProblem);
    return await _generateWithAI(prompt);
  }

  Future<String> generateAttendanceReminder({
    required NotificationTone tone,
  }) async {
    final prompt = _buildAttendanceReminderPrompt(tone);
    return await _generateWithAI(prompt);
  }

  String _buildMotivationPrompt(NotificationTone tone) {
    final toneDescription = switch (tone) {
      NotificationTone.serious =>
        'professional, serious, and inspiring without being preachy',
      NotificationTone.friendly =>
        'warm, friendly, and encouraging like a supportive mentor',
      NotificationTone.humorous =>
        'light, slightly humorous (like Zomato notifications), but not cringy or overly emoji-heavy',
    };

    return '''
Generate a short daily motivation message for MCA students preparing for placements.
Tone: $toneDescription
Length: 1-2 sentences maximum (under 150 characters)
Requirements:
- Relevant to coding/placements/career
- No emoji overload (max 1-2 emojis)
- Direct and actionable if possible
- NOT generic ("You can do it!" is boring)

Output ONLY the message text, nothing else.
''';
  }

  String _buildLeetCodeReminderPrompt(
    NotificationTone tone,
    String? todaysProblem,
  ) {
    final toneDescription = switch (tone) {
      NotificationTone.serious => 'professional and direct',
      NotificationTone.friendly => 'encouraging and supportive',
      NotificationTone.humorous => 'light and fun',
    };

    final problemContext = todaysProblem != null
        ? "Today's problem: $todaysProblem"
        : "Today's coding challenge is ready";

    return '''
Generate a short reminder for students to solve today's LeetCode problem.
Context: $problemContext
Tone: $toneDescription
Length: 1 sentence maximum
Requirements:
- Create urgency without being annoying
- Make it feel important
- No cheesy motivational quotes

Output ONLY the message text, nothing else.
''';
  }

  String _buildAttendanceReminderPrompt(NotificationTone tone) {
    final toneDescription = switch (tone) {
      NotificationTone.serious => 'professional reminder',
      NotificationTone.friendly => 'gentle nudge',
      NotificationTone.humorous => 'playful but clear',
    };

    return '''
Generate a short evening reminder for team leaders to mark attendance.
Tone: $toneDescription
Length: 1 sentence maximum
Requirements:
- Reminder about responsibility
- Not scolding, just prompting
- Clear call to action

Output ONLY the message text, nothing else.
''';
  }

  Future<String> _generateWithAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_openRouterBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://psgmx-placement.app',
          'X-Title': 'PSG MCA Placement Prep',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 100,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message']['content'] as String;
        return message.trim();
      } else {
        throw Exception('AI generation failed: ${response.body}');
      }
    } catch (e) {
      // Fallback to generic messages
      return _getFallbackMessage();
    }
  }

  String _getFallbackMessage() {
    final fallbacks = [
      'Code today. Succeed tomorrow. 💻',
      'One problem at a time, one step closer to your dream job.',
      'Consistency beats intensity. Keep solving!',
    ];
    return fallbacks[DateTime.now().millisecond % fallbacks.length];
  }

  // ========================================
  // NOTIFICATION CRUD
  // ========================================

  Future<AppNotification> createNotification({
    required String title,
    required String message,
    required NotificationType notificationType,
    NotificationTone? tone,
    required String targetAudience,
    DateTime? validUntil,
    String? createdBy,
  }) async {
    try {
      final response = await _supabase.from('notifications').insert({
        'title': title,
        'message': message,
        'notification_type': notificationType.name,
        'tone': tone?.name,
        'target_audience': targetAudience,
        'valid_until': validUntil?.toIso8601String(),
        'created_by': createdBy,
        'is_active': true,
      }).select().single();

      return AppNotification.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  Future<List<AppNotification>> getActiveNotifications({
    String? targetAudience,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select()
          .eq('is_active', true);

      if (targetAudience != null) {
        query = query.or('target_audience.eq.all,target_audience.eq.$targetAudience');
      }

      final response = await query.order('generated_at', ascending: false);

      return (response as List)
          .map((data) => AppNotification.fromMap(data))
          .where((n) => !n.isExpired)
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: ${e.toString()}');
    }
  }

  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      // Get user's unread notifications
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            notification_reads!left(
              read_at,
              dismissed_at
            )
          ''')
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((data) => AppNotification.fromMap(data))
          .where((n) => !n.isExpired)
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _supabase.from('notification_reads').upsert({
        'notification_id': notificationId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: ${e.toString()}');
    }
  }

  Future<void> dismissNotification(String notificationId, String userId) async {
    try {
      await _supabase.from('notification_reads').upsert({
        'notification_id': notificationId,
        'user_id': userId,
        'dismissed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to dismiss notification: ${e.toString()}');
    }
  }

  // ========================================
  // DAILY NOTIFICATION GENERATION
  // ========================================

  Future<void> generateDailyNotifications(String createdBy) async {
    try {
      // Morning motivation
      final motivationTone = _selectRandomTone();
      final motivationMessage = await generateMotivationMessage(
        tone: motivationTone,
      );

      await createNotification(
        title: 'Good Morning! 🌅',
        message: motivationMessage,
        notificationType: NotificationType.motivation,
        tone: motivationTone,
        targetAudience: 'all',
        validUntil: DateTime.now().add(const Duration(days: 1)),
        createdBy: createdBy,
      );

      // LeetCode reminder
      final leetCodeTone = _selectRandomTone();
      final leetCodeMessage = await generateLeetCodeReminder(
        tone: leetCodeTone,
      );

      await createNotification(
        title: 'Daily Challenge 💡',
        message: leetCodeMessage,
        notificationType: NotificationType.reminder,
        tone: leetCodeTone,
        targetAudience: 'students',
        validUntil: DateTime.now().add(const Duration(days: 1)),
        createdBy: createdBy,
      );

      // Evening attendance reminder for team leaders
      final attendanceTone = NotificationTone.friendly;
      final attendanceMessage = await generateAttendanceReminder(
        tone: attendanceTone,
      );

      await createNotification(
        title: 'Attendance Reminder 📋',
        message: attendanceMessage,
        notificationType: NotificationType.reminder,
        tone: attendanceTone,
        targetAudience: 'team_leaders',
        validUntil: DateTime.now().add(const Duration(hours: 6)),
        createdBy: createdBy,
      );
    } catch (e) {
      throw Exception('Failed to generate daily notifications: ${e.toString()}');
    }
  }

  NotificationTone _selectRandomTone() {
    final tones = NotificationTone.values;
    final index = DateTime.now().day % tones.length;
    return tones[index];
  }

  // ========================================
  // CLEANUP OLD NOTIFICATIONS
  // ========================================

  Future<void> cleanupExpiredNotifications() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_active': false})
          .lt('valid_until', DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to cleanup notifications: $e');
    }
  }
}
