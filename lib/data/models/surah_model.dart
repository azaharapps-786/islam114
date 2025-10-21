class Surah {
  final int id;
  final String name; // Arabic Name
  final String transliteration; // English Transliteration
  final String translation; // English Translation
  final String assameseName; // NEW: Assamese Name
  final String hindiName;    // NEW: Hindi Name
  final int totalVerses;
  final String revelationType;

  Surah({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.translation,
    required this.assameseName, // NEW
    required this.hindiName,    // NEW
    required this.totalVerses,
    required this.revelationType,
  });

// The fromJson constructor would also need to be updated if you were using an API
}