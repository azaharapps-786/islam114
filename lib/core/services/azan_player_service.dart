// lib/core/services/azan_player_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AzanPlayerService {
  static final AzanPlayerService _instance = AzanPlayerService._internal();
  factory AzanPlayerService() => _instance;
  AzanPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAzan({String prayerName = ''}) async {
    try {
      // If already playing, stop first
      if (_isPlaying) {
        await stopAzan();
      }

      // FIXED: Remove 'assets/' prefix when using AssetSource
      // AssetSource automatically adds 'assets/' to the path
      String azanFile = 'audio/azan.mp3';

      debugPrint('Attempting to play Azan from: $azanFile');

      await _audioPlayer.play(AssetSource(azanFile));
      _isPlaying = true;

      // Listen to player state
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          _isPlaying = false;
          debugPrint('Azan playback completed or stopped');
        }
      });

      debugPrint('Azan playing successfully');
    } catch (e) {
      debugPrint('Error playing Azan: $e');
      _isPlaying = false;
    }
  }

  Future<void> stopAzan() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('Azan stopped successfully');
    } catch (e) {
      debugPrint('Error stopping Azan: $e');
    }
  }

  Future<void> pauseAzan() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        debugPrint('Azan paused successfully');
      }
    } catch (e) {
      debugPrint('Error pausing Azan: $e');
    }
  }

  Future<void> resumeAzan() async {
    try {
      await _audioPlayer.resume();
      debugPrint('Azan resumed successfully');
    } catch (e) {
      debugPrint('Error resuming Azan: $e');
    }
  }

  // Add this method to check if the audio file exists
  Future<bool> doesAzanFileExist() async {
    try {
      debugPrint('Checking if Azan file exists...');
      // Try to load the asset to see if it exists
      await _audioPlayer.setSource(AssetSource('audio/azan.mp3'));
      debugPrint('Azan file exists');
      return true;
    } catch (e) {
      debugPrint('Azan file does not exist: $e');
      return false;
    }
  }

  // Add this method to toggle play/pause
  Future<void> toggleAzan() async {
    if (_isPlaying) {
      await pauseAzan();
    } else {
      await playAzan();
    }
  }
}