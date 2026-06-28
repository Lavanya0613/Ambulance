class AdminRequestDetails {
  final String id;
  final String requestNumber;
  final String status;
  final PatientInfo? patient;
  final LocationInfo? pickup;
  final LocationInfo? destination;
  final VendorInfo? vendor;
  final DriverInfo? driver;
  final VehicleInfo? vehicle;
  final EtaInfo? eta;
  final List<TrackingPing> trackingHistory;

  AdminRequestDetails({
    required this.id,
    required this.requestNumber,
    required this.status,
    this.patient,
    this.pickup,
    this.destination,
    this.vendor,
    this.driver,
    this.vehicle,
    this.eta,
    this.trackingHistory = const [],
  });

  factory AdminRequestDetails.fromJson(Map<String, dynamic> json) {
    return AdminRequestDetails(
      id: json['id'] ?? '',
      requestNumber: json['requestNumber'] ?? '',
      status: json['status'] ?? 'PENDING',
      patient: json['patient'] != null ? PatientInfo.fromJson(json['patient']) : null,
      pickup: json['pickup'] != null ? LocationInfo.fromJson(json['pickup']) : null,
      destination: json['destination'] != null ? LocationInfo.fromJson(json['destination']) : null,
      vendor: json['vendor'] != null ? VendorInfo.fromJson(json['vendor']) : null,
      driver: json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null,
      vehicle: json['vehicle'] != null ? VehicleInfo.fromJson(json['vehicle']) : null,
      eta: json['eta'] != null ? EtaInfo.fromJson(json['eta']) : null,
      trackingHistory: (json['trackingHistory'] as List?)?.map((e) => TrackingPing.fromJson(e)).toList() ?? [],
    );
  }
}

class PatientInfo {
  final String name;
  final String phone;

  PatientInfo({required this.name, required this.phone});

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class LocationInfo {
  final String address;
  final double? lat;
  final double? lng;

  LocationInfo({required this.address, this.lat, this.lng});

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address'] ?? '',
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }
}

class VendorInfo {
  final String name;

  VendorInfo({required this.name});

  factory VendorInfo.fromJson(Map<String, dynamic> json) {
    return VendorInfo(name: json['name'] ?? '');
  }
}

class DriverInfo {
  final String name;
  final String phone;

  DriverInfo({required this.name, required this.phone});

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class VehicleInfo {
  final String number;

  VehicleInfo({required this.number});

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(number: json['number'] ?? '');
  }
}

class EtaInfo {
  final int? seconds;

  EtaInfo({this.seconds});

  factory EtaInfo.fromJson(Map<String, dynamic> json) {
    return EtaInfo(seconds: json['seconds']);
  }
}

class TrackingPing {
  final double lat;
  final double lng;
  final double? speed;
  final String status;
  final DateTime timestamp;

  TrackingPing({
    required this.lat,
    required this.lng,
    this.speed,
    required this.status,
    required this.timestamp,
  });

  factory TrackingPing.fromJson(Map<String, dynamic> json) {
    return TrackingPing(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      status: json['status'] ?? 'UNKNOWN',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
