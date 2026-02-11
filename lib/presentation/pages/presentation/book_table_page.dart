import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../../core/services/settings_service.dart';

class BookTablePage extends StatelessWidget {
  const BookTablePage({super.key});

  // Hardcoded table of contents with IDs matching your book_content.json
  static const Map<String, dynamic> tableOfContents = {
    "title": "The Harmony of Two Books",
    "subtitle": "Scientific Miracles in the Quran",
    "contents": [
      {
        "section": "Front Matter",
        "pages": [
          {"title": "Introduction: Beyond Coincidence", "page": "vii", "id": "intro"}
        ]
      },
      {
        "section": "Part I: The Architecture of the Cosmos",
        "chapters": [
          {"title": "The Genesis: From Singularity to Primordial Smoke", "page": 3, "id": 1},
          {"title": "The Ever-Expanding Universe", "page": 15, "id": 2},
          {"title": "The Celestial Dance: Orbits and the Solar Apex", "page": 23, "id": 3},
          {"title": "The 'Big Crunch': Cosmic Cycles and the Final Fold", "page": 31, "id": 4}
        ]
      },
      {
        "section": "Part II: The Living Earth and Its Systems",
        "chapters": [
          {"title": "Mountains as Pegs: The Earth's Tectonic Guardians", "page": 41, "id": 5},
          {"title": "The Mystery of Iron: A Gift from the Stars", "page": 51, "id": 6},
          {"title": "The Divided Seas: The Invisible Partition", "page": 59, "id": 7},
          {"title": "Internal Waves: The Turmoil of the Depths", "page": 67, "id": 8},
          {"title": "The Water Cycle: Earth's Circulatory System", "page": 75, "id": 9}
        ]
      },
      {
        "section": "Part III: The Biological Blueprint",
        "chapters": [
          {"title": "The Aquatic Origin: Water as the Essence of Life", "page": 87, "id": 10},
          {"title": "The Universal Duality: The Law of Pairs", "page": 95, "id": 11},
          {"title": "The Miracle of the Bee: Linguistics and Social Order", "page": 103, "id": 12},
          {"title": "Extraterrestrial Life: The Expansive Heavens", "page": 111, "id": 13}
        ]
      },
      {
        "section": "Part IV: The Human Masterpiece",
        "chapters": [
          {"title": "The Embryonic Journey: Miracles in the Womb", "page": 121, "id": 14},
          {"title": "Sex Determination: The Genetic Spark", "page": 133, "id": 15},
          {"title": "The Frontal Lobe: The Seat of Deception", "page": 141, "id": 16},
          {"title": "Pain Receptors: The Skin's Secret", "page": 149, "id": 17}
        ]
      },
      {
        "section": "Part V: The Hidden Realms and Universal Laws",
        "chapters": [
          {"title": "The Subatomic World: Beyond the Atom", "page": 159, "id": 18},
          {"title": "The Divine Signature: The Uniqueness of Fingerprints", "page": 167, "id": 19},
          {"title": "Staged Creation: The Progressive Growth of Life", "page": 175, "id": 20}
        ]
      },
      {
        "section": "Back Matter",
        "pages": [
          {"title": "Conclusion: The Convergence of Reason and Revelation", "page": 183, "id": "conclusion"},
          {"title": "Glossary", "page": 189, "id": "glossary"},
          {"title": "Bibliography", "page": 193, "id": "bibliography"},
          {"title": "Index", "page": 197, "id": "index"},
          {"title": "About the Author", "page": 205, "id": "about"}
        ]
      }
    ]
  };

  int? _safeParsePage(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final double fontScale = settings.fontScale;

    return Scaffold(
      backgroundColor: const Color(0xDDD0F7F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A4D4D),
        centerTitle: true,
        title: Text(
          tableOfContents['title'] as String? ?? 'The Harmony of Two Books',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (20 * fontScale).clamp(18, 24),
          ),
        ),
      ),
      body: _buildContent(fontScale, context),
    );
  }

  Widget _buildContent(double fontScale, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (tableOfContents['contents'] as List<dynamic>?)?.length ?? 0,
      itemBuilder: (ctx, index) {
        final section = (tableOfContents['contents'] as List<dynamic>)[index] as Map<String, dynamic>;
        return _buildSection(section, fontScale, context);
      },
    );
  }

  Widget _buildSection(Map<String, dynamic> section, double fontScale, BuildContext context) {
    final sectionTitle = section['section'] as String?;
    final chapters = section['chapters'] as List<dynamic>?;
    final pages = section['pages'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Text(
              sectionTitle,
              style: TextStyle(
                fontSize: (18 * fontScale).clamp(16, 22),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A4D4D),
              ),
            ),
          ),
        if (chapters != null)
          ...chapters.map<Widget>((chapter) => _buildChapterItem(chapter as Map<String, dynamic>, fontScale, context)).toList(),
        if (pages != null)
          ...pages.map<Widget>((page) => _buildPageItem(page as Map<String, dynamic>, fontScale, context)).toList(),
      ],
    );
  }

  Widget _buildChapterItem(Map<String, dynamic> chapter, double fontScale, BuildContext context) {
    final title = chapter['title'] as String?;
    final page = _safeParsePage(chapter['page']);
    final chapterId = chapter['id']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4D4D).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Haptics.vibrate(HapticsType.selection);
            Navigator.pushNamed(
              context,
              '/bookDetails',
              arguments: {
                'chapterId': chapterId,  // e.g. "5", "14", "intro"
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? 'Untitled Chapter',
                    style: TextStyle(
                      fontSize: (16 * fontScale).clamp(14, 20),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A4D4D),
                    ),
                  ),
                ),
                if (page != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A4D4D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Page $page',
                      style: TextStyle(
                        fontSize: (12 * fontScale).clamp(10, 14),
                        color: const Color(0xFF0A4D4D),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageItem(Map<String, dynamic> pageItem, double fontScale, BuildContext context) {
    final title = pageItem['title'] as String?;
    final pageNumber = _safeParsePage(pageItem['page']);
    final pageId = pageItem['id']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4D4D).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Haptics.vibrate(HapticsType.selection);
            Navigator.pushNamed(
              context,
              '/bookDetails',
              arguments: {
                'chapterId': pageId,  // e.g. "conclusion", "glossary"
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? 'Untitled Page',
                    style: TextStyle(
                      fontSize: (16 * fontScale).clamp(14, 20),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A4D4D),
                    ),
                  ),
                ),
                if (pageNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A4D4D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Page $pageNumber',
                      style: TextStyle(
                        fontSize: (12 * fontScale).clamp(10, 14),
                        color: const Color(0xFF0A4D4D),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}