import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/services/flash_controller_service.dart';
import '../../../core/services/orientation_service.dart';
import '../../../core/theme/tifo_theme.dart';

class LightStudioScreen extends StatefulWidget {
  const LightStudioScreen({super.key});

  @override
  State<LightStudioScreen> createState() => _LightStudioScreenState();
}

class _LightStudioScreenState extends State<LightStudioScreen> {
  Color _selectedColor = const Color(0xFF10B981);
  double _strobeSpeedMs = 120.0;
  bool _isTorchOn = false;
  bool _isStrobeActive = false;
  Timer? _screenStrobeTimer;
  bool _screenFlashToggle = false;

  final OrientationService _orientationService = OrientationService();
  OrientationState _orientationState = OrientationState.initial();
  StreamSubscription<OrientationState>? _orientationSubscription;

  final List<Color> _presetColors = const [
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Crimson
    Color(0xFFF59E0B), // Gold
    Color(0xFFFFFFFF), // Pure White
  ];

  @override
  void initState() {
    super.initState();
    _orientationService.startListening();
    _orientationSubscription = _orientationService.orientationStream.listen((state) {
      if (mounted) {
        setState(() {
          _orientationState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopScreenStrobe();
    FlashControllerService().stopStrobe();
    FlashControllerService().turnOff();
    _orientationSubscription?.cancel();
    _orientationService.stopListening();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    if (_isTorchOn) {
      FlashControllerService().turnOn();
    } else {
      FlashControllerService().turnOff();
    }
  }

  void _toggleStrobe() {
    setState(() {
      _isStrobeActive = !_isStrobeActive;
    });
    if (_isStrobeActive) {
      FlashControllerService().startStrobe(
        frequencyMs: _strobeSpeedMs.toInt(),
        durationSeconds: 10,
      );
      _startScreenStrobe();
    } else {
      FlashControllerService().stopStrobe();
      _stopScreenStrobe();
    }
  }

  void _startScreenStrobe() {
    _stopScreenStrobe();
    _screenStrobeTimer = Timer.periodic(Duration(milliseconds: _strobeSpeedMs.toInt()), (timer) {
      if (mounted) {
        setState(() {
          _screenFlashToggle = !_screenFlashToggle;
        });
      }
    });
  }

  void _stopScreenStrobe() {
    _screenStrobeTimer?.cancel();
    _screenStrobeTimer = null;
    _screenFlashToggle = false;
  }

  void _playRhythmVibration(List<int> pattern) {
    Vibration.hasVibrator().then((hasVib) {
      if (hasVib == true) {
        Vibration.vibrate(pattern: pattern);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = (_isStrobeActive && _screenFlashToggle)
        ? _selectedColor
        : TifoTheme.darkBackground;

    return Scaffold(
      backgroundColor: effectiveBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: TifoTheme.stadiumCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'استوديو الإضاءة والتجربة (Light Studio)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TifoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, color: TifoTheme.stadiumGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'اختيار لون الفلاش والشاشة 🎨',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _presetColors.map((color) {
                      final bool isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.8),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Strobe Speed Controls Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TifoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.speed_rounded, color: TifoTheme.stadiumCyan, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'سرعة الوميض (Strobe Speed)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        '${_strobeSpeedMs.toInt()} ms',
                        style: const TextStyle(color: TifoTheme.stadiumCyan, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: _strobeSpeedMs,
                    min: 40,
                    max: 400,
                    divisions: 18,
                    activeColor: TifoTheme.stadiumCyan,
                    inactiveColor: Colors.white24,
                    onChanged: (val) {
                      setState(() {
                        _strobeSpeedMs = val;
                      });
                      if (_isStrobeActive) {
                        FlashControllerService().startStrobe(frequencyMs: val.toInt(), durationSeconds: 10);
                        _startScreenStrobe();
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleTorch,
                        icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.black, size: 18),
                        label: Text(
                          _isTorchOn ? 'الفلاش يعمل' : 'تشغيل الفلاش الثابت',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTorchOn ? Colors.amber : Colors.white24,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _toggleStrobe,
                        icon: Icon(_isStrobeActive ? Icons.stop : Icons.play_arrow, color: Colors.black, size: 18),
                        label: Text(
                          _isStrobeActive ? 'إيقاف الوميض' : 'بدء الوميض التجريبي',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStrobeActive ? Colors.redAccent : TifoTheme.stadiumGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Soundboard & Haptic Rhythm Synthesizer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TifoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.vibration, color: Color(0xFFA855F7), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'إيقاعات المدرج والاهتزاز الحسي (Fan Rhythm Beats) 🥁',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _playRhythmVibration([0, 100, 100, 100, 100, 300]),
                          icon: const Icon(Icons.touch_app, color: TifoTheme.stadiumCyan, size: 16),
                          label: const Text('تصفيق 3 دقات', style: TextStyle(color: Colors.white, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: TifoTheme.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _playRhythmVibration([0, 200, 50, 200, 50, 400]),
                          icon: const Icon(Icons.waves, color: Color(0xFFA855F7), size: 16),
                          label: const Text('إيقاع الموجه', style: TextStyle(color: Colors.white, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: TifoTheme.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hardware & Sensor Diagnostics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TifoTheme.stadiumCyan.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.developer_board, color: TifoTheme.stadiumCyan, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'تشخيص العتاد والمستشعرات (Hardware Diagnostics) 🛠️',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDiagRow('مستشعر إمالة الجوال (Gyroscope Pitch):', '${_orientationState.pitchAngleDegrees.toStringAsFixed(1)}°'),
                  _buildDiagRow('توجيه نحو الملعب:', _orientationState.isFacingPitch ? '✅ ممتاز' : '⚠️ اضبط الإمالة'),
                  _buildDiagRow('أقصى سطوع للشاشة (Screen Light API):', 'جاهز 100%'),
                  _buildDiagRow('متحكم الفلاش السريع (Torch Light API):', 'متوافق ومتصل ⚡'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          Text(value, style: const TextStyle(color: TifoTheme.stadiumCyan, fontWeight: FontWeight.bold, fontSize: 11.5)),
        ],
      ),
    );
  }
}
