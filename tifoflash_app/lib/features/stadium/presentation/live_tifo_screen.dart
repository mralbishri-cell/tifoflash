import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../../core/models/stadium_sector.dart';
import '../../../core/models/tifo_action_payload.dart';
import '../../../core/services/flash_controller_service.dart';
import '../../../core/services/orientation_service.dart';
import '../../../core/services/screen_light_service.dart';
import '../../../core/services/sync_engine_service.dart';
import '../../../core/theme/tifo_theme.dart';
import 'widgets/chant_lyrics_widget.dart';
import 'widgets/goal_celebration_overlay.dart';
import 'widgets/sponsor_popup_dialog.dart';

class LiveTifoScreen extends StatefulWidget {
  final StadiumSector sector;
  final String seatRow;
  final String seatNumber;
  final bool startInDemo;

  const LiveTifoScreen({
    super.key,
    required this.sector,
    this.seatRow = '',
    this.seatNumber = '',
    this.startInDemo = false,
  });

  @override
  State<LiveTifoScreen> createState() => _LiveTifoScreenState();
}

class _LiveTifoScreenState extends State<LiveTifoScreen> with SingleTickerProviderStateMixin {
  late SyncEngineService _syncEngine;
  late OrientationService _orientationService;

  StreamSubscription<SyncEngineState>? _syncSubscription;
  StreamSubscription<OrientationState>? _orientationSubscription;

  SyncEngineState _syncState = SyncEngineState.initial();
  OrientationState _orientationState = OrientationState.initial();

  late StadiumSector _currentSector;
  late AnimationController _radarController;

  List<SponsorInfo> _activeSponsorsToShow = const [];

  Timer? _screenStrobeTimer;
  bool _screenFlashToggle = false;

  // Demo Simulation Mode (Apple Review Guidelines 4.2 Compliance)
  bool _isDemoModeActive = false;
  Timer? _demoTimer;
  int _demoStep = 0;

  void _startScreenStrobe(int frequencyMs) {
    _stopScreenStrobe();
    final interval = (frequencyMs > 0 ? frequencyMs : 120).clamp(40, 500);
    _screenStrobeTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
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

  void _startDemoSimulation() {
    _stopDemoSimulation();
    setState(() {
      _isDemoModeActive = true;
      _demoStep = 0;
    });
    _runNextDemoStep();
  }

  void _runNextDemoStep() {
    if (!mounted || !_isDemoModeActive) return;

    if (_demoStep == 0) {
      // Step 1: Green Solid Tifo Beacon with Strobe
      setState(() {
        _syncState = const SyncEngineState(
          isConnectedToFirebase: true,
          serverTimeOffsetMs: 0,
          isActionActive: true,
          currentAction: TifoActionPayload(
            actionId: 'demo_1',
            timestamp: 0,
            type: TifoActionType.solidColor,
            targetType: TargetType.all,
            targetIds: [],
            colorHex: '#10B981',
            flashFrequencyMs: 0,
            durationSeconds: 4,
            textChar: '',
            waveDelayStepMs: 0,
          ),
          activeColorHex: '#10B981',
          activeCharDisplay: '',
          statusMessageAr: 'عرض تجريبي: وميض التيفو الأخضر الموحد 🟢',
        );
      });
      ScreenLightService().maximizeBrightness();
      FlashControllerService().turnOn();
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 200);
      });

