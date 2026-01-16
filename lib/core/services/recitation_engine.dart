import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class RecitationEngine {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Gemini Setup
  final GenerativeModel _geminiModel = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyCcvdtlEJSE1yPkWYL2eVcUfdbg7vu0Lxg', // Replace with your key
  );

  Future<bool> init() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) => print('Status: $val'),
    );
    return _isInitialized;
  }

  // Live Listening (Uses Google/Apple Cloud STT)
  void listen({required Function(String) onResult}) async {
    if (!_isInitialized) await init();

    await _speechToText.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: "ar_SA", // Set to Arabic
      cancelOnError: true,
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  Future<void> stop() async {
    await _speechToText.stop();
  }

  // Gemini Expert Judge
  Future<Map<String, dynamic>> verifyRecitation(String userText, String targetText) async {
    final prompt = """
    Target Verse: "$targetText"
    User Recited: "$userText"
    Task: Compare the user recitation with the target verse. Ignore small spelling variations.
    Return ONLY JSON: {"is_correct": bool, "accuracy": 0-100, "feedback": "Arabic Text"}
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      return {"is_correct": false, "accuracy": 0, "feedback": "Connection Error"};
    }
  }
}