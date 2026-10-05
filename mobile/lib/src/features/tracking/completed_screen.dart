import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import 'tracking_provider.dart';

const Color _kTopGreen = Color(0xFF00893F);
const Color _kChekupGreen = Color(0xFF009C51);

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments as TrackingData;

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
            const Text('Ambulance Service Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 2),
            Text('Request ID: ${data.requestNumber}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        centerTitle: true,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: _kTopGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 16),
                            const Text('Ambulance Service\nCompleted', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.secondary, height: 1.2)),
                            const SizedBox(height: 8),
                            const Text('Your ambulance trip has been\ncompleted successfully.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                          ],
                        ),
                      ),
                      // Ambulance Illustration Placeholder
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/ambulance.png', width: 120, height: 120, fit: BoxFit.cover)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today, color: _kTopGreen, size: 14),
                            SizedBox(width: 8),
                            Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: const [
                            Icon(Icons.access_time, color: _kTopGreen, size: 14),
                            SizedBox(width: 8),
                            Text('11:42 AM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStepper(),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trip Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, color: _kTopGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pickup Location', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                        Text(data.pickupAddress.isEmpty ? 'Pickup location unavailable' : data.pickupAddress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.secondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 9.0, top: 4, bottom: 4),
                                child: Icon(Icons.more_vert, size: 16, color: AppColors.border),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Destination', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                        Text(data.dropAddress.isEmpty ? 'Destination unavailable' : data.dropAddress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.secondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMiniMap(data),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Ambulance Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.local_shipping_outlined, color: _kTopGreen, size: 24)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.driver?.ambulanceType ?? 'Standard Ambulance', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.secondary)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(4)),
                                    child: Text(data.driver?.vehicleNumber ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: AppColors.secondary)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                                    child: const Icon(Icons.person, color: Colors.grey),
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(decoration: const BoxDecoration(color: _kTopGreen, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.driver?.name ?? 'Unknown Driver', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondary)),
                                  const Text('Driver', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.access_time, color: _kTopGreen, size: 20)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Travel Time', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                  Text(_travelTime(data), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.border),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.route_outlined, color: _kTopGreen, size: 20)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Distance', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                  Text(_travelDistance(data), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.border),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check, color: _kTopGreen, size: 20)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Status', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                  Text('Completed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _kTopGreen)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Fare Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kTopGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.currency_rupee, color: _kTopGreen, size: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Final Fare', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              Text('₹ 1,250', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.secondary)),
                            ],
                          ),
                        ),
                        Row(
                          children: const [
                            Text('View Fare Details', style: TextStyle(color: _kTopGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                            Icon(Icons.chevron_right, color: _kTopGreen, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Rate Your Experience', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: _kTopGreen, size: 40),
                        onPressed: () => setState(() => _rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Share your feedback (optional)',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(padding: EdgeInsets.only(top: 4, right: 4), child: Text('0/200', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: _kTopGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.receipt_long, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('View Trip Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: _kTopGreen, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.local_shipping, color: _kTopGreen, size: 18),
                          SizedBox(width: 8),
                          Text('Book Another Ambulance', style: TextStyle(color: _kTopGreen, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  ),
);
  }

  Widget _buildStepper() {
    const steps = [
      {'label': 'Request\nReceived'},
      {'label': 'Searching'},
      {'label': 'Driver\nAssigned'},
      {'label': 'On The Way'},
      {'label': 'Arrived'},
      {'label': 'Completed'},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index % 2 == 1) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Container(
                height: 2, 
                color: _kTopGreen,
              ),
            ),
          );
        }
        int i = index ~/ 2;

        return Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: _kTopGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 6),
            Text(steps[i]['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kTopGreen)),
          ],
        );
      }),
    );
  }

  String _travelDistance(TrackingData data) {
    const distance = Distance();
    final km = distance.as(LengthUnit.Kilometer, LatLng(data.pickupLat, data.pickupLng), LatLng(data.dropLat, data.dropLng));
    return '${km.toStringAsFixed(1)} km';
  }

  String _travelTime(TrackingData data) {
    const distance = Distance();
    final km = distance.as(LengthUnit.Kilometer, LatLng(data.pickupLat, data.pickupLng), LatLng(data.dropLat, data.dropLng));
    return '${(km / 30 * 60).ceil()} mins';
  }

  Widget _buildMiniMap(TrackingData data) {
    final pickup = LatLng(data.pickupLat, data.pickupLng);
    final drop = LatLng(data.dropLat, data.dropLng);

    return IgnorePointer(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng((pickup.latitude + drop.latitude) / 2, (pickup.longitude + drop.longitude) / 2),
          initialZoom: 11,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.callhealth.ambulance',
          ),
          PolylineLayer(polylines: [Polyline(points: [pickup, drop], color: _kTopGreen, strokeWidth: 4)]),
          MarkerLayer(markers: [
            Marker(point: pickup, width: 30, height: 30, child: const Icon(Icons.location_on, color: _kTopGreen, size: 24)),
            Marker(point: drop, width: 30, height: 30, child: const Icon(Icons.location_on, color: AppColors.red, size: 24)),
          ]),
        ],
      ),
    );
  }
}
