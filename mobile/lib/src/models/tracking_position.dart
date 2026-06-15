class TrackingPosition {
  final String vendorEventId;
  final double lat;
  final double lng;
  final double? speedKmph;
  final double? headingDeg;
  final DateTime capturedAt;

  TrackingPosition({required this.vendorEventId, required this.lat, required this.lng, this.speedKmph, this.headingDeg, required this.capturedAt});

  factory TrackingPosition.fromJson(Map<String, dynamic> json) => TrackingPosition(
        vendorEventId: json['vendorEventId'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        speedKmph: json['speedKmph'] != null ? (json['speedKmph'] as num).toDouble() : null,
        headingDeg: json['headingDeg'] != null ? (json['headingDeg'] as num).toDouble() : null,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'vendorEventId': vendorEventId,
        'lat': lat,
        'lng': lng,
        'speedKmph': speedKmph,
        'headingDeg': headingDeg,
        'capturedAt': capturedAt.toIso8601String(),
      };
}
