class QuranDictionaryItem {
  final int id;
  final String title;
  final String subheading;
  final String location;
  final String transliteration;
  final String translation;
  final String arabicVersePart;
  final String arabicWord;

  QuranDictionaryItem({
    required this.id,
    required this.title,
    required this.subheading,
    required this.location,
    required this.transliteration,
    required this.translation,
    required this.arabicVersePart,
    required this.arabicWord,
  });

  factory QuranDictionaryItem.fromJson(Map<String, dynamic> json) {
    // Handle the empty key issue - this is the main fix
    int id = 0;

    // First try to get the ID from the empty key
    if (json.containsKey('') && json[''] != null) {
      id = _parseToInt(json['']);
    }
    // Fallback to 'id' key if it exists
    else if (json.containsKey('id')) {
      id = _parseToInt(json['id']);
    }

    return QuranDictionaryItem(
      id: id,
      title: _parseToString(json['title']),
      subheading: _parseToString(json['subheading']),
      location: _parseToString(json['location']),
      transliteration: _parseToString(json['transliteration']),
      translation: _parseToString(json['translation']),
      arabicVersePart: _parseToString(json['arabic_verse_part']),
      arabicWord: _parseToString(json['arabic_word']),
    );
  }

  // Helper method to safely parse int values
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Helper method to safely parse string values
  static String _parseToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      '': id,
      'title': title,
      'subheading': subheading,
      'location': location,
      'transliteration': transliteration,
      'translation': translation,
      'arabic_verse_part': arabicVersePart,
      'arabic_word': arabicWord,
    };
  }
}