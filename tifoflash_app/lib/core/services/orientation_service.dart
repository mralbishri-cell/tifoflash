import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class OrientationState {
  final double pitchAngleDegrees; // Vertical tilt angle (0° = flat table, 90° = vertical upright)
  final double rollAngleDegrees;  // Horizontal roll angle
  final bool isFacingPitch;       // True if device pitch is raised between ~50° and ~110°
  final String statusPromptAr;    // User guidance message in Arabic

  const OrientationState({
    required this.pitchAngleDegrees,
    required this.rollAngleDegrees,
    required this.isFacingPitch,
    required this.statusPromptAr,
  });

  factory OrientationState.initial() => const OrientationState(
        pitchAngleDegrees: 0,
        rollAngleDegrees: 0,
        isFacingPitch: false,
        statusPromptAr: 'ارفَع هاتفك للأعلى ووجّهه نحو الملعب',
      );
}

class OrientationService {
  static final OrientationService _instance = OrientationService._internal();
  factory OrientationService() => _instance;
  OrientationService._internal();

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  final StreamController<OrientationState> _controller = StreamController<OrientationState>.broadcast();

  Stream<OrientationState> get orientationStream => _controller.stream;
  OrientationState _currentState = OrientationState.initial();
  OrientationState get currentState => _currentState;
  bool _lastFacingState = false;

  void startListening() {
    if (kIsWeb) return;
    _accelSubscription?.cancel();

    _accelSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((AccelerometerEvent event) {
      // Calculate pitch & roll from gravity vector
      // event.x, event.y, event.z in m/s^2
      final double ax = event.x;
      final double ay = event.y;
      final double az = event.z;

      // Pitch is tilt backward/forward: atan2(ay, sqrt(ax^2 + az^2))
      final double pitchRad = math.atan2(ay, math.sqrt(ax * ax + az * az));
      final double pitchDeg = (pitchRad * (180 / math.pi)).abs();

      // Roll is tilt left/right
      final double rollRad = math.atan2(ax, math.sqrt(ay * ay + az * az));
      final double rollDeg = rollRad * (180 / math.pi);

      // Facing pitch condition: phone held upright & tilted toward field
      final bool isFacing = pitchDeg >= 45.0 && pitchDeg <= 115.0;

      // Haptic confirmation trigger when reaching target angle
      if (isFacing && !_lastFacingState) {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}
      }
      _lastFacingState = isFacing;

      String prompt = 'وجه هاتفك نحو الملعب';
      if (isFacing) {
        prompt = 'موضع ممتاز! الهاتف موجّه للملعب ✨';
      } else if (pitchDeg < 45.0) {
        prompt = 'ارفَع هاتفك للأعلى باتجاه الملعب ⬆️';
      } else {
        prompt = 'عدّل زاوية الإمالة لتصبح مواجهة للملعب 🔄';
      }

      _currentState = OrientationState(
        pitchAngleDegrees: pitchDeg,
        rollAngleDegrees: rollDeg,
        isFacingPitch: isFacing,
        statusPromptAr: prompt,
      );

      if (!_controller.isClosed) {
        _controller.add(_currentState);
      }
    }, onError: (e) {
      debugPrint('[OrientationService] Sensor stream error: $e');
    });
  }

  void stopListening() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  void dispose() {
    stopListening();
    _controller.close();
  }
}
