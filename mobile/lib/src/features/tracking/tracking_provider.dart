import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class DriverInfo {
  final String name;
  final String phoneE164;
  final String vehicleNumber;
  final String ambulanceType;
  final String? ambulanceNumber;
  final String? photoUrl;

  const DriverInfo({
    required this.name,
    required this.phoneE164,
    required this.vehicleNumber,
    required this.ambulanceType,
    this.ambulanceNumber,
    this.photoUrl,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> j) => DriverInfo(
        name: j['name'] as String? ?? '',
        phoneE164: j['phoneE164'] as String? ?? '',
        vehicleNumber: j['vehicleNumber'] as String? ?? '',
        ambulanceType: j['ambulanceType'] as String? ?? '',
        ambulanceNumber: j['ambulanceNumber'] as String?,
        photoUrl: j['photoUrl'] as String?,
      );
}

class TrackingPosition {
  final double lat;
  final double lng;
  final double? speedKmph;
  final double? headingDeg;
  final String capturedAt;

  const TrackingPosition({required this.lat, required this.lng, this.speedKmph, this.headingDeg, required this.capturedAt});

  factory TrackingPosition.fromJson(Map<String, dynamic> j) => TrackingPosition(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        speedKmph: (j['speedKmph'] as num?)?.toDouble(),
        headingDeg: (j['headingDeg'] as num?)?.toDouble(),
        capturedAt: j['capturedAt'] as String? ?? '',
      );
}

class TrackingData {
  final String requestId;
  final String requestNumber;
  final String status;
  final String patientName;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropLat;
  final double dropLng;
  final String dropAddress;
  final DriverInfo? driver;
  final int? etaSeconds;
  final TrackingPosition? lastLocation;

  const TrackingData({
    required this.requestId,
    required this.requestNumber,
    required this.status,
    required this.patientName,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropLat,
    required this.dropLng,
    required this.dropAddress,
    this.driver,
    this.etaSeconds,
    this.lastLocation,
  });

  factory TrackingData.fromJson(Map<String, dynamic> j) {
    final drv = j['driver'];
    final loc = j['lastLocation'];
    return TrackingData(
      requestId: j['requestId'] as String? ?? '',
      requestNumber: j['requestNumber'] as String? ?? '',
      status: j['status'] as String? ?? 'PENDING',
      patientName: j['patientName'] as String? ?? '',
      pickupLat: (j['pickupLat'] as num).toDouble(),
      pickupLng: (j['pickupLng'] as num).toDouble(),
      pickupAddress: j['pickupAddress'] as String? ?? '',
      dropLat: (j['dropLat'] as num).toDouble(),
      dropLng: (j['dropLng'] as num).toDouble(),
      dropAddress: j['dropAddress'] as String? ?? '',
      driver: drv is Map ? DriverInfo.fromJson(drv as Map<String, dynamic>) : null,
      etaSeconds: j['etaSeconds'] as int?,
      lastLocation: loc is Map ? TrackingPosition.fromJson(loc as Map<String, dynamic>) : null,
    );
  }
}

class TrackingProvider extends ChangeNotifier {
  final DioClient _client;
  final String requestId;
  final String token;

  TrackingProvider(this._client, {required this.requestId, required this.token});

  TrackingData? data;
  bool isLoading = true;
  String? errorMsg;
  bool socketConnected = false;

  // Live overrides from WebSocket
  String? liveStatus;
  int? liveEta;
  DriverInfo? liveDriver;
  TrackingPosition? liveLocation;

  IO.Socket? _socket;
  bool _cancelling = false;
  bool get cancelling => _cancelling;

  String get effectiveStatus => liveStatus ?? data?.status ?? 'PENDING';
  int? get effectiveEta => liveEta ?? data?.etaSeconds;
  DriverInfo? get effectiveDriver => liveDriver ?? data?.driver;
  TrackingPosition? get effectiveLocation => liveLocation ?? data?.lastLocation;

  Future<void> init() async {
    await fetchData();
    _connectSocket();
  }

  Future<void> fetchData() async {
    isLoading = true;
    errorMsg = null;
    notifyListeners();
    try {
      final res = await _client.client.get(ApiEndpoints.patientRequestTrack(requestId));
      data = TrackingData.fromJson(res.data as Map<String, dynamic>);
      // Seed live state from initial fetch
      liveStatus ??= data!.status;
      liveEta ??= data!.etaSeconds;
      liveDriver ??= data!.driver;
      liveLocation ??= data!.lastLocation;
    } on DioException catch (e) {
      errorMsg = 'Could not load tracking data.';
    } catch (e) {
      errorMsg = 'Unexpected error.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _connectSocket() {
    _socket = IO.io(
      '$apiBaseUrl${ApiEndpoints.wsNamespace}',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      socketConnected = true;
      _socket!.emit('subscribe', {'requestId': requestId});
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      socketConnected = false;
      notifyListeners();
    });

    _socket!.on('ambulance_assigned', (d) {
      final data = d is String ? {} : d as Map<String, dynamic>;
      if (data['driver'] is Map) liveDriver = DriverInfo.fromJson(data['driver'] as Map<String, dynamic>);
      if (data['etaSeconds'] != null) liveEta = data['etaSeconds'] as int?;
      liveStatus = 'DRIVER_ASSIGNED';
      notifyListeners();
    });

    _socket!.on('location_updated', (d) {
      if (d is Map) liveLocation = TrackingPosition.fromJson(Map<String, dynamic>.from(d as Map));
      notifyListeners();
    });

    _socket!.on('tracking_updated', (d) {
      if (d is Map) liveLocation = TrackingPosition.fromJson(Map<String, dynamic>.from(d as Map));
      notifyListeners();
    });

    _socket!.on('eta_updated', (d) {
      if (d is Map && d['etaSeconds'] != null) liveEta = d['etaSeconds'] as int;
      notifyListeners();
    });

    _socket!.on('status_updated', (d) {
      if (d is Map && d['status'] != null) liveStatus = d['status'] as String;
      notifyListeners();
    });

    _socket!.on('driver_assigned', (d) {
      if (d is Map) {
        if (d['driver'] is Map) liveDriver = DriverInfo.fromJson(Map<String, dynamic>.from(d['driver'] as Map));
        liveStatus = 'DRIVER_ASSIGNED';
      }
      notifyListeners();
    });

    _socket!.on('request_completed', (_) {
      liveStatus = 'COMPLETED';
      liveEta = 0;
      notifyListeners();
    });

    _socket!.on('ride_completed', (_) {
      liveStatus = 'COMPLETED';
      liveEta = 0;
      notifyListeners();
    });

    _socket!.on('en_route', (_) { liveStatus = 'EN_ROUTE'; notifyListeners(); });
    _socket!.on('arrived',  (_) { liveStatus = 'ARRIVED'; notifyListeners(); });

    _socket!.connect();
  }

  Future<bool> cancelRequest() async {
    _cancelling = true;
    notifyListeners();
    try {
      await _client.client.post(
        ApiEndpoints.patientRequestCancel(requestId),
        data: {'reasonCode': 'patient_cancelled'},
      );
      liveStatus = 'CANCELLED';
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _cancelling = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
