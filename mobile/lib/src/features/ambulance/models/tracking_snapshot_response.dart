import 'driver_info.dart';
import 'tracking_position.dart';

class TrackingSnapshotResponse {
  final String requestId;
  final String status;
  final DriverInfo? driver;
  final int? etaSeconds;
  final TrackingPosition? lastLocation;
  final DateTime updatedAt;

  const TrackingSnapshotResponse({
    required this.requestId,
    required this.status,
    required this.updatedAt,
    this.driver,
    this.etaSeconds,
    this.lastLocation,
  });

  factory TrackingSnapshotResponse.fromJson(Map<String, dynamic> json) => TrackingSnapshotResponse(
        requestId: json['requestId'] as String,
        status: json['status'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        driver: DriverInfo.fromJson(json['driver'] as Map<String, dynamic>?),
        etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
        lastLocation: json['lastLocation'] == null ? null : TrackingPosition.fromJson(json['lastLocation'] as Map<String, dynamic>),
      );
}
