import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  final String apiKey;

  GoogleMapsService({required this.apiKey});

  CameraPosition initialCamera(double lat, double lng, {double zoom = 14}) {
    return CameraPosition(target: LatLng(lat, lng), zoom: zoom);
  }

  double estimateEtaSeconds(LatLng from, LatLng to, {double avgKmph = 30}) {
    const earthRadiusMeters = 6371000.0;
    final phi1 = from.latitude * (math.pi / 180);
    final phi2 = to.latitude * (math.pi / 180);
    final deltaPhi = (to.latitude - from.latitude) * (math.pi / 180);
    final deltaLambda = (to.longitude - from.longitude) * (math.pi / 180);
    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distanceMeters = earthRadiusMeters * c;
    final hours = (distanceMeters / 1000) / avgKmph;
    return hours * 3600;
  }
}
