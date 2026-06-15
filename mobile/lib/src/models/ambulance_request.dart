class AmbulanceRequest {
  final String requestId;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String patientName;
  final String patientPhone;
  final String status;

  AmbulanceRequest({required this.requestId, required this.pickupLat, required this.pickupLng, required this.dropLat, required this.dropLng, required this.patientName, required this.patientPhone, required this.status});

  factory AmbulanceRequest.fromJson(Map<String, dynamic> json) => AmbulanceRequest(
        requestId: json['requestId'] as String,
        pickupLat: (json['pickup']?['lat'] ?? 0) as double,
        pickupLng: (json['pickup']?['lng'] ?? 0) as double,
        dropLat: (json['drop']?['lat'] ?? 0) as double,
        dropLng: (json['drop']?['lng'] ?? 0) as double,
        patientName: json['patient']?['name'] ?? '',
        patientPhone: json['patient']?['phoneE164'] ?? '',
        status: json['status'] ?? 'PENDING',
      );

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'pickup': {'lat': pickupLat, 'lng': pickupLng},
        'drop': {'lat': dropLat, 'lng': dropLng},
        'patient': {'name': patientName, 'phoneE164': patientPhone},
        'status': status,
      };
}
