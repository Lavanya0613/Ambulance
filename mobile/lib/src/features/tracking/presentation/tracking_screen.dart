import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../ambulance/models/tracking_position.dart';
import 'tracking_controller.dart';
import 'tracking_state.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({
    super.key,
    required this.requestId,
    required this.socketUrl,
    required this.token,
  });

  final String requestId;
  final String socketUrl;
  final String token;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = TrackingControllerParams(
      requestId: widget.requestId,
      socketUrl: widget.socketUrl,
      token: widget.token,
    );
    final trackingState = ref.watch(trackingControllerProvider(params));
    final controller = ref.read(trackingControllerProvider(params).notifier);

    final markerSet = _buildMarkers(trackingState);
    final path = _buildPolyline(trackingState.positions);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Track Ambulance'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: trackingState.isLoading ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh snapshot',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StatusHeader(trackingState: trackingState),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCameraPosition(trackingState),
                    markers: markerSet,
                    polylines: path,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    onMapCreated: (mapController) {
                      _mapController = mapController;
                      _focusOnLiveLocation(trackingState.lastLocation);
                    },
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _InfoCard(
                      trackingState: trackingState,
                      onCenterMap: () => _focusOnLiveLocation(trackingState.lastLocation),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  CameraPosition _initialCameraPosition(TrackingState state) {
    final location = state.lastLocation;
    if (location != null) {
      return CameraPosition(target: LatLng(location.lat, location.lng), zoom: 15);
    }
    return const CameraPosition(target: LatLng(12.9716, 77.5946), zoom: 12);
  }

  Set<Marker> _buildMarkers(TrackingState state) {
    final markers = <Marker>{};
    final location = state.lastLocation;
    if (location != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ambulance_live'),
          position: LatLng(location.lat, location.lng),
          infoWindow: InfoWindow(
            title: 'Ambulance',
            snippet: 'Last update ${location.capturedAt.toLocal()}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolyline(List<TrackingPosition> positions) {
    if (positions.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('tracking_path'),
        points: positions.map((e) => LatLng(e.lat, e.lng)).toList(),
        color: const Color(0xFFE53935),
        width: 5,
      ),
    };
  }

  Future<void> _focusOnLiveLocation(TrackingPosition? location) async {
    if (_mapController == null || location == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(location.lat, location.lng), 16),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.trackingState});

  final TrackingState trackingState;

  @override
  Widget build(BuildContext context) {
    final connectedColor = trackingState.isConnected ? const Color(0xFF1E8E3E) : const Color(0xFFB3261E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          _StatusDot(color: connectedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trackingState.status,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  trackingState.isConnected ? 'Live websocket updates connected' : 'Reconnecting to live updates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (trackingState.etaSeconds != null)
            _MetricPill(
              label: 'ETA',
              value: _formatEta(trackingState.etaSeconds!),
            ),
        ],
      ),
    );
  }

  String _formatEta(int seconds) {
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.trackingState, required this.onCenterMap});

  final TrackingState trackingState;
  final VoidCallback onCenterMap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request #${trackingState.requestId.substring(0, trackingState.requestId.length > 8 ? 8 : trackingState.requestId.length)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onCenterMap,
                  icon: const Icon(Icons.my_location_outlined),
                  tooltip: 'Center map',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'ETA', value: trackingState.etaSeconds == null ? 'Calculating...' : '${(trackingState.etaSeconds! / 60).ceil()} min'),
            const SizedBox(height: 8),
            _DetailRow(label: 'Status', value: trackingState.status),
            const SizedBox(height: 8),
            _DetailRow(label: 'Live marker', value: trackingState.lastLocation == null ? 'Waiting for location' : '${trackingState.lastLocation!.lat.toStringAsFixed(5)}, ${trackingState.lastLocation!.lng.toStringAsFixed(5)}'),
            if (trackingState.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                trackingState.errorMessage!,
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700])),
          Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
