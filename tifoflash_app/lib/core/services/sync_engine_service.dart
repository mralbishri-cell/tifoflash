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
      final userGroup = _selectedSector.standGroup.toUpperCase();
      final userSecId = _selectedSector.id.toUpperCase();

      for (final rawTarget in action.targetIds) {
        final target = rawTarget.toUpperCase();
        if (target == 'ALL') return true;
        if (target == userSecId) return true;
        if (target == userGroup) return true;
        if (target.contains(userSecId) || userSecId.contains(target)) return true;

        if (target.contains('NORTH') && userGroup == 'NORTH') return true;
        if (target.contains('SOUTH') && userGroup == 'SOUTH') return true;
        if (target.contains('EAST') && userGroup == 'EAST') return true;
        if (target.contains('WEST') && userGroup == 'WEST') return true;
        if (target.contains('VIP') && userGroup == 'VIP') return true;
      }
      return false;
    }

    if (action.targetType == TargetType.seat) {
      final userSeatId = '${_selectedSector.id}_R${_seatRow}_S$_seatNumber'.toUpperCase();
      return action.targetIds.any((id) => id.toUpperCase() == userSeatId || id.toUpperCase() == _selectedSector.id.toUpperCase());
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
      _stopCurrentAction();
      return;
    }

    // Expiration Check: Ignore old actions from previous sessions
    final nowMs = DateTime.now().millisecondsSinceEpoch + _state.serverTimeOffsetMs;
    final actionAgeMs = nowMs - action.timestamp;
    if (action.durationSeconds > 0) {
      final totalDurationMs = action.durationSeconds * 1000;
      if (actionAgeMs >= totalDurationMs) {
        debugPrint('[SyncEngine] Action ${action.actionId} expired (${actionAgeMs}ms old >= ${totalDurationMs}ms total). Keeping Standby.');
        _stopCurrentAction();
        return;
      }
    }

    // Handle repeating wave laps sequence across sectors
    if (action.type == TifoActionType.wave) {
      _actionDurationTimer?.cancel();

      int sectorIndex = action.targetIds.indexOf(_selectedSector.id);
      if (sectorIndex < 0) {
        sectorIndex = action.targetIds.indexOf(_selectedSector.standGroup.toUpperCase());
      }
      if (sectorIndex < 0) {
        sectorIndex = (_selectedSector.orderIndex - 1).clamp(0, 10);
      }

      final waveStepMs = action.waveDelayStepMs > 0 ? action.waveDelayStepMs : 250;
      final crestDurationMs = 1200; // Duration of wave crest on a sector
      final totalSectors = action.targetIds.isNotEmpty ? action.targetIds.length : 10;
      final singleLapMs = totalSectors * waveStepMs + 500; // Total time for 1 lap (~3.0s)

      final nowMs = DateTime.now().millisecondsSinceEpoch + _state.serverTimeOffsetMs;
      final elapsedMs = (nowMs - action.timestamp).clamp(0, 1000000);
      final totalDurationMs = (action.durationSeconds > 0 ? action.durationSeconds : 12) * 1000;

      if (elapsedMs >= totalDurationMs) {
        _stopCurrentAction();
        return;
      }

      final timeInLap = elapsedMs % singleLapMs;
      final myCrestStart = sectorIndex * waveStepMs;
      final myCrestEnd = myCrestStart + crestDurationMs;

      if (timeInLap >= myCrestStart && timeInLap < myCrestEnd) {
        // Wave crest is ON THIS SECTOR RIGHT NOW!
        _executeAction(action);
        final remainingMsInCrest = myCrestEnd - timeInLap;

        _actionDurationTimer = Timer(Duration(milliseconds: remainingMsInCrest), () {
          _stopCurrentAction();
          // Schedule next lap check for this sector
          final nextLapCheckMs = singleLapMs - crestDurationMs;
          _actionDurationTimer = Timer(Duration(milliseconds: nextLapCheckMs), () {
            _handleIncomingAction(action);
          });
        });
      } else {
        // Wave crest is on OTHER SECTORS right now! Keep THIS sector in Standby!
        _stopCurrentAction();

        final msUntilMyCrest = timeInLap < myCrestStart
            ? (myCrestStart - timeInLap)
            : (singleLapMs - timeInLap + myCrestStart);

        _actionDurationTimer = Timer(Duration(milliseconds: msUntilMyCrest), () {
          _handleIncomingAction(action);
        });
      }
      return;
    }

    _executeAction(action);
  }

  Future<void> _executeAction(TifoActionPayload action) async {
    _actionDurationTimer?.cancel();

    await ScreenLightService().maximizeBrightness();

    if (action.type == TifoActionType.strobe ||
        action.type == TifoActionType.wave ||
        action.type == TifoActionType.goalCelebration) {
      await FlashControllerService().startStrobe(
        frequencyMs: action.type == TifoActionType.goalCelebration ? 80 : action.flashFrequencyMs,
        durationSeconds: action.durationSeconds,
      );
    }

    String charToDisplay = action.textChar.trim();
    if (charToDisplay.length > 1 && action.type == TifoActionType.textDisplay) {
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

    String targetColorHex = action.colorHex;
    if (action.sectorColors != null && action.sectorColors!.isNotEmpty) {
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
        if ((row + seat) % 2 == 0) {
          targetColorHex = action.colorHex;
        } else {
          targetColorHex = '#FFFFFF';
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

    if (action.durationSeconds > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch + _state.serverTimeOffsetMs;
      final elapsedSec = ((nowMs - action.timestamp) / 1000).floor().clamp(0, action.durationSeconds);
      final remainingSec = (action.durationSeconds - elapsedSec).clamp(1, action.durationSeconds);

      _actionDurationTimer = Timer(Duration(seconds: remainingSec), () {
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
