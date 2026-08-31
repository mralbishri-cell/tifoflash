import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChantLyricsWidget extends StatefulWidget {
  final String title;
  final List<String> lines;
  final Color primaryColor;

  const ChantLyricsWidget({
    super.key,
    required this.title,
    required this.lines,
    this.primaryColor = const Color(0xFF00E676),
  });

  @override
  State<ChantLyricsWidget> createState() => _ChantLyricsWidgetState();
}

class _ChantLyricsWidgetState extends State<ChantLyricsWidget> {
  int _activeLineIndex = 0;
  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();
    _startLyricsAnimation();
  }

  void _startLyricsAnimation() {
    if (widget.lines.isEmpty) return;
    _lineTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _activeLineIndex = (_activeLineIndex + 1) % widget.lines.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq, color: widget.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.title.isNotEmpty ? widget.title : 'أهازيج المدرج الحية 🎵',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Lyric Line
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_activeLineIndex),
              child: Text(
                widget.lines[_activeLineIndex],
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  height: 1.3,
                  shadows: [
                    Shadow(
                      color: widget.primaryColor.withValues(alpha: 0.8),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.lines.length, (index) {
              final isActive = index == _activeLineIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? widget.primaryColor : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