      _demoStep++;
      _demoTimer = Timer(const Duration(seconds: 4), _runNextDemoStep);
    } else if (_demoStep == 1) {
      // Step 2: Cyan Strobe Pulse
      _startScreenStrobe(100);
      FlashControllerService().startStrobe(frequencyMs: 100, durationSeconds: 4);
      setState(() {
        _syncState = const SyncEngineState(
          isConnectedToFirebase: true,
          serverTimeOffsetMs: 0,
          isActionActive: true,
          currentAction: TifoActionPayload(
            actionId: 'demo_2',
            timestamp: 0,
            type: TifoActionType.strobe,
            targetType: TargetType.all,
            targetIds: [],
            colorHex: '#06B6D4',
            flashFrequencyMs: 100,
            durationSeconds: 4,
            textChar: '',
            waveDelayStepMs: 0,
          ),
          activeColorHex: '#06B6D4',
          activeCharDisplay: '',
          statusMessageAr: 'عرض تجريبي: وميض ستوروب الفلاش السريع ⚡',
        );
      });

      _demoStep++;
      _demoTimer = Timer(const Duration(seconds: 4), _runNextDemoStep);
    } else if (_demoStep == 2) {
      // Step 3: Goal Celebration Gold Fireworks & Vibration
      _stopScreenStrobe();
      FlashControllerService().stopStrobe();
      setState(() {
        _syncState = const SyncEngineState(
          isConnectedToFirebase: true,
          serverTimeOffsetMs: 0,
          isActionActive: true,
          currentAction: TifoActionPayload(
            actionId: 'demo_3',
            timestamp: 0,
            type: TifoActionType.goalCelebration,
            targetType: TargetType.all,
            targetIds: [],
            colorHex: '#FFD700',
            flashFrequencyMs: 150,
            durationSeconds: 5,
            textChar: 'GOAAAL! ⚽ هدف!',
            waveDelayStepMs: 0,
          ),
          activeColorHex: '#FFD700',
          activeCharDisplay: 'GOAAAL! ⚽ هدف!',
          statusMessageAr: 'عرض تجريبي: احتفالية الهدف الذهبي ⚽🏆',
        );
      });
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(pattern: [0, 150, 50, 150, 50, 300]);
      });

      _demoStep++;
      _demoTimer = Timer(const Duration(seconds: 5), _runNextDemoStep);
    } else if (_demoStep == 3) {
      // Step 4: Text Stencil Tifo
      setState(() {
        _syncState = const SyncEngineState(
          isConnectedToFirebase: true,
          serverTimeOffsetMs: 0,
          isActionActive: true,
          currentAction: TifoActionPayload(
            actionId: 'demo_4',
            timestamp: 0,
            type: TifoActionType.textDisplay,
            targetType: TargetType.all,
            targetIds: [],
            colorHex: '#8B5CF6',
            flashFrequencyMs: 0,
            durationSeconds: 4,
            textChar: 'TIFO',
            waveDelayStepMs: 0,
          ),
          activeColorHex: '#8B5CF6',
          activeCharDisplay: 'TIFO',
          statusMessageAr: 'عرض تجريبي: تشكيل حروف التيفو الضوئي 🔤',
        );
      });

      _demoStep++;
      _demoTimer = Timer(const Duration(seconds: 4), _runNextDemoStep);
    } else {
      // Finish Demo
      _stopDemoSimulation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ انتهى العرض التجريبي بنجاح! جاهز للتزامن المباشر'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _stopDemoSimulation() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _stopScreenStrobe();
    FlashControllerService().stopStrobe();
    FlashControllerService().turnOff();
    ScreenLightService().setDimmedStandby();
    if (mounted) {
      setState(() {
        _isDemoModeActive = false;
        _demoStep = 0;
        _syncState = SyncEngineState.initial();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _currentSector = widget.sector;
    _syncEngine = SyncEngineService();
    _orientationService = OrientationService();

    // Smooth Radar Pulse for Standby
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _syncEngine.updateFanPlacement(
      sector: _currentSector,
      seatRow: widget.seatRow,
      seatNumber: widget.seatNumber,
    );
    _syncEngine.initialize();

    _syncSubscription = _syncEngine.stateStream.listen((state) {
      if (_isDemoModeActive) return; // Do not overwrite state while user is testing demo
      if (mounted) {
        setState(() {
          _syncState = state;
          if (state.activeSponsors.isNotEmpty && !state.isActionActive && _activeSponsorsToShow.isEmpty) {
            _activeSponsorsToShow = state.activeSponsors;
            _showSponsorModal(_activeSponsorsToShow);
          } else if (state.isActionActive) {
            _activeSponsorsToShow = const [];
          }
        });

        if (state.isActionActive) {
          // Auto-maximize brightness for active tifo show
          ScreenLightService().maximizeBrightness();

          final actionType = state.currentAction?.type;
          if (actionType == TifoActionType.strobe ||
              actionType == TifoActionType.goalCelebration ||
              actionType == TifoActionType.wave) {
            final freq = state.currentAction?.flashFrequencyMs ?? 120;
            _startScreenStrobe(freq);
          } else {
            _stopScreenStrobe();
          }

          // Rhythmic Haptic Pulse Beats in Fan's Hand
          Vibration.hasVibrator().then((hasVib) {
            if (hasVib == true) {
              Vibration.vibrate(pattern: [0, 150, 50, 150, 50, 300]);
            }
          });
        } else {
          _stopScreenStrobe();
          // AMOLED Battery Saver: Dim brightness during standby idle time
          ScreenLightService().setDimmedStandby();
        }
      }
    });

    _orientationService.startListening();
    _orientationSubscription = _orientationService.orientationStream.listen((oState) {
      if (mounted) {
        setState(() {
          _orientationState = oState;
        });
      }
    });

    if (widget.startInDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDemoSimulation();
      });
    }
  }

  @override
  void dispose() {
    _stopDemoSimulation();
    _stopScreenStrobe();
    _syncSubscription?.cancel();
    _orientationSubscription?.cancel();
    _orientationService.stopListening();
    _radarController.dispose();
    ScreenLightService().restoreBrightness();
    FlashControllerService().stopStrobe();
    super.dispose();
  }

  void _showSponsorModal(List<SponsorInfo> sponsors) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SponsorPopupDialog(
        sponsors: sponsors,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _syncState.isActionActive;
    final TifoActionType? currentType = _syncState.currentAction?.type;

    // Parse the sector-specific activeColorHex from sync state (supports independent per-sector colors)
    Color surfaceColor = const Color(0xFF0A0F1D);
    if (isActive) {
      if (_syncState.activeColorHex != null && _syncState.activeColorHex!.isNotEmpty) {
        try {
          final hex = _syncState.activeColorHex!.replaceAll('#', '');
          if (hex.length == 6) {
            surfaceColor = Color(int.parse('FF$hex', radix: 16));
          } else if (hex.length == 8) {
            surfaceColor = Color(int.parse(hex, radix: 16));
          }
        } catch (_) {
          surfaceColor = _syncState.currentAction?.parsedColor ?? TifoTheme.stadiumGreen;
        }
      } else {
        surfaceColor = _syncState.currentAction?.parsedColor ?? TifoTheme.stadiumGreen;
      }
    }

    // Dynamic flashing & continuous color breathing pulse on phone screen
    Color activeEffectiveColor = surfaceColor;
    if (isActive) {
      if (_screenFlashToggle) {
        activeEffectiveColor = Colors.white;
      } else {
        // Deep, visible radiant color pulse animation (pulses up and down continuously)
        final pulseProgress = (1.0 - (_radarController.value - 0.5).abs() * 2);
        final pulseFactor = 0.30 + (0.70 * pulseProgress);
        final hsl = HSLColor.fromColor(surfaceColor);
        activeEffectiveColor = hsl.withLightness((hsl.lightness * pulseFactor).clamp(0.0, 1.0)).toColor();
      }
    }

    if (isActive && currentType == TifoActionType.goalCelebration) {
      return GoalCelebrationOverlay(
        onClose: () {
          setState(() {
            _syncEngine.simulateAction(const TifoActionPayload(
              actionId: 'stop',
              timestamp: 0,
              type: TifoActionType.idle,
              targetType: TargetType.all,
              targetIds: [],
              colorHex: '#008000',
              flashFrequencyMs: 100,
              durationSeconds: 0,
              textChar: '',
              waveDelayStepMs: 0,
            ));
          });
        },
      );
    }

    final isOptimalAngle = _orientationState.isFacingPitch;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        color: isActive ? activeEffectiveColor : const Color(0xFF030712),
        child: SafeArea(
          child: Stack(
            children: [
              // Peripheral Subtle Edge Aura Indicator
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isOptimalAngle
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 3.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Main Screen Layout (If active: 100% Pure Radiant Light / Letter, If idle: Clean Pass & Radar)
              if (isActive) ...[
                Positioned.fill(
                  child: Center(
                    child: _buildActiveBeaconView(currentType, activeEffectiveColor),
                  ),
                ),
                if (_isDemoModeActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: SafeArea(
                      child: ElevatedButton.icon(
                        onPressed: _stopDemoSimulation,
                        icon: const Icon(Icons.stop_circle, color: Colors.white, size: 16),
                        label: const Text(
                          'إيقاف العرض (Stop Demo)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                Column(
                  children: [
                    // Top Clean Match Pass Bar
                    _buildTopMatchBar(isOptimalAngle, isActive),

                    // Photosensitive Light Sensitivity Safety Warning Pill (Apple Guidelines Compliance)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                          SizedBox(width: 6),
                          Text(
                            '⚠️ تنبيه السلامة: يحتوي هذا الوضع على ومضات ضوئية متكررة (Photosensitive Warning)',
                            style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Center Minimalist Sync Radar
                    _buildCleanRadarStandbyView(),

                    const Spacer(),

                    // Bottom Minimal Status Bar
                    _buildBottomBar(isOptimalAngle, isActive),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Top Clean Match Pass Bar
  Widget _buildTopMatchBar(bool isOptimalAngle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.black.withValues(alpha: 0.5)
              : const Color(0xFF111827).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOptimalAngle
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 15),
              ),
            ),
            const SizedBox(width: 12),

            // Sector & Seat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _currentSector.nameAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.seatRow.isNotEmpty
                        ? 'صف ${widget.seatRow} • مقعد ${widget.seatNumber}'
                        : 'وضع الدخول الحر التلقائي',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF06B6D4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt,
                color: Colors.black,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),

            // Orientation Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOptimalAngle
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOptimalAngle ? const Color(0xFF10B981) : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOptimalAngle ? Icons.check_circle : Icons.screen_rotation,
                    color: isOptimalAngle ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOptimalAngle ? 'موجّه ✨' : 'اضبط الزاوية',
                    style: TextStyle(
                      color: isOptimalAngle ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Center Pure Radiant Beacon View (When Tifo is Active)
  Widget _buildActiveBeaconView(TifoActionType? currentType, Color surfaceColor) {
    if (currentType == TifoActionType.chantLyrics) {
      return ChantLyricsWidget(
        title: _syncState.currentAction?.lyricsTitle ?? 'أهازيج المدرج 🎵',
        lines: _syncState.currentAction?.lyricsLines.isNotEmpty == true
            ? _syncState.currentAction!.lyricsLines
            : [
                'أووووه أووووه يا فريق البطولة 🏆',
                'نحن الجماهير خلفك بالطول والعرض 🔥',
              ],
        primaryColor: surfaceColor == Colors.black ? const Color(0xFF00E5FF) : Colors.white,
      );
    }

    if (currentType == TifoActionType.wave) {
      final waveStyle = _syncState.currentAction?.waveStyle ?? 'RADIAL_RIPPLE';
      return Stack(
        alignment: Alignment.center,
        children: [
          // 3D Depth Radial Animated Pulsing Rings
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              final scale = 1.0 + (_radarController.value * 0.5);
              final opacity = (1.0 - _radarController.value).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        surfaceColor.withValues(alpha: 0.95),
                        waveStyle == 'INFERNO_PULSE'
                            ? Colors.orange.withValues(alpha: 0.8 * opacity)
                            : (waveStyle == 'DIAMOND_SPARKLE'
                                ? Colors.cyanAccent.withValues(alpha: 0.85 * opacity)
                                : const Color(0xFF00E5FF).withValues(alpha: 0.65 * opacity)),
                        Colors.transparent,
                      ],
                      stops: const [0.15, 0.65, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_syncState.activeCharDisplay.isNotEmpty)
            Text(
              _syncState.activeCharDisplay,
              style: const TextStyle(
                fontSize: 200,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
            ),
        ],
      );
    }

    if (_syncState.activeCharDisplay.isNotEmpty) {
      final text = _syncState.activeCharDisplay;
      final isLongMessage = text.length > 1;
      final isLightBg = surfaceColor.computeLuminance() > 0.5;

      if (isLongMessage) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 35,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉 🎁 🏆', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 14),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700),
                    height: 1.35,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Giant High-Contrast Stadium Stencil Character (Zero extra clutter)
      return Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 220,
            fontWeight: FontWeight.w900,
            color: isLightBg ? Colors.black : Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: isLightBg ? Colors.white70 : Colors.black87,
                offset: const Offset(0, 10),
                blurRadius: 30,
              ),
            ],
          ),
        ),
      );
    }

    // 100% Pure Solid Radiant Light (Pure Stadium Pixel - Zero Text / Zero Icons)
    return const SizedBox.expand();
  }

  /// Center Clean Minimalist Sync Radar (When Standby / Idle)
  Widget _buildCleanRadarStandbyView() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        final progress = _radarController.value;
        final waveRadius = 70.0 + progress * 50.0;
        final waveAlpha = (1.0 - progress).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Elegant Clean Radar Pulse
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Expanding Ripple Ring
                  Container(
                    width: waveRadius * 2,
                    height: waveRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: waveAlpha * 0.4),
                        width: 2.0,
                      ),
                    ),
                  ),

                  // Middle Steady Glowing Ring
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.05),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  // Center Solid Emblem Core
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_tethering,
                      color: Color(0xFF10B981),
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Clear Instructions
            const Text(
              'بث التيفو المباشر جاهز ⚡',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _orientationState.statusPromptAr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startDemoSimulation,
              icon: const Icon(Icons.play_circle_fill, color: Colors.black, size: 20),
              label: const Text(
                '✨ تشغيل العرض التجريبي (Start Demo Show)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Bottom Minimal Status Bar
  Widget _buildBottomBar(bool isOptimalAngle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF111827).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 4,
              backgroundColor: Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            Text(
              _syncState.statusMessageAr,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
