import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'admin_request_details_provider.dart';
import 'admin_live_map_screen.dart';
import '../../models/admin_request_details_model.dart';

class AdminRequestDetailsScreen extends ConsumerWidget {
  final String requestId;

  const AdminRequestDetailsScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(adminRequestDetailsProvider(requestId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Request Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF76B82A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(adminRequestDetailsProvider(requestId).notifier).fetchDetails(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)))
              : provider.details == null
                  ? const Center(child: Text('Request not found'))
                  : _buildBody(context, provider.details!),
    );
  }

  Widget _buildBody(BuildContext context, AdminRequestDetails details) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Request #${details.requestNumber}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E3A5F)),
              ),
              _buildStatusChip(details.status),
            ],
          ),
          const SizedBox(height: 16),

          // Google Map Section
          _buildMapSection(details),
          const SizedBox(height: 16),

          // Information Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildInfoCard(
                      title: 'Patient Information',
                      icon: Icons.person,
                      children: [
                        _buildDetailRow('Name', details.patient?.name ?? '-'),
                        _buildDetailRow('Phone', details.patient?.phone ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      title: 'Locations',
                      icon: Icons.location_on,
                      children: [
                        _buildDetailRow('Pickup', details.pickup?.address ?? '-'),
                        _buildDetailRow('Destination', details.destination?.address ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      title: 'Vendor & Fleet',
                      icon: Icons.local_shipping,
                      children: [
                        _buildDetailRow('Vendor', details.vendor?.name ?? 'Unassigned'),
                        _buildDetailRow('Driver', details.driver?.name ?? '-'),
                        _buildDetailRow('Driver Phone', details.driver?.phone ?? '-'),
                        _buildDetailRow('Vehicle No.', details.vehicle?.number ?? '-'),
                        _buildDetailRow('Current ETA', details.eta?.seconds != null ? '${(details.eta!.seconds! / 60).floor()} mins' : '-'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildTimelineCard(details.trackingHistory),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(AdminRequestDetails details) {
    final Set<Marker> markers = {};
    LatLng? initialPos;

    if (details.pickup?.lat != null && details.pickup?.lng != null) {
      initialPos = LatLng(details.pickup!.lat!, details.pickup!.lng!);
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: initialPos,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (details.destination?.lat != null && details.destination?.lng != null) {
      final destPos = LatLng(details.destination!.lat!, details.destination!.lng!);
      initialPos ??= destPos;
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destPos,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (details.trackingHistory.isNotEmpty) {
      final lastPing = details.trackingHistory.last;
      initialPos = LatLng(lastPing.lat, lastPing.lng);
      markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: initialPos,
        infoWindow: const InfoWindow(title: 'Ambulance Current Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            clipBehavior: Clip.antiAlias,
            child: initialPos == null
                ? const Center(child: Text('No location data available'))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: initialPos, zoom: 12),
                    markers: markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('View Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminLiveMapScreen(requestId: details.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF76B82A), size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(List<TrackingPing> history) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: Color(0xFF76B82A), size: 20),
                SizedBox(width: 8),
                Text('Tracking History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
              ],
            ),
            const Divider(height: 24),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('No tracking data recorded yet', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final ping = history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ping.status.replaceAll('_', ' '),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              DateFormat('HH:mm:ss').format(ping.timestamp),
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Lat: ${ping.lat.toStringAsFixed(5)}, Lng: ${ping.lng.toStringAsFixed(5)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        if (ping.speed != null && ping.speed! > 0)
                          Text('Speed: ${ping.speed} m/s', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String displayStatus;

    switch (status) {
      case 'PENDING':
      case 'REQUEST_CREATED':
        displayStatus = 'Pending';
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'SEARCHING_DRIVER':
      case 'SEARCHING_VENDOR':
        displayStatus = 'Searching Vendor';
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'VENDOR_ACCEPTED':
      case 'DRIVER_ASSIGNED':
        displayStatus = 'Assigned';
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'EN_ROUTE':
        displayStatus = 'Driver Arriving';
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'ARRIVED':
      case 'PATIENT_ONBOARD':
        displayStatus = 'Patient Picked';
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'COMPLETED':
        displayStatus = 'Completed';
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'CANCELLED':
      case 'FAILED':
        displayStatus = 'Cancelled';
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        displayStatus = status;
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
