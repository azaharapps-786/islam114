import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:islam114/data/models/quran_dictionary_model.dart';

class QuranDictionaryService {
  static Future<List<QuranDictionaryItem>> loadDictionary(String language) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/dictionaries/quran_dictionary_$language.json');

      // Check if the JSON is valid
      if (jsonString.isEmpty) {
        throw Exception('Dictionary file is empty');
      }

      final dynamic jsonData = json.decode(jsonString);

      // Check if the data is a list
      if (jsonData is! List) {
        throw Exception('Invalid dictionary format: expected a list');
      }

      final List<dynamic> jsonList = jsonData;

      // Process all items including the first one with empty key
      final List<QuranDictionaryItem> items = [];

      for (final json in jsonList) {
        try {
          final item = QuranDictionaryItem.fromJson(json);
          items.add(item);
        } catch (e) {
          print('Error parsing dictionary item: $e');
          print('Problematic JSON: $json');
          // Continue processing other items even if one fails
        }
      }

      // Sort by ID to ensure proper order
      items.sort((a, b) => a.id.compareTo(b.id));

      return items;
    } catch (e) {
      print('Failed to load dictionary: $e');
      throw Exception('Failed to load dictionary: $e');
    }
  }

  static List<QuranDictionaryItem> searchDictionary(List<QuranDictionaryItem> items, String query) {
    if (query.isEmpty) return items;

    // Remove dots from query for number searches
    final cleanQuery = query.replaceAll('.', '');
    final lowerQuery = query.toLowerCase();

    // Remove parentheses and dots for location searches
    String locationQuery = query.replaceAll('(', '').replaceAll(')', '').replaceAll('.', '');

    // Extract individual words from the query for multi-word search
    final List<String> queryWords = _extractWords(query);
    final List<String> lowerQueryWords = queryWords.map((word) => word.toLowerCase()).toList();

    final List<QuranDictionaryItem> results = [];
    final Set<int> addedIds = {};

    for (final item in items) {
      if (addedIds.contains(item.id)) continue;

      // Priority 1: Exact title match
      if (item.title.toLowerCase() == lowerQuery) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 2: Title starts with whole word (not just first letter)
      if (_startsWithWholeWord(item.title.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 3: Title contains whole word (not just first letter)
      if (_containsWholeWord(item.title.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 4: Title contains word that starts with query (for variations like tiger -> tigers)
      if (_containsWordStartingWith(item.title.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Modified location checks to handle dots and parentheses
      final cleanLocation = item.location.replaceAll('(', '').replaceAll(')', '').replaceAll('.', '');

      // Priority 5: Exact location match (e.g., "2:33:3" or "(2:33:3)")
      if (item.location == query || cleanLocation == locationQuery) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 6: Location starts with query (e.g., "2:33" or "(2:33")
      if (item.location.startsWith(query) || cleanLocation.startsWith(locationQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 7: Transliteration exact match
      if (item.transliteration.toLowerCase() == lowerQuery) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 8: Transliteration starts with whole word
      if (_startsWithWholeWord(item.transliteration.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 9: Transliteration contains whole word
      if (_containsWholeWord(item.transliteration.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 10: Transliteration contains word that starts with query
      if (_containsWordStartingWith(item.transliteration.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 11: Translation exact match
      if (item.translation.toLowerCase() == lowerQuery) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 12: Translation starts with whole word
      if (_startsWithWholeWord(item.translation.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 13: Translation contains whole word
      if (_containsWholeWord(item.translation.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 14: Translation contains word that starts with query
      if (_containsWordStartingWith(item.translation.toLowerCase(), lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 15: Arabic word exact match
      if (item.arabicWord == query) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 16: Arabic word contains exact match
      if (item.arabicWord.contains(query)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 17: Multi-word search in Arabic verse
      if (queryWords.length > 1 && _containsAllWords(item.arabicVersePart, lowerQueryWords)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 18: Multi-word search in translation
      if (queryWords.length > 1 && _containsAllWords(item.translation, lowerQueryWords)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 19: Partial match in Arabic verse (for long verses)
      if (query.length > 10 && _containsPartialMatch(item.arabicVersePart, lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }

      // Priority 20: Partial match in translation (for long verses)
      if (query.length > 10 && _containsPartialMatch(item.translation, lowerQuery)) {
        results.add(item);
        addedIds.add(item.id);
        continue;
      }
    }

    return results;
  }

  // Helper method to check if text starts with whole word
  static bool _startsWithWholeWord(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    // Extract words from text
    final List<String> words = _extractWords(text);

    // Check if any word starts with the query
    for (final word in words) {
      if (word.startsWith(query)) {
        return true;
      }
    }

    return false;
  }

  // Helper method to check if text contains whole word
  static bool _containsWholeWord(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    // Extract words from text
    final List<String> words = _extractWords(text);

    // Check if any word equals the query
    for (final word in words) {
      if (word == query) {
        return true;
      }
    }

    return false;
  }

  // Helper method to check if text contains word that starts with query
  static bool _containsWordStartingWith(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    // Extract words from text
    final List<String> words = _extractWords(text);

    // Check if any word starts with the query
    for (final word in words) {
      if (word.startsWith(query)) {
        return true;
      }
    }

    return false;
  }

  // Helper method to extract words from a query
  static List<String> _extractWords(String text) {
    // Remove diacritics and special characters for Arabic text
    String normalizedText = text
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '') // Remove Arabic diacritics
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ') // Keep Arabic letters, numbers, and spaces
        .trim();

    return normalizedText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  }

  // Helper method to check if text contains all query words
  static bool _containsAllWords(String text, List<String> queryWords) {
    final String normalizedText = text
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '') // Remove Arabic diacritics
        .toLowerCase();

    for (final word in queryWords) {
      if (!normalizedText.contains(word)) {
        return false;
      }
    }
    return true;
  }

  // Helper method to check for partial match in long text
  static bool _containsPartialMatch(String text, String query) {
    if (text.length < query.length) return false;

    // For long queries, check if any substantial part of the query exists in the text
    final int minLength = query.length > 20 ? 10 : query.length ~/ 2;

    for (int i = 0; i <= query.length - minLength; i++) {
      final String substring = query.substring(i, i + minLength);
      if (text.contains(substring)) {
        return true;
      }
    }

    return false;
  }
}