import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import 'tracking_provider.dart';

const _kStatusSteps = [
  {'key': 'REQUEST_CREATED',     'label': 'Created',         'icon': '📋'},
  {'key': 'SEARCHING_DRIVER',    'label': 'Searching',       'icon': '🔍'},
  {'key': 'VENDOR_ACCEPTED',     'label': 'Accepted',        'icon': '🤝'},
  {'key': 'DRIVER_ASSIGNED',     'label': 'Driver Assigned', 'icon': '👨‍✈️'},
  {'key': 'EN_ROUTE',            'label': 'En Route',        'icon': '🚑'},
  {'key': 'ARRIVED',             'label': 'Arriving',        'icon': '📍'},
  {'key': 'PATIENT_ONBOARD',     'label': 'Onboard',         'icon': '🛏️'},
  {'key': 'DESTINATION_REACHED', 'label': 'At Hospital',     'icon': '🏥'},
  {'key': 'COMPLETED',           'label': 'Completed',       'icon': '✅'},
];

int _stepIndex(String status) {
  const map = {
    'PENDING': 0, 'REQUEST_CREATED': 0, 'SEARCHING_DRIVER': 1,
    'VENDOR_ACCEPTED': 2, 'ASSIGNED': 3, 'DRIVER_ASSIGNED': 3,
    'EN_ROUTE': 4, 'ARRIVED': 5, 'PATIENT_ONBOARD': 6,
    'IN_PROGRESS': 6, 'DESTINATION_REACHED': 7, 'COMPLETED': 8,
  };
  return map[status] ?? 0;
}

Color _statusColor(String status) {
  switch (status) {
    case 'COMPLETED': case 'ARRIVED': case 'DESTINATION_REACHED': return AppColors.green;
    case 'SEARCHING_DRIVER': return AppColors.amber;
    case 'CANCELLED': case 'FAILED': return AppColors.red;
    default: return AppColors.darkBlue;
  }
}

