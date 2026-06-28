import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'admin_live_map_provider.dart';

class AdminLiveMapScreen extends ConsumerWidget {
  final String requestId;

  const AdminLiveMapScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(adminLiveMapProvider(requestId));

    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    if (provider.pickupLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: provider.pickupLocation!,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (provider.destinationLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: provider.destinationLocation!,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (provider.ambulanceLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: provider.ambulanceLocation!,
        infoWindow: const InfoWindow(title: 'Ambulance'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));

      // Draw simple straight-line polyline for route approximation
      if (provider.destinationLocation != null) {
        polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: [provider.ambulanceLocation!, provider.destinationLocation!],
          color: Colors.blueAccent,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
    }

    final initialPos = provider.ambulanceLocation ?? provider.pickupLocation ?? const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Tracking: $requestId', style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(provider.isFollowing ? Icons.my_location : Icons.location_disabled),
            tooltip: provider.isFollowing ? 'Auto-follow ON' : 'Auto-follow OFF',
            onPressed: () => ref.read(adminLiveMapProvider(requestId).notifier).toggleFollow(),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 15),
            markers: markers,
            polylines: polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => ref.read(adminLiveMapProvider(requestId).notifier).setMapController(controller),
            onCameraMoveStarted: () {
              // User interacted with the map manually
              if (ref.read(adminLiveMapProvider(requestId)).isFollowing) {
                ref.read(adminLiveMapProvider(requestId).notifier).toggleFollow();
              }
            },
          ),
          
          // Bottom Telemetry Overlay
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildTelemetryHUD(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryHUD(AdminLiveMapProvider provider) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mission Status', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.status.replaceAll('_', ' '),
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Distance', provider.distanceRemaining, Icons.route),
                _buildMetricColumn('ETA', provider.etaSeconds != null ? '${(provider.etaSeconds! / 60).floor()} min' : 'N/A', Icons.timer),
                _buildMetricColumn('Speed', provider.speed != null ? '${(provider.speed! * 3.6).toStringAsFixed(1)} km/h' : '0 km/h', Icons.speed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF76B82A), size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A5F))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
