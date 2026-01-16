import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class QuranRecitePage extends StatefulWidget {
  final String language;
  const QuranRecitePage({super.key, required this.language});

  @override
  State<QuranRecitePage> createState() => _QuranRecitePageState();
}

class _QuranRecitePageState extends State<QuranRecitePage> {
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isListening = false;
  bool _isManuallyStopped = true;
  String _statusMessage = "اضغط على الميكروفون للبدء";
  DateTime _lastAlarmTime = DateTime.now();

  final List<String> surahFatiha = [
    "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
    "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
    "الرَّحْمَنِ الرَّحِيمِ",
    "مَالِكِ يَوْمِ الدِّينِ",
    "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينَ",
    "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ",
    "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ"
  ];

  late List<String> targetTokens;
  Map<int, bool> _wordSuccessMap = {};
  List<String> _currentSessionWords = [];

  @override
  void initState() {
    super.initState();
    targetTokens = surahFatiha.join(" ").split(' ');
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint("STT Status: $status");
        if (mounted) {
          setState(() => _isListening = _speechToText.isListening);
        }
        // If it stops but we didn't press 'Stop', force a restart
        if ((status == 'done' || status == 'notListening') && !_isManuallyStopped) {
          _forceRestart();
        }
      },
      onError: (val) {
        debugPrint("STT Error: $val");
        if (!_isManuallyStopped) _forceRestart();
      },
    );
    if (!available) {
      setState(() => _statusMessage = "الميكروفون غير متاح حالياً");
    }
  }

  // Restart with a small delay to allow hardware to release Audio Focus
  void _forceRestart() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_isManuallyStopped) {
        _startListeningProcess();
      }
    });
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll('آ', 'ا').replaceAll('إ', 'ا').replaceAll('أ', 'ا')
        .trim();
  }

  void _toggleListening() async {
    if (_isListening) {
      _isManuallyStopped = true;
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _statusMessage = "تم الإيقاف";
      });
    } else {
      _isManuallyStopped = false;
      _startListeningProcess();
    }
  }

  void _startListeningProcess() async {
    if (!mounted || _isManuallyStopped || _speechToText.isListening) return;

    await _speechToText.listen(
      onResult: (result) => _processSpeechResult(result.recognizedWords),
      localeId: "ar_SA",
      listenMode: ListenMode.confirmation, // confirmation mode is more persistent than dictation
      partialResults: true,
      listenFor: const Duration(hours: 1),
      pauseFor: const Duration(seconds: 20), // Max allowed gap
    );

    setState(() {
      _isListening = true;
      _statusMessage = "جاري الاستماع... صحح خطأك وسيتحول للأخضر";
    });
  }

  void _processSpeechResult(String recognized) {
    if (recognized.isEmpty) return;

    List<String> userWords = recognized.split(' ');
    _currentSessionWords = userWords;
    int currentErrors = 0;

    for (int i = 0; i < userWords.length; i++) {
      String normUser = _normalize(userWords[i]);
      bool foundCorrectly = false;

      for (var target in targetTokens) {
        if (normUser == _normalize(target)) {
          foundCorrectly = true;
          break;
        }
      }
      _wordSuccessMap[i] = foundCorrectly;
      if (!foundCorrectly) currentErrors++;
    }

    if (currentErrors >= 2 && DateTime.now().difference(_lastAlarmTime).inSeconds > 4) {
      _triggerAlarm();
    }

    if (mounted) setState(() {});
  }

  void _triggerAlarm() async {
    _lastAlarmTime = DateTime.now();
    HapticFeedback.vibrate();
    try {
      // Use setPlayerMode to ensure it doesn't take permanent focus
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.play(AssetSource('sounds/error_beep.mp3'), volume: 0.3);
    } catch (e) {
      debugPrint("Sound Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recitation Judge Pro"),
        backgroundColor: const Color(0xFF004D40),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.teal.withOpacity(0.05),
              child: SingleChildScrollView(
                child: Text(
                  surahFatiha.join("\n"),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 20, fontFamily: 'Amiri', height: 1.8),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 2),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                reverse: true,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  direction: Axis.horizontal,
                  textDirection: TextDirection.rtl,
                  spacing: 8,
                  children: List.generate(_currentSessionWords.length, (index) {
                    bool isCorrect = _wordSuccessMap[index] ?? false;
                    return Text(
                      _currentSessionWords[index],
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        fontFamily: 'Amiri',
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          // Status indicator dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(_statusMessage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          FloatingActionButton.large(
            onPressed: _toggleListening,
            backgroundColor: _isListening ? Colors.redAccent : Colors.teal,
            child: Icon(_isListening ? Icons.stop : Icons.mic),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}