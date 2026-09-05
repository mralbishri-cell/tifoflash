import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:vibration/vibration.dart';

import '../models/stadium_sector.dart';
import '../models/tifo_action_payload.dart';
import '../utils/stadium_seat_stencil.dart';
import 'flash_controller_service.dart';
import 'screen_light_service.dart';

class ActiveMatchInfo {
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final String stadiumName;
  final String statusText;
  final bool isLive;

  const ActiveMatchInfo({
    this.homeTeam = 'الهلال',
    this.awayTeam = 'النصر',
    this.homeLogo = '⚽',
    this.awayLogo = '🏆',
    this.stadiumName = 'استاد جامعة الملك سعود (الأول بارك)',
    this.statusText = 'مباشر الان 🔥',
    this.isLive = true,
  });

  factory ActiveMatchInfo.fromMap(Map<dynamic, dynamic> map) {
    return ActiveMatchInfo(
      homeTeam: (map['home_team'] ?? map['homeTeam'] ?? 'الهلال').toString().trim(),
      awayTeam: (map['away_team'] ?? map['awayTeam'] ?? '').toString().trim(),
      homeLogo: (map['home_logo'] ?? map['homeLogo'] ?? '⚽').toString().trim(),
      awayLogo: (map['away_logo'] ?? map['awayLogo'] ?? '').toString().trim(),
      stadiumName: (map['stadium_name'] ?? map['stadiumName'] ?? 'استاد جامعة الملك سعود (الأول بارك)').toString().trim(),
      statusText: (map['status_text'] ?? map['statusText'] ?? 'مباشر الان 🔥').toString().trim(),
      isLive: map['is_live'] == true || map['isLive'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveMatchInfo &&
          runtimeType == other.runtimeType &&
          homeTeam == other.homeTeam &&
          awayTeam == other.awayTeam &&
          homeLogo == other.homeLogo &&
          awayLogo == other.awayLogo &&
          stadiumName == other.stadiumName &&
          statusText == other.statusText &&
          isLive == other.isLive;

  @override
  int get hashCode =>
      homeTeam.hashCode ^
      awayTeam.hashCode ^
      homeLogo.hashCode ^
      awayLogo.hashCode ^
      stadiumName.hashCode ^
      statusText.hashCode ^
      isLive.hashCode;
}

class SyncEngineState {
  final bool isConnectedToFirebase;
  final int serverTimeOffsetMs;
  final TifoActionPayload? currentAction;
  final bool isActionActive;
  final String activeCharDisplay;
  final String? activeColorHex;
  final SponsorInfo? activeSponsor;
  final String statusMessageAr;
  final ActiveMatchInfo activeMatch;

  List<SponsorInfo> get activeSponsors => currentAction?.sponsors.isNotEmpty == true 
      ? currentAction!.sponsors 
      : (activeSponsor != null ? [activeSponsor!] : const []);

  const SyncEngineState({
    required this.isConnectedToFirebase,
    required this.serverTimeOffsetMs,
    this.currentAction,
    required this.isActionActive,
    required this.activeCharDisplay,
    this.activeColorHex,
    this.activeSponsor,
    required this.statusMessageAr,
    this.activeMatch = const ActiveMatchInfo(),
  });

  factory SyncEngineState.initial() => const SyncEngineState(
        isConnectedToFirebase: false,
        serverTimeOffsetMs: 0,
        currentAction: null,
        isActionActive: false,
        activeCharDisplay: '',
        activeColorHex: null,
        activeSponsor: null,
        statusMessageAr: 'جاري الاتصال بالنظام المباشر للملعب...',
        activeMatch: ActiveMatchInfo(),
      );

  SyncEngineState copyWith({
    bool? isConnectedToFirebase,
    int? serverTimeOffsetMs,
    TifoActionPayload? currentAction,
    bool? isActionActive,
    String? activeCharDisplay,
    String? activeColorHex,
    SponsorInfo? activeSponsor,
    String? statusMessageAr,
    ActiveMatchInfo? activeMatch,
  }) {
    return SyncEngineState(
      isConnectedToFirebase: isConnectedToFirebase ?? this.isConnectedToFirebase,
      serverTimeOffsetMs: serverTimeOffsetMs ?? this.serverTimeOffsetMs,
      currentAction: currentAction ?? this.currentAction,
      isActionActive: isActionActive ?? this.isActionActive,
      activeCharDisplay: activeCharDisplay ?? this.activeCharDisplay,
      activeColorHex: activeColorHex ?? this.activeColorHex,
      activeSponsor: activeSponsor ?? this.activeSponsor,
      statusMessageAr: statusMessageAr ?? this.statusMessageAr,
      activeMatch: activeMatch ?? this.activeMatch,
    );
  }
}

class SyncEngineService {
  static final SyncEngineService _instance = SyncEngineService._internal();
  factory SyncEngineService() => _instance;
  SyncEngineService._internal();

  final _stateController = StreamController<SyncEngineState>.broadcast();
  Stream<SyncEngineState> get stateStream => _stateController.stream;

  SyncEngineState _state = SyncEngineState.initial();
  SyncEngineState get state => _state;

  String _matchId = 'match_2026_final';
  StadiumSector _selectedSector = PresetStadiumData.sectors.first;
  String _seatRow = '';
  String _seatNumber = '';
  final String _deviceId = _generateDeviceId();

  bool _disposed = false;
  bool _isInitialized = false;

  DatabaseReference? _liveActionRef;
  DatabaseReference? _presenceRef;
  DatabaseReference? _offsetRef;
  StreamSubscription<DatabaseEvent>? _actionSubscription;
  StreamSubscription<DatabaseEvent>? _offsetSubscription;
  StreamSubscription<DatabaseEvent>? _activeInfoSubscription;
  Timer? _actionDurationTimer;
  Timer? _waveInitialTimer;
  Timer? _waveCycleTimer;
  Timer? _wavePulseOffTimer;
  Timer? _httpPollTimer;
  String _lastHandledActionId = '';
  int _lastHandledTimestamp = 0;
  int _httpPollBackoffMs = 3000; // Start at 3 seconds, increase on errors
  static const int _httpPollBaseMs = 3000;
  static const int _httpPollMaxMs = 15000;

  static String _generateDeviceId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(8, (_) => rng.nextInt(256));
    return 'dev_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  void updateFanPlacement({
    required StadiumSector sector,
    String seatRow = '',
    String seatNumber = '',
  }) {
    _selectedSector = sector;
    _seatRow = seatRow;
    _seatNumber = seatNumber;
    _registerDevicePresence();
    debugPrint('[SyncEngine] Fan placement updated: Sector=${sector.id}, Row=$seatRow, Seat=$seatNumber, Device=$_deviceId');
  }

  Timer? _presenceHeartbeatTimer;

  void _registerDevicePresence() {
    final payload = {
      'device_id': _deviceId,
      'sector_id': _selectedSector.id,
      'sector_name': _selectedSector.nameAr,
      'seat_row': _seatRow,
      'seat_number': _seatNumber,
      'joined_at': ServerValue.timestamp,
    };

    // 1. Firebase SDK WebSocket
    try {
      if (_presenceRef != null) {
        _presenceRef?.set(payload);
        _presenceRef?.onDisconnect().remove();
      }
    } catch (e) {
      debugPrint('[SyncEngine] Presence SDK write notice: $e');
    }

    // 2. HTTP REST Direct Backup & Heartbeat (ensures 100% presence registration across all mobile browsers)
    _sendRestPresence();
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_disposed) {
        _sendRestPresence();
      }
    });
  }

  void _sendRestPresence() async {
    try {
      final encodedMatchId = Uri.encodeComponent(_matchId);
      final encodedDeviceId = Uri.encodeComponent(_deviceId);
      final url = Uri.parse('https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app/matches/$encodedMatchId/active_devices/$encodedDeviceId.json');
      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'device_id': _deviceId,
          'sector_id': _selectedSector.id,
          'sector_name': _selectedSector.nameAr,
          'seat_row': _seatRow,
          'seat_number': _seatNumber,
          'joined_at': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 2));
    } catch (e) {
      // Silent network retry
    }
  }

  void initialize({String matchId = 'match_2026_final'}) {
    // [STABILITY FIX] Guard against duplicate initialization
    if (_isInitialized) {
      debugPrint('[SyncEngine] Already initialized. Skipping duplicate init.');
      return;
    }

    final sanitizedMatchId = matchId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (sanitizedMatchId.isEmpty || sanitizedMatchId.length > 50) {
      debugPrint('[SyncEngine] Invalid matchId rejected: $matchId');
      return;
    }
    _matchId = sanitizedMatchId;
    _isInitialized = true;
    FlashControllerService().checkAvailability();

    try {
      FirebaseDatabase db;
      try {
        db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app',
        );
      } catch (_) {
        db = FirebaseDatabase.instance;
      }
      
      _offsetRef = db.ref('/.info/serverTimeOffset');
      _offsetSubscription = _offsetRef?.onValue.listen((event) {
        final offset = (event.snapshot.value as num?)?.toInt() ?? 0;
        _updateState(_state.copyWith(
          isConnectedToFirebase: true,
          serverTimeOffsetMs: offset,
          statusMessageAr: 'متصل بشبكة التيفو التزامنية 🟢',
        ));
      });

      _presenceRef = db.ref('/matches/$_matchId/active_devices/$_deviceId');
      _registerDevicePresence();

      _liveActionRef = db.ref('/matches/$_matchId/live_action');
      _actionSubscription = _liveActionRef?.onValue.listen((event) {
        if (event.snapshot.value == null) return;
        try {
          final raw = event.snapshot.value;
          if (raw is! Map) {
            debugPrint('[SyncEngine] Unexpected RTDB value type: ${raw.runtimeType}');
            return;
          }
          final dataMap = Map<String, dynamic>.from(raw);
          final actionId = dataMap['action_id']?.toString() ?? '';
          final timestamp = (dataMap['timestamp'] as num?)?.toInt() ?? 0;
          if (actionId.isNotEmpty && (actionId != _lastHandledActionId || timestamp != _lastHandledTimestamp)) {
            _lastHandledActionId = actionId;
            _lastHandledTimestamp = timestamp;
            final action = TifoActionPayload.fromJson(dataMap);
            _handleIncomingAction(action);
          }
        } catch (e) {
          debugPrint('[SyncEngine] Error parsing live action: $e');
        }
      }, onError: (err) {
        debugPrint('[SyncEngine] WebSocket error: $err');
      });

      // Active Match Info Listener (Synced with Admin Dashboard)
      _activeInfoSubscription?.cancel();
      _activeInfoSubscription = db.ref('/matches/$_matchId/active_info').onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          try {
            final matchMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
            final info = ActiveMatchInfo.fromMap(matchMap);
            _updateState(_state.copyWith(activeMatch: info));
          } catch (e) {
            debugPrint('[SyncEngine] Error parsing active match info: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('[SyncEngine] Firebase init error: $e');
    }

    _fetchActiveMatchInfoHttp();
    _startHttpPolling();
  }

  Future<void> _fetchActiveMatchInfoHttp() async {
    try {
      final encodedMatchId = Uri.encodeComponent(_matchId);
      final url = Uri.parse('https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app/matches/$encodedMatchId/active_info.json');
      final res = await http.get(url).timeout(const Duration(milliseconds: 3000));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = json.decode(res.body);
        if (decoded is Map) {
          final info = ActiveMatchInfo.fromMap(decoded);
          if (info != _state.activeMatch) {
            _updateState(_state.copyWith(activeMatch: info));
            debugPrint('[SyncEngine] Synced match info: ${info.homeTeam} (${info.homeLogo}) vs ${info.awayTeam} (${info.awayLogo})');
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncEngine] HTTP active_info fetch notice: $e');
    }
  }

  void _startHttpPolling() {
    _httpPollTimer?.cancel();
    _httpPollBackoffMs = _httpPollBaseMs;

    void scheduleNextPoll() {
      if (_disposed) return;
      _httpPollTimer = Timer(Duration(milliseconds: _httpPollBackoffMs), () async {
        if (_disposed) return;
        _fetchActiveMatchInfoHttp();
        try {
          final encodedMatchId = Uri.encodeComponent(_matchId);
          final url = Uri.parse('https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app/matches/$encodedMatchId/live_action.json');
          final response = await http.get(url).timeout(const Duration(milliseconds: 2500));
          // Reject suspiciously large payloads (>64KB) to prevent memory exhaustion
          if (response.contentLength != null && response.contentLength! > 65536) {
            debugPrint('[SyncEngine] HTTP poll payload too large (${response.contentLength} bytes). Skipping.');
            scheduleNextPoll();
            return;
          }
          if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null' && response.body.length <= 65536) {
            final decoded = json.decode(response.body);
            if (decoded is! Map) {
              scheduleNextPoll();
              return;
            }
            final dataMap = Map<String, dynamic>.from(decoded);
            final actionId = dataMap['action_id']?.toString() ?? '';
            final timestamp = (dataMap['timestamp'] as num?)?.toInt() ?? 0;

            if (actionId.isNotEmpty && (actionId != _lastHandledActionId || timestamp != _lastHandledTimestamp)) {
              _lastHandledActionId = actionId;
              _lastHandledTimestamp = timestamp;

              // Filter out stale/expired actions from previous test sessions upon app startup
              final nowMs = DateTime.now().millisecondsSinceEpoch + _state.serverTimeOffsetMs;
              final ageMs = nowMs - timestamp;
              final payloadMap = (dataMap['payload'] as Map?)?.cast<String, dynamic>() ?? {};
              final durationSec = (payloadMap['duration_seconds'] as num?)?.toInt() ?? 30;
              final maxAllowedAgeMs = (durationSec > 0 ? durationSec : 45) * 1000;

              if (timestamp > 0 && ageMs > maxAllowedAgeMs) {
                debugPrint('[SyncEngine] Stale action ($actionId) ignored. Age: ${ageMs}ms > Max: ${maxAllowedAgeMs}ms');
                scheduleNextPoll();
                return;
              }

              final action = TifoActionPayload.fromJson(dataMap);
              _handleIncomingAction(action);
            }

            if (!_state.isConnectedToFirebase) {
              _updateState(_state.copyWith(
                isConnectedToFirebase: true,
                statusMessageAr: 'متصل بشبكة التيفو التزامنية 🟢',
              ));
            }

            // [STABILITY FIX] Reset backoff on success
            _httpPollBackoffMs = _httpPollBaseMs;
          }
        } catch (e) {
          // [STABILITY FIX] Exponential backoff on failure
          _httpPollBackoffMs = (_httpPollBackoffMs * 1.5).toInt().clamp(_httpPollBaseMs, _httpPollMaxMs);
          debugPrint('[SyncEngine] HTTP poll error, backoff: ${_httpPollBackoffMs}ms');
        }
        scheduleNextPoll();
      });
    }

    scheduleNextPoll();
  }

  bool isFanTargeted(TifoActionPayload action) {
    // 1. Row-level filter check (applies across all targets if row is specified)
    if (action.targetRowFilter != 'ALL' && _seatRow.isNotEmpty) {
      final row = int.tryParse(_seatRow) ?? 1;
      if (action.targetRowFilter == 'EVEN' && row % 2 != 0) return false;
      if (action.targetRowFilter == 'ODD' && row % 2 == 0) return false;
      if (action.targetRowFilter == 'LOWER' && row > 15) return false;
      if (action.targetRowFilter == 'UPPER' && row <= 15) return false;
      if (action.targetRowFilter.startsWith('ROW_')) {
        final targetRow = action.targetRowFilter.replaceFirst('ROW_', '');
        if (_seatRow != targetRow) return false;
      }
    }

    // 2. Target type and ID check
    if (action.targetType == TargetType.all) return true;
    if (action.targetIds.isEmpty || action.targetIds.contains('ALL')) return true;

    if (action.targetType == TargetType.sector) {
      return action.targetIds.contains(_selectedSector.id) ||
          action.targetIds.contains(_selectedSector.standGroup.toUpperCase()) ||
          action.targetIds.any((id) => id.contains(_selectedSector.id) || _selectedSector.id.contains(id));
    }

    if (action.targetType == TargetType.seat) {
      final userSeatId = '${_selectedSector.id}_R${_seatRow}_S$_seatNumber';
      return action.targetIds.contains(userSeatId) ||
          action.targetIds.contains(_deviceId) ||
          action.targetIds.contains(_selectedSector.id);
    }

    return true;
  }

  void _handleIncomingAction(TifoActionPayload action) {
    debugPrint('[SyncEngine] Received action payload: ${action.type} (ID: ${action.actionId}, Hardware: ${action.hardwareTarget})');

    if (action.type == TifoActionType.idle) {
      _stopCurrentAction();
      return;
    }

    if (!isFanTargeted(action)) {
      debugPrint('[SyncEngine] Fan sector (${_selectedSector.id}) not targeted by this action. Setting to idle standby.');
      _stopCurrentAction();
      return;
    }

    // Specialized Traveling Wave Engine (طواف الصاعقة وموجات المدرج 360°)
    if (action.type == TifoActionType.wave) {
      _handleWaveAction(action);
      return;
    }

    _executeAction(action);
  }

  /// Specialized periodic orbital wave crest processor
  void _handleWaveAction(TifoActionPayload action) {
    _waveInitialTimer?.cancel();
    _waveCycleTimer?.cancel();
    _wavePulseOffTimer?.cancel();
    _actionDurationTimer?.cancel();

    // Ensure immediate clean standby state while awaiting wave crest
    FlashControllerService().stopStrobe();
    FlashControllerService().turnOff();
    ScreenLightService().setDimmedStandby();

    _updateState(_state.copyWith(
      currentAction: action,
      isActionActive: false,
      statusMessageAr: 'طواف الصاعقة 360° يقترب من مدرجك... 🌊⚡',
    ));

    final totalSectors = action.targetIds.isNotEmpty ? action.targetIds.length : 10;
    int sectorIndex = action.targetIds.indexOf(_selectedSector.id);
    if (sectorIndex < 0) {
      sectorIndex = (_selectedSector.orderIndex - 1).clamp(0, totalSectors - 1);
    }

    if (action.waveDirection == 'R2L') {
      sectorIndex = (totalSectors - 1 - sectorIndex).clamp(0, totalSectors - 1);
    } else if (action.waveDirection == 'CENTER_OUT') {
      final center = (totalSectors - 1) / 2.0;
      sectorIndex = (sectorIndex - center).abs().round().clamp(0, totalSectors - 1);
    } else if (action.waveDirection == 'TOP_BOTTOM') {
      final rowNum = (int.tryParse(_seatRow) ?? 6).clamp(1, 6);
      sectorIndex = (6 - rowNum).clamp(0, 5);
    } else if (action.waveDirection == 'BOTTOM_TOP') {
      final rowNum = (int.tryParse(_seatRow) ?? 1).clamp(1, 6);
      sectorIndex = (rowNum - 1).clamp(0, 5);
    }

    final stepMs = action.waveDelayStepMs > 0 ? action.waveDelayStepMs : 100;
    final cyclePeriodMs = (totalSectors * stepMs).clamp(1200, 12000);
    final crestDurationMs = (stepMs * 2.2).clamp(250, 750).round();
    final initialOffsetMs = (sectorIndex * stepMs) % cyclePeriodMs;

    final totalDurationSeconds = action.durationSeconds > 0 ? action.durationSeconds : 20;
    final endTime = DateTime.now().add(Duration(seconds: totalDurationSeconds));

    final bool allowScreen = action.hardwareTarget != HardwareTarget.ledOnly;
    final bool allowLed = action.hardwareTarget != HardwareTarget.screenOnly;

    String targetColorHex = action.colorHex;
    if (action.sectorColors != null && action.sectorColors!.containsKey(_selectedSector.id)) {
      targetColorHex = action.sectorColors![_selectedSector.id]!;
    }

    void triggerCrest() {
      if (DateTime.now().isAfter(endTime)) {
        _stopCurrentAction();
        return;
      }

      // 1. Activate pulse when wave crest reaches this seat
      if (allowScreen) {
        ScreenLightService().maximizeBrightness();
      } else {
        ScreenLightService().setDimmedStandby();
      }

      if (allowLed) {
        FlashControllerService().startStrobe(
          frequencyMs: action.flashFrequencyMs > 0 ? action.flashFrequencyMs : 80,
          durationSeconds: 0,
        );
      } else {
        FlashControllerService().stopStrobe();
        FlashControllerService().turnOff();
      }

      Vibration.hasVibrator().then((hasVib) {
        if (hasVib == true) {
          Vibration.vibrate(pattern: [0, 70, 30, 100]);
        }
      });

      _updateState(_state.copyWith(
        currentAction: action,
        isActionActive: true,
        activeCharDisplay: '', // Pure radiant colored light beam (Zero emojis/symbols)
        activeColorHex: targetColorHex,
        statusMessageAr: 'موجة الصاعقة تعبر مقعدك الآن! ⚡🌊',
      ));

      // 2. Shut off immediately after crest passes this seat
      _wavePulseOffTimer?.cancel();
      _wavePulseOffTimer = Timer(Duration(milliseconds: crestDurationMs), () {
        FlashControllerService().stopStrobe();
        FlashControllerService().turnOff();
        ScreenLightService().setDimmedStandby();

        _updateState(_state.copyWith(
          isActionActive: false,
          statusMessageAr: 'طواف الصاعقة مستمر حول المدرج... 🌊',
        ));
      });
    }

    // Schedule wave arrival for this sector
    _waveInitialTimer = Timer(Duration(milliseconds: initialOffsetMs), () {
      if (DateTime.now().isAfter(endTime)) return;
      triggerCrest();

      _waveCycleTimer = Timer.periodic(Duration(milliseconds: cyclePeriodMs), (timer) {
        if (DateTime.now().isAfter(endTime)) {
          timer.cancel();
          _stopCurrentAction();
          return;
        }
        triggerCrest();
      });
    });

    _actionDurationTimer = Timer(Duration(seconds: totalDurationSeconds), () {
      _stopCurrentAction();
    });
  }

  /// Execute non-wave payload action on hardware (Screen + Strobe + Character + Sponsor + Lyrics + Matrix)
  Future<void> _executeAction(TifoActionPayload action) async {
    _actionDurationTimer?.cancel();
    _waveInitialTimer?.cancel();
    _waveCycleTimer?.cancel();
    _wavePulseOffTimer?.cancel();

    final bool allowScreen = action.hardwareTarget != HardwareTarget.ledOnly;
    final bool allowLed = action.hardwareTarget != HardwareTarget.screenOnly;

    // 1. Hardware Screen Brightness
    if (allowScreen) {
      await ScreenLightService().maximizeBrightness();
    } else {
      await ScreenLightService().setDimmedStandby();
    }

    // 2. Hardware Strobe Trigger for strobe or goal celebration
    if (allowLed) {
      if (action.type == TifoActionType.strobe ||
          action.type == TifoActionType.goalCelebration) {
        await FlashControllerService().startStrobe(
          frequencyMs: action.type == TifoActionType.goalCelebration ? 80 : action.flashFrequencyMs,
          durationSeconds: action.durationSeconds,
        );
      } else if (action.type == TifoActionType.solidColor) {
        await FlashControllerService().turnOn();
      } else {
        await FlashControllerService().stopStrobe();
        await FlashControllerService().turnOff();
      }
    } else {
      await FlashControllerService().stopStrobe();
      await FlashControllerService().turnOff();
    }

    // Determine target character (custom payload text or default assigned sector letter)
    String charToDisplay = '';
    String targetColorHex = action.colorHex;

    // 1. Specialized Arabic & Latin Geometric Seat Stencil Engine (رسم الحروف عبر كراسي المدرجات)
    if (action.type == TifoActionType.textDisplay) {
      final rawWord = action.textChar.trim().isNotEmpty ? action.textChar.trim() : 'السعودية';
      final chars = rawWord.split('').where((c) => c.trim().isNotEmpty).toList();
      if (chars.isEmpty) chars.add('ا');

      // Assign letter to this sector based on targetIds order
      String targetChar = chars.first;
      if (action.targetIds.isNotEmpty) {
        final secIndex = action.targetIds.indexOf(_selectedSector.id);
        if (secIndex >= 0) {
          targetChar = chars[secIndex % chars.length];
        } else {
          final sIndex = (_selectedSector.orderIndex - 1).clamp(0, chars.length - 1);
          targetChar = chars[sIndex];
        }
      }

      // Check if this seat coordinate (row, seat) falls on the letter's stroke
      final row = (int.tryParse(_seatRow) ?? 3).clamp(1, 6);
      final seat = (int.tryParse(_seatNumber) ?? 5).clamp(1, 10);
      final bool isStroke = StadiumSeatStencil.isSeatOnStroke(targetChar, row, seat);

      // Foreground stroke color (Bright White/Gold) vs Background stand color (Saudi Green / Theme)
      final fgColor = (action.colorHex.isNotEmpty && action.colorHex != '#008000')
          ? action.colorHex
          : '#FFFFFF'; // Crisp White for the letter outline
      final bgColor = (action.sectorColors != null && action.sectorColors!.containsKey(_selectedSector.id))
          ? action.sectorColors![_selectedSector.id]!
          : '#16A34A'; // Saudi Green for background seats

      targetColorHex = isStroke ? fgColor : bgColor;
      charToDisplay = ''; // Screen stays 100% pure colored pixel!
    } else if (action.sectorColors != null && action.sectorColors!.isNotEmpty) {
      // Use per-sector custom color if available, else fall back to global colorHex
      targetColorHex = action.sectorColors![_selectedSector.id] ?? action.colorHex;
    } else if (action.type == TifoActionType.pixelMatrix && action.pixelMatrixMap != null) {
      final seatKey = '${_selectedSector.id}_R${_seatRow}_S$_seatNumber';
      final rowKey = 'ROW_$_seatRow';
      if (action.pixelMatrixMap!.containsKey(seatKey)) {
        targetColorHex = action.pixelMatrixMap![seatKey].toString();
      } else if (action.pixelMatrixMap!.containsKey(rowKey)) {
        targetColorHex = action.pixelMatrixMap![rowKey].toString();
      } else {
        final row = int.tryParse(_seatRow) ?? 1;
        final seat = int.tryParse(_seatNumber) ?? 1;
        final shape = action.pixelMatrixMap!['shape']?.toString() ?? '';

        if (shape == 'HEART') {
          final x = (seat - 5) / 3.0;
          final y = (4 - row) / 3.0;
          final inHeart = (x * x + y * y - 1) * (x * x + y * y - 1) * (x * x + y * y - 1) - x * x * y * y * y <= 0;
          targetColorHex = inHeart ? '#FF1744' : action.colorHex;
        } else if (shape == 'STAR') {
          final isCenterStar = (row >= 2 && row <= 5) && (seat >= 3 && seat <= 8);
          targetColorHex = isCenterStar ? '#FFD700' : action.colorHex;
        } else if (shape == 'MOSAIC_ORNAMENT') {
          final isPattern = (row + seat) % 2 == 0;
          targetColorHex = isPattern ? '#00E5FF' : '#D500F9';
        } else {
          targetColorHex = (row + seat) % 2 == 0 ? action.colorHex : '#FFFFFF';
        }
      }
    }

    String statusText = 'تيفو مفعّل الآن ⚡';
    if (action.type == TifoActionType.chantLyrics) {
      statusText = 'أهازيج المدرج متزامنة الآن 🎵';
      charToDisplay = action.textChar.trim();
    } else if (action.type == TifoActionType.goalCelebration) {
      statusText = 'احتفال بالهدف ⚽🔥!';
    } else if (action.type == TifoActionType.pixelMatrix) {
      statusText = 'تيفو نقطي متناسق مفعّل 🎨';
    } else if (action.type == TifoActionType.textDisplay) {
      statusText = 'تيفو كلمة "${action.textChar.trim().isNotEmpty ? action.textChar.trim() : 'السعودية'}" مرسوم على المدرج 🇸🇦✨';
    }

    _updateState(_state.copyWith(
      currentAction: action,
      isActionActive: true,
      activeCharDisplay: (action.type == TifoActionType.chantLyrics) ? charToDisplay : '', // Zero clutter for all tifo displays
      activeColorHex: targetColorHex,
      activeSponsor: action.sponsor,
      statusMessageAr: statusText,
    ));

    // Schedule automatic restoration after action duration
    if (action.durationSeconds > 0) {
      _actionDurationTimer = Timer(Duration(seconds: action.durationSeconds), () {
        if (action.sponsor != null) {
          _updateState(_state.copyWith(
            isActionActive: false,
            statusMessageAr: 'تم التفعيل بنجاح! شاهد العرض المتاح.',
          ));
        } else {
          _stopCurrentAction();
        }
      });
    }
  }


  /// Stop current action & restore previous screen brightness
  void _stopCurrentAction() {
    _actionDurationTimer?.cancel();
    _waveInitialTimer?.cancel();
    _waveCycleTimer?.cancel();
    _wavePulseOffTimer?.cancel();
    FlashControllerService().stopStrobe();
    FlashControllerService().turnOff();
    ScreenLightService().restoreBrightness();

    _updateState(_state.copyWith(
      isActionActive: false,
      activeCharDisplay: '',
      activeColorHex: null,
      statusMessageAr: 'في انتظار الإشارة التالية من غرفة التحكم...',
    ));
  }

  /// Trigger a direct local test action (for testing/demoing offline or in Admin preview)
  void simulateAction(TifoActionPayload action) {
    _handleIncomingAction(action);
  }

  void _updateState(SyncEngineState newState) {
    if (_disposed) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void dispose() {
    _disposed = true;
    _isInitialized = false;
    _presenceHeartbeatTimer?.cancel();
    _httpPollTimer?.cancel();
    _actionSubscription?.cancel();
    _offsetSubscription?.cancel();
    _activeInfoSubscription?.cancel();
    _actionDurationTimer?.cancel();
    _waveInitialTimer?.cancel();
    _waveCycleTimer?.cancel();
    _wavePulseOffTimer?.cancel();
    FlashControllerService().stopStrobe();
    FlashControllerService().turnOff();
    if (!_stateController.isClosed) _stateController.close();
  }
}
