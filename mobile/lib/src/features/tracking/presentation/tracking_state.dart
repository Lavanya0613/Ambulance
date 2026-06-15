import '../../ambulance/models/driver_info.dart';
import '../../ambulance/models/tracking_position.dart';

class TrackingState {
  final String requestId;
  final String status;
  final DriverInfo? driver;
  final int? etaSeconds;
  final TrackingPosition? lastLocation;
  final List<TrackingPosition> positions;
  final bool isConnected;
  final bool isLoading;
  final String? errorMessage;

  const TrackingState({
    required this.requestId,
    this.status = 'PENDING',
    this.driver,
    this.etaSeconds,
    this.lastLocation,
    this.positions = const [],
    this.isConnected = false,
    this.isLoading = true,
    this.errorMessage,
  });

  TrackingState copyWith({
    String? requestId,
    String? status,
    DriverInfo? driver,
    int? etaSeconds,
    TrackingPosition? lastLocation,
    List<TrackingPosition>? positions,
    bool? isConnected,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrackingState(
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      driver: driver ?? this.driver,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      lastLocation: lastLocation ?? this.lastLocation,
      positions: positions ?? this.positions,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
