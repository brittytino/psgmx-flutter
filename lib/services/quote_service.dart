import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuoteService {
  static const String _kDateKey = 'quote_date';
  static const String _kQuoteKey = 'quote_text';
  static const String _kAuthorKey = 'quote_author';

  Future<Map<String, String>> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = prefs.getString(_kDateKey);

    if (storedDate == today) {
      return {
        'text': prefs.getString(_kQuoteKey) ?? 'Keep pushing!',
        'author': prefs.getString(_kAuthorKey) ?? 'PSG Tech',
      };
    }

    // Fetch new quote
    try {
      // Using a free open API for demo purposes as OpenRouter requires a key.
      // In production, swap with OpenRouter API call.
      final response = await http.get(Uri.parse('https://api.quotable.io/random?tags=technology,inspirational'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'];
        final author = data['author'];

        await prefs.setString(_kDateKey, today);
        await prefs.setString(_kQuoteKey, content);
        await prefs.setString(_kAuthorKey, author);

        return {'text': content, 'author': author};
      }
    } catch (e) {
      debugPrint('Quote fetch error: $e');
    }

    return {'text': 'Consistency is key.', 'author': 'Unknown'};
  }
}
