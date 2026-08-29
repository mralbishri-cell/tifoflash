import 'dart:ui';

enum TifoActionType {
  strobe,
  solidColor,
  wave,
  textDisplay,
  sponsorPopup,
  idle;

  static TifoActionType parse(String? value) {
    switch (value?.toUpperCase()) {
      case 'STROBE':
        return TifoActionType.strobe;
      case 'SOLID_COLOR':
        return TifoActionType.solidColor;
      case 'WAVE':
        return TifoActionType.wave;
      case 'TEXT_DISPLAY':
        return TifoActionType.textDisplay;
      case 'SPONSOR_POPUP':
        return TifoActionType.sponsorPopup;
      default:
        return TifoActionType.idle;
    }
  }
}

enum TargetType {
  sector,
  seat,
  all;

  static TargetType parse(String? value) {
    switch (value?.toUpperCase()) {
      case 'SECTOR':
        return TargetType.sector;
      case 'SEAT':
        return TargetType.seat;
      case 'ALL':
      default:
        return TargetType.all;
    }
  }
}

class SponsorInfo {
  final String title;
  final String imageUrl;
  final String couponCode;
  final String linkUrl;

  const SponsorInfo({
    required this.title,
    required this.imageUrl,
    required this.couponCode,
    required this.linkUrl,
  });

  factory SponsorInfo.fromJson(Map<String, dynamic> json) {
    return SponsorInfo(
      title: json['title'] ?? 'عرض خاص من الراعي الرسمي',
      imageUrl: json['image_url'] ?? '',
      couponCode: json['coupon_code'] ?? 'MATCH2026',
      linkUrl: json['link_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'image_url': imageUrl,
        'coupon_code': couponCode,
        'link_url': linkUrl,
      };
}

class TifoActionPayload {
  final String actionId;
  final int timestamp;
  final TifoActionType type;
  final TargetType targetType;
  final List<String> targetIds;
  final String colorHex;
  final int flashFrequencyMs;
  final int durationSeconds;
  final String textChar;
  final int waveDelayStepMs;
  final SponsorInfo? sponsor;

  const TifoActionPayload({
    required this.actionId,
    required this.timestamp,
    required this.type,
    required this.targetType,
    required this.targetIds,
    required this.colorHex,
    required this.flashFrequencyMs,
    required this.durationSeconds,
    required this.textChar,
    required this.waveDelayStepMs,
    this.sponsor,
  });

  factory TifoActionPayload.fromJson(Map<String, dynamic> json) {
    final payloadMap = (json['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawTargetIds = json['target_ids'];
    List<String> parsedTargetIds = [];
    if (rawTargetIds is List) {
      parsedTargetIds = rawTargetIds.map((e) => e.toString()).toList();
    }

    return TifoActionPayload(
      actionId: json['action_id'] ?? 'act_idle',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      type: TifoActionType.parse(json['type']),
      targetType: TargetType.parse(json['target_type']),
      targetIds: parsedTargetIds,
      colorHex: payloadMap['color_hex'] ?? '#008000',
      flashFrequencyMs: payloadMap['flash_frequency_ms'] ?? 150,
      durationSeconds: payloadMap['duration_seconds'] ?? 10,
      textChar: payloadMap['text_char'] ?? '',
      waveDelayStepMs: payloadMap['wave_delay_step_ms'] ?? 250,
      sponsor: payloadMap['sponsor'] != null
          ? SponsorInfo.fromJson(Map<String, dynamic>.from(payloadMap['sponsor']))
          : null,
    );
  }

  Color get parsedColor {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF008000); // Default stadium green
  }
}
