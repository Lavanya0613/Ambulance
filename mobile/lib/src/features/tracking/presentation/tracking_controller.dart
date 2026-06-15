import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/websocket/websocket_service.dart';
import '../../ambulance/domain/ambulance_service.dart';
import '../../ambulance/models/driver_info.dart';
import '../../ambulance/models/tracking_position.dart';
import 'tracking_state.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final trackingControllerProvider = StateNotifierProvider.autoDispose.family<TrackingController, TrackingState, TrackingControllerParams>(
  (ref, params) => TrackingController(
    ambulanceService: ref.read(ambulanceServiceProvider),
    webSocketService: ref.read(webSocketServiceProvider),
    requestId: params.requestId,
    socketUrl: params.socketUrl,
    token: params.token,
  ),
);

class TrackingControllerParams {
  final String requestId;
  final String socketUrl;
  final String token;

  const TrackingControllerParams({required this.requestId, required this.socketUrl, required this.token});
}

class TrackingController extends StateNotifier<TrackingState> {
  TrackingController({
    required AmbulanceService ambulanceService,
    required WebSocketService webSocketService,
    required String requestId,
    required String socketUrl,
    required String token,
  })  : _ambulanceService = ambulanceService,
        _webSocketService = webSocketService,
        _requestId = requestId,
        _socketUrl = socketUrl,
        _token = token,
        super(TrackingState(requestId: requestId)) {
    _initialize();
  }

  final AmbulanceService _ambulanceService;
  final WebSocketService _webSocketService;
  final String _requestId;
  final String _socketUrl;
  final String _token;
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _loadSnapshot();
      _connectSocket();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> _loadSnapshot() async {
    final snapshot = await _ambulanceService.getPatientTrackingSnapshot(_requestId);
    final positions = <TrackingPosition>[
      if (snapshot.lastLocation != null) snapshot.lastLocation!,
    ];
    state = state.copyWith(
      status: snapshot.status,
      driver: snapshot.driver,
      etaSeconds: snapshot.etaSeconds,
      lastLocation: snapshot.lastLocation,
      positions: positions,
      isLoading: false,
      clearError: true,
    );
  }

  void _connectSocket() {
    _webSocketService.connect(url: _socketUrl, token: _token);
    state = state.copyWith(isConnected: true);

    _webSocketService.emit('subscribe', {'requestId': _requestId});

    _webSocketService.on('ambulance_assigned', (payload) {
      _applyServerUpdate(payload);
    });

    _webSocketService.on('location_updated', (payload) {
      final position = _parsePosition(payload);
      if (position == null) return;
      final updatedPositions = [...state.positions, position];
      state = state.copyWith(
        lastLocation: position,
        positions: updatedPositions,
        clearError: true,
      );
    });

    _webSocketService.on('eta_updated', (payload) {
      final eta = _extractEtaSeconds(payload);
      if (eta == null) return;
      state = state.copyWith(etaSeconds: eta, clearError: true);
    });

    _webSocketService.on('ride_completed', (payload) {
      state = state.copyWith(status: 'COMPLETED', clearError: true);
      _applyServerUpdate(payload);
    });

    _webSocketService.on('connect', (_) {
      state = state.copyWith(isConnected: true, clearError: true);
      _webSocketService.emit('subscribe', {'requestId': _requestId});
    });

    _webSocketService.on('disconnect', (_) {
      state = state.copyWith(isConnected: false, clearError: true);
    });

    _webSocketService.on('connect_error', (error) {
      state = state.copyWith(isConnected: false, errorMessage: error?.toString() ?? 'Socket connection error');
    });
  }

  void _applyServerUpdate(dynamic payload) {
    if (payload is! Map) return;
    final map = payload.cast<String, dynamic>();
    final status = map['status'] as String?;
    final eta = _extractEtaSeconds(map['etaSeconds']);
    final driver = map['driver'];

    TrackingPosition? position;
    if (map['lastLocation'] is Map) {
      position = _parsePosition(map['lastLocation']);
    } else if (map['position'] is Map) {
      position = _parsePosition(map['position']);
    }

    state = state.copyWith(
      status: status,
      etaSeconds: eta,
      lastLocation: position ?? state.lastLocation,
      positions: position == null ? state.positions : [...state.positions, position],
      driver: driver is Map ? _parseDriver(driver) : state.driver,
      clearError: true,
    );
  }

  int? _extractEtaSeconds(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Map && value['etaSeconds'] != null) {
      return _extractEtaSeconds(value['etaSeconds']);
    }
    return null;
  }

  TrackingPosition? _parsePosition(dynamic payload) {
    if (payload is! Map) return null;
    final map = payload.cast<String, dynamic>();
    if (map['vendorEventId'] == null || map['lat'] == null || map['lng'] == null) return null;
    return TrackingPosition(
      vendorEventId: map['vendorEventId'].toString(),
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      speedKmph: map['speedKmph'] == null ? null : (map['speedKmph'] as num).toDouble(),
      headingDeg: map['headingDeg'] == null ? null : (map['headingDeg'] as num).toDouble(),
      capturedAt: map['capturedAt'] is String ? DateTime.tryParse(map['capturedAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  DriverInfo _parseDriver(Map<String, dynamic> payload) {
    return DriverInfo(
      vendorDriverRef: payload['vendorDriverRef']?.toString() ?? '',
      name: payload['name']?.toString() ?? '',
      phoneE164: payload['phoneE164']?.toString(),
      vehicleNumber: payload['vehicleNumber']?.toString(),
      ambulanceType: payload['ambulanceType']?.toString(),
    );
  }

  Future<void> refresh() async {
    await _loadSnapshot();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
