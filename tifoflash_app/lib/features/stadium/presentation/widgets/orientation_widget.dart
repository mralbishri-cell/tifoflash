import 'package:flutter/material.dart';
import '../../../../core/services/orientation_service.dart';

class OrientationGuidanceWidget extends StatelessWidget {
  final OrientationState state;

  const OrientationGuidanceWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFacing = state.isFacingPitch;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isFacing
            ? const Color(0xFF00E676).withValues(alpha: 0.15)
            : const Color(0xFFFF9100).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isFacing ? const Color(0xFF00E676) : const Color(0xFFFF9100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isFacing ? const Color(0xFF00E676) : const Color(0xFFFF9100)).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: (state.pitchAngleDegrees - 90) * (3.14159 / 180),
            child: Icon(
              isFacing ? Icons.phone_android : Icons.screen_rotation,
              color: isFacing ? const Color(0xFF00E676) : const Color(0xFFFF9100),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.statusPromptAr,
                style: TextStyle(
                  color: isFacing ? const Color(0xFF00E676) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'زاوية الإمالة: ${state.pitchAngleDegrees.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
