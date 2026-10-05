import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import 'tracking_provider.dart';
import '../requests/cancel_booking_modal.dart';

const Color _kTopGreen = Color(0xFF5BA438);
const Color _kChekupGreen = Color(0xFF5BA438);

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    String requestId = '';
    if (rawArgs is String) {
      requestId = rawArgs;
    } else if (rawArgs is Map<String, dynamic>) {
      requestId = (rawArgs['requestId'] ?? rawArgs['id'] ?? '').toString();
    }

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
  bool _openedCompleted = false;

  int _stepIndex(String status) {
    final map = {
      'SCHEDULED': 0,
      'PENDING': 0,
      'REQUEST_RECEIVED': 0,
      'REQUEST_CREATED': 1,
      'SEARCHING': 1,
      'SEARCHING_DRIVER': 1,
      'VENDOR_ACCEPTED': 1,
      'DRIVER_ASSIGNED': 2,
      'EN_ROUTE': 3,
      'ARRIVED': 4, 
      'PATIENT_ONBOARD': 5, 
      'TRIP_STARTED': 5,
      'DESTINATION_REACHED': 5,
      'COMPLETED': 6,
      'CANCELLED': 7,
    };
    return map[status] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(builder: (context, prov, _) {
      if (prov.isLoading && prov.data == null) {
        return const Scaffold(backgroundColor: Color(0xFFF9FAFB), body: Center(child: CircularProgressIndicator(color: _kChekupGreen)));
      }
      if (prov.errorMsg != null && prov.data == null) {
        return Scaffold(
          body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 64),
              const SizedBox(height: 16),
              Text(prov.errorMsg!, textAlign: TextAlign.center),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
            ]),
          ),
        );
      }

      final data = prov.data!;
      final status = prov.effectiveStatus;
      
      final driver = prov.effectiveDriver;
      final location = prov.effectiveLocation;
      final step = _stepIndex(status);

      if (location != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              final points = [
                LatLng(data.pickupLat, data.pickupLng),
                LatLng(data.dropLat, data.dropLng),
                LatLng(location.lat, location.lng),
              ];
              _mapCtrl.fitCamera(
                CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(40),
                ),
              );
            } catch (_) {}
          }
        });
      }

      final isSearching = step <= 1;
      final isArrived = step == 4;
      final isTripStarted = step == 5;
      final isCompleted = step == 6;
      final isCancelled = step == 7;

      if (status == 'COMPLETED' && !_openedCompleted) {
        _openedCompleted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/completed', arguments: prov.displayData);
          }
        });
      }
      
      final showDriver = driver != null && step >= 2 && !isCancelled;

      // Distance calculation
      String distLabel = 'Calculating...';
      if (isArrived) {
        distLabel = '0.0 km';
      } else if (isCompleted || isCancelled) {
        distLabel = '-';
      } else {
        final distMeters = prov.effectiveDistanceMeters;
        if (distMeters != null) {
          final km = distMeters / 1000.0;
          distLabel = '${km.toStringAsFixed(1)} km';
        }
      }

      // ETA calculation
      String etaLabel = 'Calculating...';
      if (isArrived) {
        etaLabel = 'Arrived';
      } else if (isCompleted || isCancelled) {
        etaLabel = '-';
      } else {
        final etaSecs = prov.effectiveEtaSeconds;
        if (etaSecs != null) {
          final mins = (etaSecs / 60).ceil();
          if (mins < 1) {
            etaLabel = '< 1 min';
          } else {
            etaLabel = '~ $mins mins';
          }
        }
      }

      return Container(
        color: const Color(0xFFF9FAFB),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Scaffold(
              backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: _kTopGreen,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
          title: Column(
            children: [
              Text(
                isCancelled ? 'Cancelled' : 
                isCompleted ? 'Completed' : 
                isSearching ? 'Ambulance Request' : 
                isTripStarted ? 'Trip In Progress' :
                isArrived ? 'Ambulance Arrived' : 
                'Ambulance On The Way', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)
              ),
              const SizedBox(height: 2),
              Text('Request ID: ${data.requestNumber}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          centerTitle: true,
          actions: [
            if (!isSearching && !isCompleted && !isCancelled)
              IconButton(
                icon: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 18)),
                onPressed: () {},
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Top white section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusPill(status, step),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_headerTitle(step), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.secondary, height: 1.2)),
                              const SizedBox(height: 8),
                              Text(_headerSubtitle(step), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                            ],
                          ),
                        ),
                        // Ambulance Illustration Placeholder
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/ambulance.png', width: 100, height: 100, fit: BoxFit.cover)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    if (!isSearching && !isArrived && !isCompleted && !isCancelled) ...[
                      Row(
                        children: [
                          Expanded(child: _buildSmallPill(Icons.access_time, 'ETA', etaLabel)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSmallPill(Icons.route_outlined, 'Distance', distLabel)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (isArrived) ...[
                      Row(
                        children: [
                          Expanded(child: _buildSmallPill(Icons.access_time, '', 'Arrived just now')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSmallPill(Icons.location_on_outlined, '', data.pickupAddress)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (!isCancelled) _buildStepper(step),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSearching) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: _kChekupGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kChekupGreen.withOpacity(0.1))),
                        child: Row(
                          children: [
                            const Icon(Icons.radar, color: _kChekupGreen, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('We are searching for the nearest ambulance in your area.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.secondary)),
                                  SizedBox(height: 2),
                                  Text('Please stay on this screen for live updates.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Map Card
                    Container(
                      height: 220,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), color: Colors.white),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            _buildMap(data, location, prov.routeCoords, status),
                            _buildMapOverlays(step),
                          ],
                        ),
                      ),
                    ),
                    
                    if (isSearching) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: _kChekupGreen, size: 24),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Estimated Arrival', style: TextStyle(fontSize: 10, color: _kChekupGreen, fontWeight: FontWeight.w600)),
                                      Text(etaLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _kChekupGreen)),
                                      const Text('We will update you shortly', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.route_outlined, color: _kChekupGreen, size: 24),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Distance', style: TextStyle(fontSize: 10, color: _kChekupGreen, fontWeight: FontWeight.w600)),
                                      Text(distLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _kChekupGreen)),
                                      const Text('from your location', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildBookingDetails(data),
                    ],

                    if (showDriver) ...[
                      const SizedBox(height: 20),
                      const Text('Driver Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.secondary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(shape: BoxShape.circle, image: driver.photoUrl != null ? DecorationImage(image: NetworkImage(driver.photoUrl!), fit: BoxFit.cover) : null, color: Colors.grey.shade200),
                              child: driver.photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(4)),
                                    child: Text(driver.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.secondary)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${driver.ambulanceType} Ambulance', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Row(children: [const Icon(Icons.phone, size: 12, color: AppColors.textSecondary), const SizedBox(width: 4), Text(driver.phoneE164, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary))]),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri(scheme: 'tel', path: driver.phoneE164);
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                              icon: const Icon(Icons.phone, color: Colors.white, size: 14),
                              label: const Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kTopGreen, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Text('Ambulance Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.secondary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ambFeature(Icons.local_shipping_outlined, 'Standard\nAmbulance'),
                            Container(width: 1, height: 30, color: AppColors.border),
                            _ambFeature(Icons.health_and_safety_outlined, 'Basic Life\nSupport'),
                            Container(width: 1, height: 30, color: AppColors.border),
                            _ambFeature(Icons.people_outline, 'Trained Medical\nStaff'),
                          ],
                        ),
                      ),
                    ],

                    if (showDriver && !isArrived && !isCompleted && !isTripStarted) ...[
                       const SizedBox(height: 20),
                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: _kChekupGreen.withOpacity(0.05),
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: _kChekupGreen.withOpacity(0.2)),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Expanded(
                                   child: Row(
                                     children: [
                                       const Icon(Icons.access_time, color: _kTopGreen, size: 28),
                                       const SizedBox(width: 12),
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           const Text('Estimated Arrival', style: TextStyle(fontSize: 10, color: _kTopGreen, fontWeight: FontWeight.w600)),
                                           Text(etaLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kTopGreen)),
                                         ],
                                       ),
                                     ],
                                   ),
                                 ),
                                 Container(width: 1, height: 40, color: _kTopGreen.withOpacity(0.2)),
                                 const SizedBox(width: 16),
                                 Expanded(
                                   child: Row(
                                     children: [
                                       const Icon(Icons.route_outlined, color: AppColors.secondary, size: 28),
                                       const SizedBox(width: 12),
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           const Text('Distance', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                           Text(distLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                                         ],
                                       ),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 16),
                             Row(
                               children: const [
                                 Icon(Icons.info_outline, color: AppColors.textSecondary, size: 14),
                                 SizedBox(width: 6),
                                 Text('ETA may change based on traffic and road conditions.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                               ],
                             ),
                           ],
                         ),
                       ),
                    ],

                    const SizedBox(height: 20),
                    if (!isArrived && !isCompleted && !isCancelled && !isTripStarted) _buildBlueSupportCard(),

                    if (isArrived || isTripStarted || isCompleted) ...[
                      _buildWhiteSupportCard(),
                      const SizedBox(height: 16),
                      _buildNeedAssistanceCard(),
                    ],

                    if (isCancelled) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.red.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.cancel, color: AppColors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Booking Cancelled', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.red)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This emergency ambulance request was cancelled.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00561B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/booking'),
                          icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 18),
                          label: const Text('Book New Ambulance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00561B), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Return to Previous Screen', style: TextStyle(color: Color(0xFF00561B), fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                    ],

                    if (!isArrived && !isCompleted && !isCancelled && !isTripStarted) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final ok = await CancelBookingModal.show(
                            context,
                            requestId: prov.requestId,
                            onConfirmCancel: (reason) async {
                              return await prov.cancelRequest(reason);
                            },
                          );
                          if (ok == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ambulance request cancelled successfully.')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.red.withOpacity(0.2))),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.red)), child: const Icon(Icons.close, color: AppColors.red, size: 16)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.red)),
                                    Text('Cancel this emergency request with custom reason.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (prov.cancelling) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red))
                              else const Icon(Icons.chevron_right, color: AppColors.red),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isSearching ? _buildBottomNavigation(context) : null,
      ),
    ),
  ),
);
      });
  }

  String _headerTitle(int step) {
    if (step == 0) return 'Booking Scheduled';
    if (step == 1) return 'Searching for Ambulance';
    if (step == 2) return 'Driver Assigned';
    if (step == 3) return 'Ambulance is\non the way';
    if (step == 4) return 'Ambulance\nhas arrived';
    if (step == 5) return 'Trip in progress';
    if (step == 6) return 'Trip Completed';
    if (step == 7) return 'Request Cancelled';
    return 'Ambulance is\non the way';
  }

  String _headerSubtitle(int step) {
    if (step == 0) return 'Your booking is scheduled. Dispatch will start at the requested time.';
    if (step == 1) return "We're finding the nearest available\nambulance for you.";
    if (step == 2) return 'Your driver has been assigned.';
    if (step == 3) return 'Your driver has been assigned and is\nheading to your location.';
    if (step == 4) return 'Your ambulance is waiting at\nthe pickup location.';
    if (step == 5) return 'You are on the way to the destination.';
    if (step == 6) return 'Your trip has been successfully completed.';
    if (step == 7) return 'This request has been cancelled.';
    return 'Your driver has been assigned and is\nheading to your location.';
  }

  Widget _buildStatusPill(String status, int step) {
    String label = 'Request Received';
    if (step == 0 || status == 'SCHEDULED') label = 'Scheduled';
    if (step == 1) label = 'Searching';
    if (step == 2 || step == 3) label = 'Driver Assigned';
    if (step == 4) label = 'Ambulance Arrived';
    if (step == 5) label = 'Trip Started';
    if (step == 6) label = 'Completed';
    if (step == 7) label = 'Cancelled';

    final isCancelled = step == 7 || status == 'CANCELLED';
    final color = isCancelled ? AppColors.red : _kChekupGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCancelled ? Icons.cancel : Icons.check_circle, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSmallPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: _kTopGreen, size: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: _kTopGreen, size: 24),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondary)),
      ],
    );
  }

  Widget _buildStepper(int step) {
    final steps = step <= 1
        ? const [
            {'label': 'Request\nReceived', 'icon': Icons.check},
            {'label': 'Searching', 'icon': Icons.search},
            {'label': 'Driver\nAssigned', 'icon': Icons.person},
            {'label': 'On The Way', 'icon': Icons.location_on},
          ]
        : const [
            {'label': 'Request\nReceived', 'icon': Icons.check},
            {'label': 'Searching', 'icon': Icons.search},
            {'label': 'Driver\nAssigned', 'icon': Icons.person},
            {'label': 'On The Way', 'icon': Icons.local_shipping},
            {'label': 'Arrived', 'icon': Icons.notifications},
            {'label': 'Trip\nStarted', 'icon': Icons.play_arrow},
            {'label': 'Completed', 'icon': Icons.flag},
          ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index % 2 == 1) {
          int lineStep = index ~/ 2;
          bool isDone = lineStep < step;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Container(
                height: 2, 
                color: isDone ? _kTopGreen : AppColors.border,
              ),
            ),
          );
        }
        int i = index ~/ 2;
        final isDone = i < step;
        final isCurrent = i == step;
        final bgColor = isDone || isCurrent ? _kTopGreen : Colors.white;
        final iconColor = isDone || isCurrent ? Colors.white : AppColors.textMuted;
        final borderColor = isDone || isCurrent ? _kTopGreen : AppColors.border;

        return Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, border: Border.all(color: borderColor)),
              child: Icon(isDone ? Icons.check : (steps[i]['icon'] as IconData), color: iconColor, size: 16),
            ),
            const SizedBox(height: 6),
            Text(steps[i]['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500, color: isDone || isCurrent ? _kTopGreen : AppColors.textSecondary)),
          ],
        );
      }),
    );
  }

  Widget _buildMapOverlays(int step) {
    if (step <= 1) {
      return Positioned(
        top: 16, right: 16, left: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('Your Location', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 8),
                  Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: _kTopGreen, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('Searching Nearby', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600))]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
              child: Row(
                children: const [
                  Icon(Icons.radar, color: _kTopGreen, size: 16),
                  SizedBox(width: 8),
                  Text('Finding nearest\nambulance...', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (step == 4) {
      return Positioned(
        top: 16, left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _kTopGreen, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
          child: const Text('Ambulance Arrived', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );
    } else {
      return Positioned(
        top: 16, left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
          child: Row(
            children: const [
              Icon(Icons.sensors, color: _kTopGreen, size: 16),
              SizedBox(width: 8),
              Text('Ambulance is\non the way', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondary)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMap(TrackingData data, TrackingPosition? location, List<LatLng> routeCoords, String status) {
    final pickup = LatLng(data.pickupLat, data.pickupLng);
    final drop = LatLng(data.dropLat, data.dropLng);
    final hasAmb = location != null;
    final ambPos = hasAmb ? LatLng(location.lat, location.lng) : pickup;

    final isSearching = status == 'PENDING' || status == 'REQUEST_RECEIVED' || status == 'REQUEST_CREATED' || status == 'SEARCHING' || status == 'SEARCHING_DRIVER' || status == 'VENDOR_ACCEPTED';
    final isArrived = status == 'ARRIVED';
    final isTripStarted = status == 'TRIP_STARTED' || status == 'PATIENT_ONBOARD';
    final isCompleted = status == 'COMPLETED';
    final isCancelled = status == 'CANCELLED';

    final markers = <Marker>[
      Marker(point: pickup, width: 110, height: 80, child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 5)]),
              child: const Text('Your Location', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondary)),
            ),
            const Icon(Icons.person_pin_circle, color: Colors.blue, size: 42),
          ],
        )),
      if (!isTripStarted && !isCompleted) Marker(point: drop, width: 90, height: 80, child: Column(
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)), child: const Text('Destination', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600))),
          const Icon(Icons.business, color: AppColors.red, size: 40),
        ],
      )),
      if (!isSearching && !isCompleted && !isCancelled && hasAmb)
        Marker(
          point: ambPos, width: 80, height: 80,
          child: const Icon(Icons.local_shipping, color: _kTopGreen, size: 40).animate(onPlay: (c) => isArrived ? c.repeat(reverse: true) : null).scale(duration: 1.seconds),
        ),
    ];

    final List<LatLng> pointsToFit = [];
    if (!isTripStarted && !isCompleted) pointsToFit.add(pickup);
    pointsToFit.add(drop);
    if (!isSearching && !isCompleted && !isCancelled && hasAmb) pointsToFit.add(ambPos);
    
    // Fallback if empty
    if (pointsToFit.isEmpty) {
      pointsToFit.addAll([pickup, drop]);
    }

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: pointsToFit.first,
        initialZoom: 14,
        initialCameraFit: pointsToFit.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(pointsToFit),
                padding: const EdgeInsets.all(50.0),
              )
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.callhealth.ambulance',
        ),
        
        if (!isCancelled)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routeCoords.length > 1 ? routeCoords : [pickup, drop],
                color: Colors.blue.withOpacity(0.5),
                strokeWidth: 4,
              ),
            ],
          ),
          
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildBookingDetails(TrackingData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
              Row(
                children: const [
                  Text('View Details', style: TextStyle(color: _kTopGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                  Icon(Icons.chevron_right, color: _kTopGreen, size: 16),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.airport_shuttle_outlined, size: 20, color: AppColors.secondary)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ambulance Type', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                        Text(data.driver?.ambulanceType ?? 'Standard\nAmbulance', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.person_outline, size: 20, color: AppColors.secondary)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Patient Name', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                        Text(data.patientName.isEmpty ? 'Unknown' : data.patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Condition', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Normal', style: TextStyle(color: _kTopGreen, fontWeight: FontWeight.w700, fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: _kTopGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pickup Location', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          Text(data.pickupAddress.isEmpty ? 'Not specified' : data.pickupAddress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.business, color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Destination', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          Text(data.dropAddress.isEmpty ? 'Not specified' : data.dropAddress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlueSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle), child: const Icon(Icons.shield, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('We are available 24/7 to help you.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1565C0))),
                Text('Our team is always ready for your assistance.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.headset_mic, color: Colors.white, size: 14),
            label: const Text('Emergency Support', style: TextStyle(color: Colors.white, fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _kTopGreen,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          onTap: (index) {
            if (index == 1) {
              Navigator.of(context).pushReplacementNamed('/booking');
            } else if (index == 3) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Tracking'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'My Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.headset_mic_outlined), label: 'Support'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle), child: const Icon(Icons.shield, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Emergency Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1565C0))),
                Text('Need immediate assistance?\nOur team is available 24/7.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.headset_mic, color: Colors.white, size: 14),
            label: const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedAssistanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          const Icon(Icons.handshake_outlined, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Need Assistance?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.orange)),
                Text('Your ambulance has arrived at the pickup location.\nPlease connect with the driver to begin the journey.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: Row(
              children: const [
                Text('View Pickup Details', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.orange, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
