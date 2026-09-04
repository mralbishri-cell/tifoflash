import 'dart:ui';

/// Security sanitization utilities for incoming payloads
class PayloadSanitizer {
  /// Validate and sanitize hex color string (e.g. '#00E676')
  static String sanitizeColorHex(String? raw) {
    if (raw == null || raw.isEmpty) return '#008000';
    final cleaned = raw.replaceAll(RegExp(r'[^#0-9A-Fa-f]'), '');
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(cleaned)) return cleaned;
    if (RegExp(r'^#[0-9A-Fa-f]{8}$').hasMatch(cleaned)) return cleaned;
    return '#008000';
  }

  /// Sanitize text input — strip HTML/script tags, limit length
  static String sanitizeText(String? raw, {int maxLength = 50}) {
    if (raw == null || raw.isEmpty) return '';
    // Strip any HTML tags
    final stripped = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    // Limit length
    return stripped.length > maxLength ? stripped.substring(0, maxLength) : stripped;
  }

  /// Validate URL — only allow https:// URLs, reject javascript: and other schemes
  static String sanitizeUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final trimmed = raw.trim();
    // Only allow HTTPS URLs
    if (trimmed.startsWith('https://')) return trimmed;
    // Block everything else (javascript:, data:, http:, ftp:, etc.)
    return '';
  }

  /// Sanitize coupon code — alphanumeric + limited symbols only
  static String sanitizeCouponCode(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '').substring(0, raw.length > 30 ? 30 : raw.length);
  }

  /// Clamp numeric value within safe bounds
  static int clampInt(dynamic raw, int defaultVal, int min, int max) {
    final val = (raw is num) ? raw.toInt() : defaultVal;
    return val.clamp(min, max);
  }
}

enum TifoActionType {
  strobe,
  solidColor,
  wave,
  textDisplay,
  sponsorPopup,
  chantLyrics,
  goalCelebration,
  pixelMatrix,
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
      case 'CHANT_LYRICS':
        return TifoActionType.chantLyrics;
      case 'GOAL_CELEBRATION':
        return TifoActionType.goalCelebration;
      case 'PIXEL_MATRIX':
        return TifoActionType.pixelMatrix;
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

enum HardwareTarget {
  both,
  screenOnly,
  ledOnly;

  static HardwareTarget parse(String? value) {
    switch (value?.toUpperCase()) {
      case 'SCREEN_ONLY':
        return HardwareTarget.screenOnly;
      case 'LED_ONLY':
      case 'FLASH_ONLY':
        return HardwareTarget.ledOnly;
      case 'BOTH':
      default:
        return HardwareTarget.both;
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
      title: PayloadSanitizer.sanitizeText(json['title'] as String?, maxLength: 100) 
             .isEmpty ? 'عرض خاص من الراعي الرسمي' 
             : PayloadSanitizer.sanitizeText(json['title'] as String?, maxLength: 100),
      imageUrl: PayloadSanitizer.sanitizeUrl(json['image_url'] as String?),
      couponCode: PayloadSanitizer.sanitizeCouponCode(json['coupon_code'] as String?),
      linkUrl: PayloadSanitizer.sanitizeUrl(json['link_url'] as String?),
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
  final String waveDirection;
  final String waveStyle;
  final String waveTempo;
  final List<SponsorInfo> sponsors;
  final String lyricsTitle;
  final List<String> lyricsLines;
  final Map<String, dynamic>? pixelMatrixMap;
  final Map<String, String>? sectorColors;
  final String targetRowFilter;
  final HardwareTarget hardwareTarget;

  SponsorInfo? get sponsor => sponsors.isNotEmpty ? sponsors.first : null;

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
    this.waveDirection = 'L2R',
    this.waveStyle = 'RADIAL_RIPPLE',
    this.waveTempo = 'SMOOTH',
    this.sponsors = const [],
    this.lyricsTitle = '',
    this.lyricsLines = const [],
    this.pixelMatrixMap,
    this.sectorColors,
    this.targetRowFilter = 'ALL',
    this.hardwareTarget = HardwareTarget.both,
  });

  factory TifoActionPayload.fromJson(Map<String, dynamic> json) {
    final payloadMap = (json['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawTargetIds = json['target_ids'];
    List<String> parsedTargetIds = [];
    if (rawTargetIds is List) {
      parsedTargetIds = rawTargetIds.map((e) => e.toString()).toList();
    }

    final rawLyrics = payloadMap['lyrics_lines'];
    List<String> parsedLyrics = [];
    if (rawLyrics is List) {
      parsedLyrics = rawLyrics.map((e) => e.toString()).toList();
    }

    Map<String, String>? parsedSectorColors;
    if (payloadMap['sector_colors'] is Map) {
      parsedSectorColors = {};
      (payloadMap['sector_colors'] as Map).forEach((key, val) {
        if (key != null && val != null) {
          parsedSectorColors![key.toString()] = PayloadSanitizer.sanitizeColorHex(val.toString());
        }
      });
    }

    // Parse multi-sponsor list or single sponsor (with backward compatibility)
    List<SponsorInfo> parsedSponsors = [];
    if (payloadMap['sponsors'] is List) {
      final list = payloadMap['sponsors'] as List;
      for (final item in list) {
        if (item is Map) {
          parsedSponsors.add(SponsorInfo.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (payloadMap['sponsor'] != null && payloadMap['sponsor'] is Map) {
      parsedSponsors.add(SponsorInfo.fromJson(Map<String, dynamic>.from(payloadMap['sponsor'])));
    }

    final rawHardware = payloadMap['hardware_target'] ?? json['hardware_target'];

    return TifoActionPayload(
      actionId: PayloadSanitizer.sanitizeText(json['action_id'] as String?, maxLength: 64)
               .isEmpty ? 'act_idle'
               : PayloadSanitizer.sanitizeText(json['action_id'] as String?, maxLength: 64),
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      type: TifoActionType.parse(json['type']),
      targetType: TargetType.parse(json['target_type']),
      targetIds: parsedTargetIds,
      colorHex: PayloadSanitizer.sanitizeColorHex(payloadMap['color_hex'] as String?),
      flashFrequencyMs: PayloadSanitizer.clampInt(payloadMap['flash_frequency_ms'], 150, 80, 1000),
      durationSeconds: PayloadSanitizer.clampInt(payloadMap['duration_seconds'], 10, 0, 300),
      textChar: PayloadSanitizer.sanitizeText(payloadMap['text_char'] as String?, maxLength: 200),
      waveDelayStepMs: PayloadSanitizer.clampInt(payloadMap['wave_delay_step_ms'], 250, 40, 2000),
      waveDirection: payloadMap['wave_direction']?.toString() ?? 'L2R',
      waveStyle: payloadMap['wave_style']?.toString() ?? 'RADIAL_RIPPLE',
      waveTempo: payloadMap['wave_tempo']?.toString() ?? 'SMOOTH',
      sponsors: parsedSponsors,
      lyricsTitle: PayloadSanitizer.sanitizeText(payloadMap['lyrics_title'] as String?, maxLength: 100),
      lyricsLines: parsedLyrics.map((l) => PayloadSanitizer.sanitizeText(l, maxLength: 200)).toList(),
      pixelMatrixMap: payloadMap['pixel_matrix'] != null
          ? Map<String, dynamic>.from(payloadMap['pixel_matrix'])
          : null,
      sectorColors: parsedSectorColors,
      targetRowFilter: payloadMap['target_row_filter']?.toString() ?? 'ALL',
      hardwareTarget: HardwareTarget.parse(rawHardware?.toString()),
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

