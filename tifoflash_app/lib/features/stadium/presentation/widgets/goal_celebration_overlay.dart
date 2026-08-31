import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoalCelebrationOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const GoalCelebrationOverlay({super.key, required this.onClose});

  @override
  State<GoalCelebrationOverlay> createState() => _GoalCelebrationOverlayState();
}

class _GoalCelebrationOverlayState extends State<GoalCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  Timer? _autoCloseTimer;
  int _colorIndex = 0;

  final List<Color> _partyColors = [
    const Color(0xFF00E676),
    const Color(0xFFFFD700),
    const Color(0xFFFF1744),
    const Color(0xFF00E5FF),
    const Color(0xFFAA00FF),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Color cycling timer
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (mounted) {
        setState(() {
          _colorIndex = (_colorIndex + 1) % _partyColors.length;
        });
      }
    });

    _autoCloseTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _partyColors[_colorIndex];

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Radial Flash
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  currentColor.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
                radius: 1.2,
              ),
            ),
          ),

          // Main Goal Text Animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '⚽🔥⚽',
                  style: TextStyle(fontSize: 54),
                ),
                const SizedBox(height: 12),
                Text(
                  'GOAL !!!',
                  style: GoogleFonts.outfit(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: currentColor, blurRadius: 30),
                      Shadow(color: currentColor, blurRadius: 60),
                    ],
                  ),
                ),
                Text(
                  'هـــــدف هـــــدف !',
                  style: GoogleFonts.cairo(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: currentColor,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: currentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: currentColor, width: 2),
                  ),
                  child: Text(
                    'احتفال التيفو الضوئي المتزامن 🎉',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}
