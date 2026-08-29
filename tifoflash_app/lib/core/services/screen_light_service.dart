import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ScreenLightService {
  static final ScreenLightService _instance = ScreenLightService._internal();
  factory ScreenLightService() => _instance;
  ScreenLightService._internal();

  double? _originalBrightness;
  bool _isMaximized = false;

  bool get isMaximized => _isMaximized;

  /// Store baseline system screen brightness
  Future<void> initBrightness() async {
    if (kIsWeb) return;
    try {
      _originalBrightness = await ScreenBrightness().application;
    } catch (e) {
      debugPrint('[ScreenLightService] Failed to read current brightness: $e');
      _originalBrightness = 0.7; // default fallback
    }
  }

  /// Maximize screen brightness for full stadium illumination
  Future<void> maximizeBrightness() async {
    if (kIsWeb) return;
    try {
      if (_originalBrightness == null) {
        await initBrightness();
      }
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
      _isMaximized = true;
    } catch (e) {
      debugPrint('[ScreenLightService] Failed to maximize brightness: $e');
    }
  }

  /// Restore pre-tifo user brightness level
  Future<void> restoreBrightness() async {
    if (kIsWeb) return;
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setApplicationScreenBrightness(_originalBrightness!);
      } else {
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
      _isMaximized = false;
    } catch (e) {
      debugPrint('[ScreenLightService] Failed to restore brightness: $e');
    }
  }
}
