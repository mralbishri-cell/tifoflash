import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

class FlashControllerService {
  static final FlashControllerService _instance = FlashControllerService._internal();
  factory FlashControllerService() => _instance;
  FlashControllerService._internal();

  bool _isTorchAvailable = false;
  bool _isStrobing = false;
  bool _currentFlashState = false;
  Timer? _strobeTimer;
  Timer? _autoOffTimer;

  bool get isStrobing => _isStrobing;
  bool get isTorchAvailable => _isTorchAvailable;

  /// Initialize hardware availability check
  Future<bool> checkAvailability() async {
    if (kIsWeb) {
      _isTorchAvailable = false;
      return false;
    }
    try {
      _isTorchAvailable = await TorchLight.isTorchAvailable();
    } catch (e) {
      debugPrint('[FlashController] Torch availability error: $e');
      _isTorchAvailable = false;
    }
    return _isTorchAvailable;
  }

  /// Turn flashlight ON
  Future<void> turnOn() async {
    if (!_isTorchAvailable) return;
    try {
      if (!_currentFlashState) {
        await TorchLight.enableTorch();
        _currentFlashState = true;
      }
    } catch (e) {
      debugPrint('[FlashController] enableTorch error: $e');
    }
  }

  /// Turn flashlight OFF
  Future<void> turnOff() async {
    if (!_isTorchAvailable) return;
    try {
      if (_currentFlashState) {
        await TorchLight.disableTorch();
        _currentFlashState = false;
      }
    } catch (e) {
      debugPrint('[FlashController] disableTorch error: $e');
    }
  }

  /// Start rapid strobe sequence with specified frequency (ms) and duration (seconds)
  Future<void> startStrobe({required int frequencyMs, required int durationSeconds}) async {
    await stopStrobe(); // Cleanup existing timer

    if (!_isTorchAvailable) {
      debugPrint('[FlashController] Strobe requested but torch not available. Falling back to screen strobe.');
      return;
    }

    _isStrobing = true;
    final intervalMs = frequencyMs.clamp(50, 1000);

    _strobeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (!_isStrobing) {
        timer.cancel();
        return;
      }
      try {
        if (_currentFlashState) {
          await turnOff();
        } else {
          await turnOn();
        }
      } catch (e) {
        debugPrint('[FlashController] Strobe pulse cycle error: $e');
      }
    });

    if (durationSeconds > 0) {
      _autoOffTimer = Timer(Duration(seconds: durationSeconds), () {
        stopStrobe();
      });
    }
  }

  /// Stop strobe sequence and release hardware safely
  Future<void> stopStrobe() async {
    _isStrobing = false;
    _strobeTimer?.cancel();
    _strobeTimer = null;
    _autoOffTimer?.cancel();
    _autoOffTimer = null;
    await turnOff();
  }

  /// Cleanup on service dispose
  Future<void> dispose() async {
    await stopStrobe();
  }
}
