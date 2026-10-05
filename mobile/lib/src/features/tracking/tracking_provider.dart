import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:latlong2/latlong.dart';
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
  bool _disposed = false;
  Timer? _mockTimer;

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

  TrackingPosition? get effectiveLocation {
    if (liveLocation != null) return liveLocation;
    if (data?.lastLocation != null) return data!.lastLocation;
    if (data != null) {
      final st = effectiveStatus;
      if (st == 'DRIVER_ASSIGNED' || st == 'EN_ROUTE' || st == 'ARRIVED' || st == 'TRIP_STARTED' || st == 'PATIENT_ONBOARD') {
        final offset = (st == 'TRIP_STARTED' || st == 'PATIENT_ONBOARD') ? 0.003 : 0.010;
        return TrackingPosition(
          lat: data!.pickupLat + offset,
          lng: data!.pickupLng + offset,
          speedKmph: 35.0,
          headingDeg: 45.0,
          capturedAt: DateTime.now().toIso8601String(),
        );
      }
    }
    return null;
  }

  TrackingData get displayData {
    final current = data!;
    return TrackingData(
      requestId: current.requestId,
      requestNumber: current.requestNumber,
      status: effectiveStatus,
      patientName: current.patientName,
      pickupLat: current.pickupLat,
      pickupLng: current.pickupLng,
      pickupAddress: current.pickupAddress,
      dropLat: current.dropLat,
      dropLng: current.dropLng,
      dropAddress: current.dropAddress,
      driver: effectiveDriver,
      etaSeconds: effectiveEta,
      lastLocation: effectiveLocation,
    );
  }

  double? get calculatedDistanceMeters {
    final loc = effectiveLocation;
    if (data == null || loc == null) return null;
    
    final status = effectiveStatus;
    final d = const Distance();
    
    if (status == 'DRIVER_ASSIGNED' || status == 'EN_ROUTE') {
      return d.as(LengthUnit.Meter, LatLng(loc.lat, loc.lng), LatLng(data!.pickupLat, data!.pickupLng)).toDouble();
    } else if (status == 'TRIP_STARTED' || status == 'PATIENT_ONBOARD') {
      return d.as(LengthUnit.Meter, LatLng(loc.lat, loc.lng), LatLng(data!.dropLat, data!.dropLng)).toDouble();
    }
    return null;
  }

  int? get calculatedEtaSeconds {
    final dist = calculatedDistanceMeters;
    if (dist == null) return null;
    // Assume 40 km/h avg speed in city = ~11.11 m/s
    return (dist / 11.11).round();
  }

  List<LatLng> routeCoords = [];
  double? routeDistanceMeters;
  int? routeDurationSeconds;

  Future<void> init() async {
    await fetchData();
    _connectSocket();
    _startMockSimulationIfNeeded();
  }

  final Map<String, List<LatLng>> _routeCache = {};

  Future<void> fetchRoute() async {
    if (data == null) return;
    
    final status = effectiveStatus;
    final loc = effectiveLocation;
    
    double startLat = data!.pickupLat;
    double startLng = data!.pickupLng;
    double endLat = data!.dropLat;
    double endLng = data!.dropLng;
    
    if (loc != null) {
      if (status == 'DRIVER_ASSIGNED' || status == 'EN_ROUTE' || status == 'SEARCHING_DRIVER') {
        startLat = loc.lat;
        startLng = loc.lng;
        endLat = data!.pickupLat;
        endLng = data!.pickupLng;
      } else if (status == 'TRIP_STARTED' || status == 'PATIENT_ONBOARD') {
        startLat = loc.lat;
        startLng = loc.lng;
        endLat = data!.dropLat;
        endLng = data!.dropLng;
      }
    }

    final cacheKey = '${startLat.toStringAsFixed(4)},${startLng.toStringAsFixed(4)};${endLat.toStringAsFixed(4)},${endLng.toStringAsFixed(4)}';
    if (_routeCache.containsKey(cacheKey)) {
      routeCoords = _routeCache[cacheKey]!;
      notifyListeners();
      return;
    }

    try {
      final res = await Dio().get(
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
        options: Options(sendTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)),
      );
      if (res.data['routes'] != null && res.data['routes'].isNotEmpty) {
        final route = res.data['routes'][0] as Map<String, dynamic>;
        final coords = route['geometry']['coordinates'] as List;
        routeCoords = coords.map((coordinate) {
          final point = coordinate as List;
          return LatLng(
            (point[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          );
        }).toList();
        _routeCache[cacheKey] = routeCoords;
        routeDistanceMeters = (route['distance'] as num?)?.toDouble();
        routeDurationSeconds = (route['duration'] as num?)?.round();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  double? get effectiveDistanceMeters {
    return calculatedDistanceMeters ?? routeDistanceMeters;
  }

  int? get effectiveEtaSeconds {
    return effectiveEta ?? calculatedEtaSeconds ?? routeDurationSeconds;
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
      fetchRoute();
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
      ApiEndpoints.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/ws/socket.io')
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
      if (d is Map && d['status'] != null) {
        liveStatus = d['status'] as String;
        fetchRoute();
      }
      notifyListeners();
    });

    _socket!.on('request_created', (d) {
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

  Future<bool> cancelRequest([String reasonCode = 'patient_cancelled']) async {
    _cancelling = true;
    notifyListeners();
    try {
      await _client.client.post(
        ApiEndpoints.patientRequestCancel(requestId),
        data: {'reasonCode': reasonCode},
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

  void _startMockSimulationIfNeeded() {
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_disposed || data == null || socketConnected) {
        timer.cancel();
        return;
      }

      final st = effectiveStatus;
      if (st == 'COMPLETED' || st == 'CANCELLED' || st == 'SCHEDULED') {
        timer.cancel();
        return;
      }

      final pickup = LatLng(data!.pickupLat, data!.pickupLng);
      final drop = LatLng(data!.dropLat, data!.dropLng);

      if (st == 'PENDING' || st == 'REQUEST_RECEIVED' || st == 'REQUEST_CREATED' || st == 'SEARCHING' || st == 'SEARCHING_DRIVER') {
        liveStatus = 'DRIVER_ASSIGNED';
        liveDriver ??= const DriverInfo(
          name: 'Ravi Kumar',
          phoneE164: '+919999998888',
          vehicleNumber: 'MO-01-9012',
          ambulanceType: 'ALS',
        );
        liveLocation = TrackingPosition(
          lat: pickup.latitude + 0.010,
          lng: pickup.longitude + 0.010,
          speedKmph: 40.0,
          headingDeg: 220.0,
          capturedAt: DateTime.now().toIso8601String(),
        );
        notifyListeners();
        return;
      }

      final currentLoc = effectiveLocation;
      if (currentLoc == null) return;

      final currentPos = LatLng(currentLoc.lat, currentLoc.lng);
      final targetPos = (st == 'TRIP_STARTED' || st == 'PATIENT_ONBOARD') ? drop : pickup;

      final dist = const Distance().as(LengthUnit.Meter, currentPos, targetPos);

      if (dist < 40) {
        if (st == 'DRIVER_ASSIGNED' || st == 'EN_ROUTE') {
          liveStatus = 'ARRIVED';
          liveEta = 0;
          notifyListeners();
        } else if (st == 'ARRIVED') {
          liveStatus = 'TRIP_STARTED';
          fetchRoute();
          notifyListeners();
        } else if (st == 'TRIP_STARTED' || st == 'PATIENT_ONBOARD') {
          liveStatus = 'COMPLETED';
          liveEta = 0;
          timer.cancel();
          notifyListeners();
        }
      } else {
        final newLat = currentPos.latitude + (targetPos.latitude - currentPos.latitude) * 0.12;
        final newLng = currentPos.longitude + (targetPos.longitude - currentPos.longitude) * 0.12;
        
        if (st == 'DRIVER_ASSIGNED') liveStatus = 'EN_ROUTE';

        liveLocation = TrackingPosition(
          lat: newLat,
          lng: newLng,
          speedKmph: 42.0,
          headingDeg: 45.0,
          capturedAt: DateTime.now().toIso8601String(),
        );
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _mockTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
