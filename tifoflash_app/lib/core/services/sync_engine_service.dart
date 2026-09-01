import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/stadium_sector.dart';
import '../models/tifo_action_payload.dart';
import 'flash_controller_service.dart';
import 'screen_light_service.dart';

class SyncEngineState {
  final bool isConnectedToFirebase;
  final int serverTimeOffsetMs;
  final TifoActionPayload? currentAction;
  final bool isActionActive;
  final String activeCharDisplay;
  final String? activeColorHex;
  final SponsorInfo? activeSponsor;
  final String statusMessageAr;

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
  final String _deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
  
  DatabaseReference? _liveActionRef;
  DatabaseReference? _presenceRef;
  DatabaseReference? _offsetRef;
  StreamSubscription<DatabaseEvent>? _actionSubscription;
  StreamSubscription<DatabaseEvent>? _offsetSubscription;
  Timer? _actionDurationTimer;
  Timer? _httpPollTimer;
  String _lastHandledActionId = '';
  int _lastHandledTimestamp = 0;

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

  void _registerDevicePresence() {
    if (_presenceRef == null) return;
    try {
      _presenceRef?.set({
        'device_id': _deviceId,
        'sector_id': _selectedSector.id,
        'sector_name': _selectedSector.nameAr,
        'seat_row': _seatRow,
        'seat_number': _seatNumber,
        'joined_at': ServerValue.timestamp,
      });
      _presenceRef?.onDisconnect().remove();
    } catch (e) {
      debugPrint('[SyncEngine] Presence register error: $e');
    }
  }

  void initialize({String matchId = 'match_2026_final'}) {
    final sanitizedMatchId = matchId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (sanitizedMatchId.isEmpty || sanitizedMatchId.length > 50) {
      debugPrint('[SyncEngine] Invalid matchId rejected: $matchId');
      return;
    }
    _matchId = sanitizedMatchId;
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
          final dataMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          final actionId = dataMap['action_id']?.toString() ?? '';
          final timestamp = (dataMap['timestamp'] as num?)?.toInt() ?? 0;
          if (actionId != _lastHandledActionId || timestamp != _lastHandledTimestamp) {
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
    } catch (e) {
      debugPrint('[SyncEngine] Firebase init error: $e');
    }

    _startHttpPolling();
  }

  void _startHttpPolling() {
    _httpPollTimer?.cancel();
    _httpPollTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      try {
        final url = Uri.parse('https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app/matches/$_matchId/live_action.json');
        final response = await http.get(url).timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
          final dataMap = json.decode(response.body) as Map<String, dynamic>;
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
        }
      } catch (e) {
        // Network silent retry
      }
    });
  }

  bool isFanTargeted(TifoActionPayload action) {
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
          action.targetIds.contains(_selectedSector.id);
    }

    return true;
  }

  void _handleIncomingAction(TifoActionPayload action) {
    debugPrint('[SyncEngine] Received action payload: ${action.type} (ID: ${action.actionId})');

    if (action.type == TifoActionType.idle) {
      _stopCurrentAction();
      return;
    }

    if (!isFanTargeted(action)) {
      debugPrint('[SyncEngine] Fan sector (${_selectedSector.id}) not targeted by this action.');
      return;
    }

    // Calculate wave offset delay if target_type is wave
    int executionDelayMs = 0;
    if (action.type == TifoActionType.wave) {
      int sectorIndex = action.targetIds.indexOf(_selectedSector.id);
      if (sectorIndex < 0) {
        sectorIndex = (_selectedSector.orderIndex - 1).clamp(0, 10);
      }

      final totalSectors = action.targetIds.isNotEmpty ? action.targetIds.length : 10;

      if (action.waveDirection == 'R2L') {
        sectorIndex = (totalSectors - 1 - sectorIndex).clamp(0, totalSectors - 1);
      } else if (action.waveDirection == 'CENTER_OUT') {
        final center = totalSectors / 2;
        sectorIndex = (sectorIndex - center).abs().floor();
      } else if (action.waveDirection == 'TOP_BOTTOM') {
        final rowNum = int.tryParse(_seatRow) ?? 1;
        sectorIndex = (rowNum - 1).clamp(0, 5);
      }

      executionDelayMs = sectorIndex * action.waveDelayStepMs;
      debugPrint('[SyncEngine] Wave delay for ${_selectedSector.id}: $executionDelayMs ms (Dir: ${action.waveDirection}, Step: ${action.waveDelayStepMs} ms)');
    }

    Timer(Duration(milliseconds: executionDelayMs), () {
      _executeAction(action);
    });
  }

  /// Execute payload action on hardware (Screen + Strobe + Character + Sponsor + Lyrics + Matrix)
  Future<void> _executeAction(TifoActionPayload action) async {
    _actionDurationTimer?.cancel();

    // 1. Maximize Screen Brightness
    await ScreenLightService().maximizeBrightness();

    // 2. Hardware Strobe Trigger for strobe, wave, or goal celebration
    if (action.type == TifoActionType.strobe ||
        action.type == TifoActionType.wave ||
        action.type == TifoActionType.goalCelebration) {
      await FlashControllerService().startStrobe(
        frequencyMs: action.type == TifoActionType.goalCelebration ? 80 : action.flashFrequencyMs,
        durationSeconds: action.durationSeconds,
      );
    }

    // Determine target character (custom payload text or default assigned sector letter)
    String charToDisplay = action.textChar.trim();
    if (charToDisplay.length > 1 && action.type == TifoActionType.textDisplay) {
      // Sector-level and seat-level word rasterization algorithm:
      // Map word letters across targeted sectors in the stand sequentially
      final secIndex = action.targetIds.indexOf(_selectedSector.id);
      if (secIndex >= 0) {
        charToDisplay = charToDisplay[secIndex % charToDisplay.length];
      } else {
        final seatIdx = (int.tryParse(_seatNumber) ?? 1) - 1;
        final charIdx = seatIdx % charToDisplay.length;
        charToDisplay = charToDisplay[charIdx];
      }
    } else if (charToDisplay.isEmpty && action.type == TifoActionType.textDisplay) {
      charToDisplay = _selectedSector.assignedChar;
    }

    // Determine pixel color if matrix mode is active or sector-specific colors
    String targetColorHex = action.colorHex;
    if (action.sectorColors != null && action.sectorColors!.isNotEmpty) {
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
    } else if (action.type == TifoActionType.goalCelebration) {
      statusText = 'احتفال بالهدف ⚽🔥!';
    } else if (action.type == TifoActionType.pixelMatrix) {
      statusText = 'تيفو نقطي متناسق مفعّل 🎨';
    }

    _updateState(_state.copyWith(
      currentAction: action,
      isActionActive: true,
      activeCharDisplay: charToDisplay,
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
    FlashControllerService().stopStrobe();
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
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void dispose() {
    _httpPollTimer?.cancel();
    _actionSubscription?.cancel();
    _offsetSubscription?.cancel();
    _actionDurationTimer?.cancel();
    _stateController.close();
  }
}
