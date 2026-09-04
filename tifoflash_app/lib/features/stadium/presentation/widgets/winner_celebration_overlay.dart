import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

class WinnerCelebrationOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onClose;

  const WinnerCelebrationOverlay({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  State<WinnerCelebrationOverlay> createState() => _WinnerCelebrationOverlayState();
}

class _WinnerCelebrationOverlayState extends State<WinnerCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Haptic pulse celebration pattern
    Vibration.hasVibrator().then((hasVib) {
      if (hasVib == true) {
        Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 400]);
      }
    });

    _autoCloseTimer = Timer(const Duration(seconds: 25), () {
      if (mounted) widget.onClose();
    });
  }

  void _cleanup() {
    _pulseController.dispose();
    _autoCloseTimer?.cancel();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Golden Glow Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.85 + (_pulseController.value * 0.2),
                        colors: [
                          const Color(0xFFFFD700).withValues(alpha: 0.35),
                          const Color(0xFFB45309).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main VIP Winner Card
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🏆 🎁 🚗',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                        ),
                        child: Text(
                          '🌟 مبروك! أنت الفائز في السحب 🌟',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.4,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 16, offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'توجه إلى منصة الفائزين أو راجع مسؤولي الملعب لاستلام جائزتك 🎫',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: widget.onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 10,
                        ),
                        child: Text(
                          'إغلاق والعودة للتيفو ✓',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
