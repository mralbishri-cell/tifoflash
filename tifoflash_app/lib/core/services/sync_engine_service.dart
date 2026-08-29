import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

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

  DatabaseReference? _liveActionRef;
  DatabaseReference? _offsetRef;
  StreamSubscription<DatabaseEvent>? _actionSubscription;
  StreamSubscription<DatabaseEvent>? _offsetSubscription;

  final StreamController<SyncEngineState> _stateController = StreamController<SyncEngineState>.broadcast();
  Stream<SyncEngineState> get stateStream => _stateController.stream;

  SyncEngineState _state = SyncEngineState.initial();
  SyncEngineState get state => _state;

  String _matchId = 'match_2026_final';
  StadiumSector _selectedSector = PresetStadiumData.sectors.first;
  String _seatRow = '';
  String _seatNumber = '';
  Timer? _actionDurationTimer;

  void updateFanPlacement({
    required StadiumSector sector,
    String seatRow = '',
    String seatNumber = '',
  }) {
    _selectedSector = sector;
    _seatRow = seatRow;
    _seatNumber = seatNumber;
    debugPrint('[SyncEngine] Fan placement updated: Sector=${sector.id}, Row=$seatRow, Seat=$seatNumber');
  }

  /// Connect to Firebase Realtime Database and start listening to server offset + live action node
  void initialize({String matchId = 'match_2026_final'}) {
    _matchId = matchId;

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

      _liveActionRef = db.ref('/matches/$_matchId/live_action');
      _actionSubscription = _liveActionRef?.onValue.listen((event) {
        if (event.snapshot.value == null) return;
        try {
          final dataMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          final action = TifoActionPayload.fromJson(dataMap);
          _handleIncomingAction(action);
        } catch (e) {
          debugPrint('[SyncEngine] Error parsing live action: $e');
        }
      }, onError: (err) {
        _updateState(_state.copyWith(
          isConnectedToFirebase: false,
          statusMessageAr: 'تعذر الاتصال بقاعدة البيانات. تفعيل النظام الاحتياطي.',
        ));
      });
    } catch (e) {
      debugPrint('[SyncEngine] Firebase init error: $e');
      _updateState(_state.copyWith(
        isConnectedToFirebase: false,
        statusMessageAr: 'وضع المحاكاة المحلي يعمل بنجاح.',
      ));
    }
  }

  /// Evaluate if current fan placement matches target scope
  bool isFanTargeted(TifoActionPayload action) {
    if (action.targetType == TargetType.all) return true;

    if (action.targetType == TargetType.sector) {
      return action.targetIds.contains(_selectedSector.id) ||
          action.targetIds.contains(_selectedSector.standGroup.toUpperCase());
    }

    if (action.targetType == TargetType.seat) {
      final userSeatId = '${_selectedSector.id}_R${_seatRow}_S$_seatNumber';
      return action.targetIds.contains(userSeatId);
    }

    return false;
  }

  /// Process incoming live action command
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
      executionDelayMs = (_selectedSector.orderIndex - 1) * action.waveDelayStepMs;
    }

    Timer(Duration(milliseconds: executionDelayMs), () {
      _executeAction(action);
    });
  }

  /// Execute payload action on hardware (Screen + Strobe + Character + Sponsor)
  Future<void> _executeAction(TifoActionPayload action) async {
    _actionDurationTimer?.cancel();

    // 1. Maximize Screen Brightness
    await ScreenLightService().maximizeBrightness();

    // 2. Hardware Strobe Trigger
    if (action.type == TifoActionType.strobe || action.type == TifoActionType.wave) {
      await FlashControllerService().startStrobe(
        frequencyMs: action.flashFrequencyMs,
        durationSeconds: action.durationSeconds,
      );
    }

    // Determine target character (custom payload text or default assigned sector letter)
    String charToDisplay = action.textChar;
    if (charToDisplay.isEmpty && action.type == TifoActionType.textDisplay) {
      charToDisplay = _selectedSector.assignedChar;
    }

    _updateState(_state.copyWith(
      currentAction: action,
      isActionActive: true,
      activeCharDisplay: charToDisplay,
      activeColorHex: action.colorHex,
      activeSponsor: action.sponsor,
      statusMessageAr: 'تيفو مفعّل الآن ⚡',
    ));

    // Schedule automatic restoration after action duration
    if (action.durationSeconds > 0) {
      _actionDurationTimer = Timer(Duration(seconds: action.durationSeconds), () {
        if (action.sponsor != null) {
          // Show sponsor popup after main sequence
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
    _actionSubscription?.cancel();
    _offsetSubscription?.cancel();
    _actionDurationTimer?.cancel();
    _stateController.close();
  }
}