const _kTerminal = {'COMPLETED', 'CANCELLED', 'FAILED'};

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestId = ModalRoute.of(context)!.settings.arguments as String;
    final auth = context.read<AuthProvider>();

    return ChangeNotifierProvider(
      create: (_) {
        final client = DioClient(tokenProvider: () async => auth.token);
        final prov = TrackingProvider(client, requestId: requestId, token: auth.token);
        prov.init();
        return prov;
      },
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatefulWidget {
  const _TrackingView();

  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView> {
  final MapController _mapCtrl = MapController();
  bool _showCancelDialog = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(builder: (context, prov, _) {
      if (prov.isLoading && prov.data == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.green)));
      }
      if (prov.errorMsg != null && prov.data == null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 64),
                const SizedBox(height: 16),
                Text(prov.errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
              ]),
            ),
          ),
        );
      }

      final data = prov.data!;
      final status = prov.effectiveStatus;
      final eta = prov.effectiveEta;
      final driver = prov.effectiveDriver;
      final location = prov.effectiveLocation;
      final step = _stepIndex(status);
      final color = _statusColor(status);
      final isTerminal = _kTerminal.contains(status);

      final etaLabel = eta == null ? 'Calculating...' : eta <= 0 ? 'Arrived' : '${(eta / 60).ceil()} min';

      return Container(
        color: const Color(0xFFF0F4F8),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
            ),
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
          slivers: [
            // Status Hero Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      const Text('Back', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Ambulance On The Way', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.darkBlue)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Icon(prov.socketConnected ? Icons.wifi : Icons.wifi_off,
                                  size: 16, color: prov.socketConnected ? AppColors.green : AppColors.amber),
                              const SizedBox(width: 4),
                              Text(prov.socketConnected ? 'Live' : 'Offline',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: prov.socketConnected ? AppColors.green : AppColors.amber)),
                            ]),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('ETA', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 1)),
                          Text(etaLabel, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1.1)),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // Progress Timeline
                    _buildTimeline(step, status),
                  ],
                ),
              ),
            ),

            // Map
            SliverToBoxAdapter(
              child: Container(
                height: 280,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                clipBehavior: Clip.hardEdge,
                child: _buildMap(data, location),
              ),
            ),

            // Driver Card
            SliverToBoxAdapter(
              child: _buildDriverCard(driver, location, etaLabel),
            ),

            // Action Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBlue),
                      onPressed: () {},
                      child: const Text('Emergency Support', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (!isTerminal) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _showCancelDialog = true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.red),
                      child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
        // Cancel Dialog
        bottomSheet: _showCancelDialog
            ? _CancelDialog(
                cancelling: prov.cancelling,
                onConfirm: () async {
                  final ok = await prov.cancelRequest();
                  setState(() => _showCancelDialog = false);
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled.')));
                  }
                },
                onDismiss: () => setState(() => _showCancelDialog = false),
              )
            : null,
      ))));
    });
  }

  Widget _buildTimeline(int currentStep, String status) {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          // Background bar
          Positioned(
            top: 18, left: 24, right: 24,
            child: Container(height: 4, color: const Color(0xFFf3f4f6)),
          ),
          // Progress bar
          Positioned(
            top: 18, left: 24,
            right: 24 + (1 - currentStep / (_kStatusSteps.length - 1)) * (MediaQuery.of(context).size.width - 80),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              height: 4,
              color: _statusColor(status),
            ),
          ),
          // Steps
          Row(
            children: List.generate(_kStatusSteps.length, (i) {
              final s = _kStatusSteps[i];
              final isDone = i < currentStep || status == 'COMPLETED';
              final isActive = i == currentStep && status != 'COMPLETED';
              return Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 36 : 28,
                    height: isActive ? 36 : 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isActive ? _statusColor(status) : Colors.white,
                      border: Border.all(color: isDone || isActive ? _statusColor(status) : const Color(0xFFe5e7eb), width: 2),
                      boxShadow: isActive ? [BoxShadow(color: _statusColor(status).withOpacity(0.3), blurRadius: 10, spreadRadius: 3)] : [],
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text(s['icon'] as String, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TrackingData data, TrackingPosition? location) {
    final pickup = LatLng(data.pickupLat, data.pickupLng);
    final drop = LatLng(data.dropLat, data.dropLng);
    final hasAmb = location != null;
    final ambPos = hasAmb ? LatLng(location.lat, location.lng) : null;

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: LatLng((data.pickupLat + data.dropLat) / 2, (data.pickupLng + data.dropLng) / 2),
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.callhealth.ambulance',
        ),
        PolylineLayer(polylines: [
          Polyline(
            points: [ambPos ?? pickup, drop],
            color: AppColors.darkBlue,
            strokeWidth: 4,
          ),
        ]),
        MarkerLayer(markers: [
          // Pickup
          Marker(point: pickup, width: 40, height: 40,
            child: const _MapMarker(color: AppColors.green, icon: Icons.person_pin_circle, label: 'P')),
          // Drop
          Marker(point: drop, width: 40, height: 40,
            child: const _MapMarker(color: AppColors.red, icon: Icons.local_hospital, label: 'H')),
          // Ambulance
          if (hasAmb)
            Marker(point: ambPos!, width: 44, height: 44,
              child: const _MapMarker(color: AppColors.darkBlue, icon: Icons.emergency, label: '🚑', isAmbulance: true)),
        ]),
      ],
    );
  }

  Widget _buildDriverCard(DriverInfo? driver, TrackingPosition? location, String etaLabel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Driver Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkBlue)),
          const SizedBox(height: 14),
          if (driver == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  CircularProgressIndicator(color: AppColors.darkBlue, strokeWidth: 2),
                  SizedBox(height: 12),
                  Text('Assigning nearest ambulance...', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ),
            )
          else ...[
            Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFf0f4f8),
                backgroundImage: driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
                child: driver.photoUrl == null ? const Icon(Icons.person, color: AppColors.darkBlue, size: 32) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(driver.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black)),
                    child: Text(driver.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  if (driver.ambulanceNumber != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.darkBlue, borderRadius: BorderRadius.circular(6)),
                      child: Text(driver.ambulanceNumber!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(_ambulanceTypeLabel(driver.ambulanceType),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(driver.phoneE164, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _statBox('Speed', '${location?.speedKmph?.round() ?? '--'} km/h')),
              const SizedBox(width: 10),
              Expanded(child: _statBox('ETA', etaLabel, valueColor: AppColors.green)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: driver.phoneE164);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Driver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, {Color valueColor = AppColors.textPrimary}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor)),
      ]),
    );
  }

  String _ambulanceTypeLabel(String t) {
    switch (t) {
      case 'BLS': return 'Standard Ambulance';
      case 'ALS': return 'Emergency Ambulance';
      case 'ICU': return 'Critical Care Ambulance';
      default: return t;
    }
  }
}

class _MapMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool isAmbulance;

  const _MapMarker({required this.color, required this.icon, required this.label, this.isAmbulance = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
      ),
      child: isAmbulance
          ? const Center(child: Text('🚑', style: TextStyle(fontSize: 18)))
          : Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _CancelDialog extends StatelessWidget {
  final bool cancelling;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const _CancelDialog({required this.cancelling, required this.onConfirm, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Cancel Ambulance Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkBlue)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.warning_amber, color: AppColors.amber, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('This action cannot be undone.', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: onDismiss, child: const Text('Dismiss'))),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: cancelling ? null : onConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                child: cancelling
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
