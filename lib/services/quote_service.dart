import '../core/constants/daily_inspirations.dart';

class QuoteService {
  /// Get today's inspirational message
  /// No "Daily Motivation" label - just pure inspiration
  Future<Map<String, String>> getDailyQuote() async {
    return {
      'text': DailyInspirations.getMessageForToday(),
      'author': '', // No author attribution for cleaner UI
    };
  }
}
