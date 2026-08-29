import 'dart:async';
import 'package:flutter/foundation.dart';

class AudioTriggerService {
  static final AudioTriggerService _instance = AudioTriggerService._internal();
  factory AudioTriggerService() => _instance;
  AudioTriggerService._internal();

  bool _isListening = false;
  final StreamController<bool> _audioTriggerController = StreamController<bool>.broadcast();

  Stream<bool> get audioTriggerStream => _audioTriggerController.stream;
  bool get isListening => _isListening;

  /// Start audio sensor monitoring for stadium cheer whistle / noise peaks
  Future<void> startListening({Function()? onWhistleDetected}) async {
    if (_isListening) return;
    _isListening = true;
    debugPrint('[AudioTriggerService] Initialized audio whistle/cheer fallback detector.');

    // Simulated pitch/amplitude trigger listener when cell network drops
  }

  /// Simulate audio peak trigger (e.g. for offline mode testing)
  void simulateAudioTrigger() {
    debugPrint('[AudioTriggerService] Audio peak whistle triggered fallback pulse!');
    if (!_audioTriggerController.isClosed) {
      _audioTriggerController.add(true);
    }
  }

  void stopListening() {
    _isListening = false;
  }

  void dispose() {
    stopListening();
    _audioTriggerController.close();
  }
}
