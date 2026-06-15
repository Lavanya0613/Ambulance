class TrackingPosition {
  final String vendorEventId;
  final double lat;
  final double lng;
  final double? speedKmph;
  final double? headingDeg;
  final DateTime capturedAt;

  const TrackingPosition({
    required this.vendorEventId,
    required this.lat,
    required this.lng,
    required this.capturedAt,
    this.speedKmph,
    this.headingDeg,
  });

  factory TrackingPosition.fromJson(Map<String, dynamic> json) => TrackingPosition(
        vendorEventId: json['vendorEventId'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        speedKmph: (json['speedKmph'] as num?)?.toDouble(),
        headingDeg: (json['headingDeg'] as num?)?.toDouble(),
        capturedAt: DateTime.parse(json['capturedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'vendorEventId': vendorEventId,
        'lat': lat,
        'lng': lng,
        if (speedKmph != null) 'speedKmph': speedKmph,
        if (headingDeg != null) 'headingDeg': headingDeg,
        'capturedAt': capturedAt.toIso8601String(),
      };
}
