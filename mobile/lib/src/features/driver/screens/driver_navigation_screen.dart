import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:ambulance_app/src/core/theme/app_theme.dart';
import '../driver_auth_provider.dart';

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({super.key});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  LatLng? _driverPos;
  double _currentSpeedKmH = 0.0;
  double _heading = 0.0;
  bool _isFollowingDriver = true;
  List<LatLng> _routePolyline = [];
  double _distanceRemainingKm = 0.0;
  int _etaMinutes = 0;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLiveTracking() async {
    // Determine position & location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Use fallback initial position if location services disabled
      _setFallbackPosition();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      _setFallbackPosition();
      return;
    }

    // Get initial position
    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _updatePosition(pos);
    } catch (e) {
      _setFallbackPosition();
    }

    // Subscribe to position stream for live movement & automatic route update
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters moved
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position pos) {
      _updatePosition(pos);
    });
  }

  void _setFallbackPosition() {
    final driverProv = context.read<DriverAuthProvider>();
    final req = driverProv.activeRequest;

    double pLat = (req != null && req['pickupLat'] != null) ? (req['pickupLat'] as num).toDouble() : 17.4399;
    double pLng = (req != null && req['pickupLng'] != null) ? (req['pickupLng'] as num).toDouble() : 78.4482;

    // Offset slightly to simulate driver approaching
    setState(() {
      _driverPos = LatLng(pLat - 0.015, pLng - 0.012);
      _currentSpeedKmH = 38.5; // Simulated speed
      _recalculateRoute();
    });
  }

  void _updatePosition(Position pos) {
    if (!mounted) return;

    final latLng = LatLng(pos.latitude, pos.longitude);
    final speedKmH = (pos.speed > 0 ? pos.speed * 3.6 : 0.0); // m/s to km/h

    setState(() {
      _driverPos = latLng;
      _currentSpeedKmH = speedKmH;
      _heading = pos.heading;
      _recalculateRoute();
    });

    if (_isFollowingDriver && _driverPos != null) {
      _mapController.move(_driverPos!, 16.0);
    }

    // Keep backend socket tracking active
    context.read<DriverAuthProvider>().sendLocationUpdate(
      lat: pos.latitude,
      lng: pos.longitude,
      speed: speedKmH,
      heading: pos.heading,
    );
  }

  Future<void> _recalculateRoute() async {
    final driverProv = context.read<DriverAuthProvider>();
    final req = driverProv.activeRequest;

    double pLat = (req != null && req['pickupLat'] != null) ? (req['pickupLat'] as num).toDouble() : 17.4399;
    double pLng = (req != null && req['pickupLng'] != null) ? (req['pickupLng'] as num).toDouble() : 78.4482;
    double dLat = (req != null && req['dropLat'] != null) ? (req['dropLat'] as num).toDouble() : 17.4485;
    double dLng = (req != null && req['dropLng'] != null) ? (req['dropLng'] as num).toDouble() : 78.3808;

    final pickup = LatLng(pLat, pLng);
    final hospital = LatLng(dLat, dLng);
    final currentPos = _driverPos ?? LatLng(pLat - 0.01, pLng - 0.01);

    // Determine target based on status
    final status = req != null ? req['status'] : null;
    LatLng target = pickup;
    if (status == 'TRIP_STARTED' || status == 'PATIENT_ONBOARD') {
      target = hospital;
    }

    try {
      final res = await Dio().get(
        'https://router.project-osrm.org/route/v1/driving/${currentPos.longitude},${currentPos.latitude};${target.longitude},${target.latitude}?overview=full&geometries=geojson',
      );
      if (res.data['routes'] != null && res.data['routes'].isNotEmpty) {
        final route = res.data['routes'][0];
        final coords = route['geometry']['coordinates'] as List;
        List<LatLng> polyline = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        
        double totalMeters = (route['distance'] as num).toDouble();
        double distKm = totalMeters / 1000.0;
        int eta = ((route['duration'] as num).toDouble() / 60).round();
        if (eta < 1) eta = 1;

        if (mounted) {
          setState(() {
            _routePolyline = polyline;
            _distanceRemainingKm = double.parse(distKm.toStringAsFixed(1));
            _etaMinutes = eta;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) * c(point2.latitude * p) * (1 - c((point2.longitude - point1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Meters
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch external map navigation')),
      );
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final phoneUrl = Uri.parse('tel:$phone');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProv = context.watch<DriverAuthProvider>();
    final activeRequest = driverProv.activeRequest;

    final patientName = activeRequest?['patientName'] ?? activeRequest?['userName'] ?? 'Emergency Patient';
    final patientPhone = activeRequest?['patientPhone'] ?? activeRequest?['userPhone'] ?? '+919876543210';
    final pickupAddr = activeRequest?['pickupAddress'] ?? 'Jubilee Hills, Road No 36, Hyderabad';
    final hospitalName = activeRequest?['hospitalName'] ?? activeRequest?['dropAddress'] ?? 'Apollo Hospital Emergency';

    double pLat = (activeRequest != null && activeRequest['pickupLat'] != null) ? (activeRequest['pickupLat'] as num).toDouble() : 17.4399;
    double pLng = (activeRequest != null && activeRequest['pickupLng'] != null) ? (activeRequest['pickupLng'] as num).toDouble() : 78.4482;
    double dLat = (activeRequest != null && activeRequest['dropLat'] != null) ? (activeRequest['dropLat'] as num).toDouble() : 17.4485;
    double dLng = (activeRequest != null && activeRequest['dropLng'] != null) ? (activeRequest['dropLng'] as num).toDouble() : 78.3808;

    final pickup = LatLng(pLat, pLng);
    final hospital = LatLng(dLat, dLng);
    final currentPos = _driverPos ?? LatLng(pLat - 0.015, pLng - 0.012);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map / HD Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 15.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _isFollowingDriver) {
                  setState(() => _isFollowingDriver = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.callhealth.ambulance',
              ),

              // 2. Driving Route Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePolyline.isNotEmpty ? _routePolyline : [currentPos, pickup, hospital],
                    strokeWidth: 6.0,
                    color: AppColors.darkBlue,
                  ),
                ],
              ),

              // 3. Markers (Driver, Pickup, Hospital)
              MarkerLayer(
                markers: [
                  // Driver Marker
                  Marker(
                    point: currentPos,
                    width: 50,
                    height: 50,
                    child: Transform.rotate(
                      angle: (_heading * pi / 180),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.darkBlue,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white, size: 28),
                      ),
                    ),
                  ),

                  // Patient Pickup Marker
                  Marker(
                    point: pickup,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 28),
                    ),
                  ),

                  // Hospital Marker
                  Marker(
                    point: hospital,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                      child: const Icon(Icons.local_hospital, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 4. Header Bar / Top Telemetry HUD & Offline Banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!driverProv.isNetworkConnected)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ Offline - Connection lost (${driverProv.pendingSyncCount} pending queued)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.darkBlue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.darkBlue,
                            borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Speed
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_currentSpeedKmH.toStringAsFixed(0)} km/h',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const Text('Speed', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white30),
                          // Distance
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_distanceRemainingKm km',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const Text('Remaining', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white30),
                          // ETA
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_etaMinutes min',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const Text('ETA', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
          // Re-center Floating Action Button
          if (!_isFollowingDriver)
            Positioned(
              right: 16,
              bottom: 250,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: AppColors.darkBlue),
                onPressed: () {
                  setState(() => _isFollowingDriver = true);
                  if (_driverPos != null) {
                    _mapController.move(_driverPos!, 16.0);
                  }
                },
              ),
            ),

          // 5. Bottom Navigation & Action Controls Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Patient Details Header
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.person, color: AppColors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const Text(
                                'Emergency Patient',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Pickup Address & Hospital Info
                    Row(
                      children: [
                        const Icon(Icons.trip_origin, color: AppColors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pickupAddr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, color: AppColors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hospitalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Next Status Lifecycle Transition Button
                    _buildNextStatusButton(context, activeRequest, driverProv),
                    const SizedBox(height: 12),

                    // Action Buttons Row: [Navigate] [Call Patient] [Refresh Route]
                    Row(
                      children: [
                        // Navigate Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text('Navigate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            onPressed: () => _launchNavigation(pLat, pLng),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Call Patient Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.phone, size: 20),
                            label: const Text('Call Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            onPressed: () => _makePhoneCall(patientPhone),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Refresh Route Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.darkBlue),
                            tooltip: 'Refresh Route',
                            onPressed: () {
                              _recalculateRoute();
                              if (_driverPos != null) {
                                _mapController.move(_driverPos!, 15.0);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Route and map metrics refreshed'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStatusButton(BuildContext context, Map<String, dynamic>? request, DriverAuthProvider prov) {
    if (request == null) return const SizedBox.shrink();
    final status = request['status'];
    String? nextStatus;
    String label = '';
    Color color = AppColors.green;
    IconData icon = Icons.arrow_forward;

    switch (status) {
      case 'DRIVER_ASSIGNED':
        nextStatus = 'ARRIVED';
        label = 'ARRIVED AT PICKUP';
        icon = Icons.location_on;
        color = Colors.teal;
        break;
      case 'ARRIVED':
        nextStatus = 'PATIENT_ONBOARD';
        label = 'PATIENT ONBOARD';
        icon = Icons.accessible_forward;
        color = Colors.indigo;
        break;
      case 'PATIENT_ONBOARD':
        nextStatus = 'EN_ROUTE';
        label = 'EN ROUTE HOSPITAL';
        icon = Icons.navigation;
        color = Colors.orange.shade800;
        break;
      case 'EN_ROUTE':
        nextStatus = 'DESTINATION_REACHED';
        label = 'ARRIVED AT HOSPITAL';
        icon = Icons.local_hospital;
        color = Colors.purple;
        break;
      case 'DESTINATION_REACHED':
        nextStatus = 'COMPLETED';
        label = 'COMPLETE TRIP';
        icon = Icons.check_circle;
        color = AppColors.green;
        break;
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        onPressed: prov.isLoading
            ? null
            : () async {
                final success = await prov.updateTripStatus(request['id'] ?? request['requestId'], nextStatus!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Trip status updated to $nextStatus')),
                  );
                  if (nextStatus == 'COMPLETED') {
                    Navigator.pop(context);
                  }
                }
              },
      ),
    );
  }
}
