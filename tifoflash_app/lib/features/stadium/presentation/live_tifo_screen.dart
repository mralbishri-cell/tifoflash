import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../../core/models/stadium_sector.dart';
import '../../../core/models/tifo_action_payload.dart';
import '../../../core/services/audio_trigger_service.dart';
import '../../../core/services/flash_controller_service.dart';
import '../../../core/services/orientation_service.dart';
import '../../../core/services/screen_light_service.dart';
import '../../../core/services/sync_engine_service.dart';
import '../../../core/theme/tifo_theme.dart';
import 'widgets/orientation_widget.dart';
import 'widgets/sponsor_popup_dialog.dart';

class LiveTifoScreen extends StatefulWidget {
  final StadiumSector sector;
  final String seatRow;
  final String seatNumber;

  const LiveTifoScreen({
    super.key,
    required this.sector,
    this.seatRow = '',
    this.seatNumber = '',
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  SponsorInfo? _activeSponsorToShow;

  @override
  void initState() {
    super.initState();

    _currentSector = widget.sector;
    _syncEngine = SyncEngineService();
    _orientationService = OrientationService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncEngine.updateFanPlacement(
      sector: _currentSector,
      seatRow: widget.seatRow,
      seatNumber: widget.seatNumber,
    );
    _syncEngine.initialize();

    _syncSubscription = _syncEngine.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _syncState = state;
          if (state.activeSponsor != null && !state.isActionActive) {
            _activeSponsorToShow = state.activeSponsor;
            _showSponsorModal(_activeSponsorToShow!);
          }
        });

        if (state.isActionActive) {
          Vibration.hasVibrator().then((hasVib) {
            if (hasVib == true) {
              Vibration.vibrate(duration: 200);
            }
          });
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
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _orientationSubscription?.cancel();
    _orientationService.stopListening();
    _pulseController.dispose();
    ScreenLightService().restoreBrightness();
    FlashControllerService().stopStrobe();
    super.dispose();
  }

  void _onSwitchSector(StadiumSector newSector) {
    setState(() {
      _currentSector = newSector;
    });
    _syncEngine.updateFanPlacement(
      sector: newSector,
      seatRow: widget.seatRow,
      seatNumber: widget.seatNumber,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم الانتقال السلس إلى: ${newSector.nameAr} 🏟️'),
        duration: const Duration(seconds: 1),
        backgroundColor: TifoTheme.stadiumGreen,
      ),
    );
  }

  void _showSponsorModal(SponsorInfo sponsor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SponsorPopupDialog(
        sponsor: sponsor,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _triggerLocalDemoAction(TifoActionType type) {
    final demoPayload = TifoActionPayload(
      actionId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: type,
      targetType: TargetType.all,
      targetIds: [_currentSector.id],
      colorHex: type == TifoActionType.strobe ? '#00E676' : '#FFD700',
      flashFrequencyMs: 150,
      durationSeconds: 6,
      textChar: _currentSector.assignedChar.isNotEmpty ? _currentSector.assignedChar : '★',
      waveDelayStepMs: 200,
      sponsor: type == TifoActionType.sponsorPopup
          ? const SponsorInfo(
              title: 'عرض خاص من الراعي الرسمي - خصم 30%',
              imageUrl: '',
              couponCode: 'MATCH2026',
              linkUrl: 'https://example.com',
            )
          : null,
    );

    _syncEngine.simulateAction(demoPayload);
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _syncState.isActionActive;
    final Color surfaceColor = _syncState.activeColorHex != null
        ? _syncState.currentAction?.parsedColor ?? TifoTheme.stadiumGreen
        : TifoTheme.darkBackground;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: isActive ? surfaceColor : TifoTheme.darkBackground,
        child: SafeArea(
          child: Stack(
            children: [
              // Main Interactive Screen Surface (renders text character or pulsating color)
              Positioned.fill(
                child: Center(
                  child: isActive
                      ? ScaleTransition(
                          scale: _pulseAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_syncState.activeCharDisplay.isNotEmpty) ...[
                                Text(
                                  _syncState.activeCharDisplay,
                                  style: const TextStyle(
                                    fontSize: 160,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 8),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.white60,
                                        blurRadius: 40,
                                        spreadRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.flash_on,
                                    size: 110,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  '⚡ التيفو مفعّل الآن ⚡',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TifoTheme.cardSurface,
                                border: Border.all(color: TifoTheme.stadiumGreen, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: TifoTheme.stadiumGreen.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.wifi_tethering,
                                color: TifoTheme.stadiumGreen,
                                size: 54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _currentSector.nameAr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.seatRow.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'صف: ${widget.seatRow} • مقعد: ${widget.seatNumber}',
                                style: const TextStyle(color: TifoTheme.stadiumCyan, fontSize: 14),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _syncState.statusMessageAr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Orientation Guidance Overlay
              Positioned(
                top: 70,
                left: 16,
                right: 16,
                child: Center(
                  child: OrientationGuidanceWidget(state: _orientationState),
                ),
              ),

              // Top Bar with On-The-Fly Sector Switcher Carousel
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: PresetStadiumData.sectors.length,
                          itemBuilder: (context, index) {
                            final sec = PresetStadiumData.sectors[index];
                            final isSelected = sec.id == _currentSector.id;
                            return GestureDetector(
                              onTap: () => _onSwitchSector(sec),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? TifoTheme.stadiumGreen : Colors.white10,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    sec.nameAr,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Control & Demo Trigger Dock
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'اختبار التفعيل السريع (Local Test Dock):',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTestButton(
                            label: 'Goal Flash',
                            icon: Icons.bolt,
                            color: TifoTheme.stadiumGreen,
                            onTap: () => _triggerLocalDemoAction(TifoActionType.strobe),
                          ),
                          _buildTestButton(
                            label: 'Text Tifo',
                            icon: Icons.font_download,
                            color: TifoTheme.stadiumCyan,
                            onTap: () => _triggerLocalDemoAction(TifoActionType.textDisplay),
                          ),
                          _buildTestButton(
                            label: 'Sponsor',
                            icon: Icons.card_giftcard,
                            color: TifoTheme.stadiumGold,
                            onTap: () => _triggerLocalDemoAction(TifoActionType.sponsorPopup),
                          ),
                          _buildTestButton(
                            label: 'Audio Peak',
                            icon: Icons.mic,
                            color: Colors.purpleAccent,
                            onTap: () => AudioTriggerService().simulateAudioTrigger(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
