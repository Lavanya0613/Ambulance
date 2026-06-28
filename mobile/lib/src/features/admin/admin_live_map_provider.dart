import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../models/admin_request_details_model.dart';
import 'admin_request_details_provider.dart';

const String apiBaseUrl = 'http://localhost:3000';

final adminLiveMapProvider = ChangeNotifierProvider.family<AdminLiveMapProvider, String>((ref, id) {
  final detailsProv = ref.watch(adminRequestDetailsProvider(id));
  return AdminLiveMapProvider(id, detailsProv.details);
});

class AdminLiveMapProvider extends ChangeNotifier {
  final String requestId;
  final AdminRequestDetails? initialDetails;
  
  IO.Socket? _socket;
  GoogleMapController? mapController;
  
  LatLng? pickupLocation;
  LatLng? destinationLocation;
  LatLng? ambulanceLocation;
  
  double? speed;
  int? etaSeconds;
  String status = 'UNKNOWN';
  
  bool isFollowing = true;

  AdminLiveMapProvider(this.requestId, this.initialDetails) {
    _initFromDetails();
    _connectWebsocket();
  }

  void _initFromDetails() {
    if (initialDetails != null) {
      status = initialDetails!.status;
      etaSeconds = initialDetails!.eta?.seconds;
      
      if (initialDetails!.pickup?.lat != null) {
        pickupLocation = LatLng(initialDetails!.pickup!.lat!, initialDetails!.pickup!.lng!);
      }
      if (initialDetails!.destination?.lat != null) {
        destinationLocation = LatLng(initialDetails!.destination!.lat!, initialDetails!.destination!.lng!);
      }
      if (initialDetails!.trackingHistory.isNotEmpty) {
        final last = initialDetails!.trackingHistory.last;
        ambulanceLocation = LatLng(last.lat, last.lng);
        speed = last.speed;
      }
    }
  }

  void _connectWebsocket() {
    _socket = IO.io('$apiBaseUrl/ws', IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': 'TEMP_ADMIN_TOKEN_IF_NEEDED'})
      .build());

    _socket!.on('tracking_updated', (data) => _handleEvent('tracking_updated', data));
    _socket!.on('eta_updated', (data) => _handleEvent('eta_updated', data));
    _socket!.on('request_updated', (data) => _handleEvent('request_updated', data));

    _socket!.connect();
  }

  void _handleEvent(String event, dynamic payload) {
    if (payload is String) payload = jsonDecode(payload);
    
    final id = payload['requestId'] ?? payload['id'];
    if (id != requestId) return; // Ignore other requests

    if (event == 'tracking_updated') {
      ambulanceLocation = LatLng(
        (payload['lat'] as num).toDouble(),
        (payload['lng'] as num).toDouble(),
      );
      speed = payload['speed'] != null ? (payload['speed'] as num).toDouble() : null;
      
      if (isFollowing && mapController != null && ambulanceLocation != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(ambulanceLocation!));
      }
    } else if (event == 'eta_updated') {
      etaSeconds = payload['etaSeconds'];
    } else if (event == 'request_updated') {
      if (payload['status'] != null) {
        status = payload['status'];
      }
    }
    
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    if (ambulanceLocation != null) {
      mapController!.moveCamera(CameraUpdate.newLatLngZoom(ambulanceLocation!, 15));
    }
  }

  void toggleFollow() {
    isFollowing = !isFollowing;
    if (isFollowing && mapController != null && ambulanceLocation != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(ambulanceLocation!));
    }
    notifyListeners();
  }

  String get distanceRemaining {
    if (ambulanceLocation == null || destinationLocation == null) return 'N/A';
    
    // Haversine formula for straight-line distance
    const R = 6371; // km
    final dLat = _deg2rad(destinationLocation!.latitude - ambulanceLocation!.latitude);
    final dLon = _deg2rad(destinationLocation!.longitude - ambulanceLocation!.longitude);
    final a = 
      math.sin(dLat/2) * math.sin(dLat/2) +
      math.cos(_deg2rad(ambulanceLocation!.latitude)) * math.cos(_deg2rad(destinationLocation!.latitude)) * 
      math.sin(dLon/2) * math.sin(dLon/2); 
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a)); 
    final d = R * c; 
    
    return '${d.toStringAsFixed(1)} km';
  }

  double _deg2rad(double deg) {
    return deg * (math.pi/180);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
