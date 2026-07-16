import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

enum BookingState { idle, loading, success, error }

class LocationResult {
  final String address;
  final double lat;
  final double lng;
  LocationResult({required this.address, required this.lat, required this.lng});
}

class AddressSuggestion {
  final String displayName;
  final String placeId;
  AddressSuggestion({required this.displayName, required this.placeId});
}

class BookingProvider extends ChangeNotifier {
  final DioClient _client;
  BookingProvider(this._client);

  bool _disposed = false;

  // State
  BookingState state = BookingState.idle;
  String? errorMsg;
  String? createdRequestId;

  // Form Fields
  String patientName = '';
  String patientPhone = '';
  String priority = 'normal'; // normal | high | critical
  String ambulanceType = 'BLS'; // BLS | ALS | ICU
  String notes = '';

  // Location
  LocationResult? pickupLocation;
  LocationResult? dropLocation;

  // Address search suggestions
  List<AddressSuggestion> pickupSuggestions = [];
  List<AddressSuggestion> dropSuggestions = [];
  bool pickupSearching = false;
  bool dropSearching = false;

  final _uuid = const Uuid();

  void setField({
    String? patientName,
    String? patientPhone,
    String? priority,
    String? ambulanceType,
    String? notes,
  }) {
    if (patientName != null) this.patientName = patientName;
    if (patientPhone != null) this.patientPhone = patientPhone;
    if (priority != null) this.priority = priority;
    if (ambulanceType != null) this.ambulanceType = ambulanceType;
    if (notes != null) this.notes = notes;
    if (!_disposed) notifyListeners();
  }

  void appendNote(String note) {
    notes = notes.isEmpty ? note : '$notes, $note';
    if (!_disposed) notifyListeners();
  }

  void setPickupLocation(LocationResult loc) {
    pickupLocation = loc;
    pickupSuggestions = [];
    if (!_disposed) notifyListeners();
  }

  void setDropLocation(LocationResult loc) {
    dropLocation = loc;
    dropSuggestions = [];
    if (!_disposed) notifyListeners();
  }

  Future<void> searchPickup(String query) async {
    if (query.length < 3) { pickupSuggestions = []; notifyListeners(); return; }
    pickupSearching = true;
    if (!_disposed) notifyListeners();
    pickupSuggestions = await _searchAddress(query);
    pickupSearching = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> searchDrop(String query) async {
    if (query.length < 3) { dropSuggestions = []; notifyListeners(); return; }
    dropSearching = true;
    if (!_disposed) notifyListeners();
    dropSuggestions = await _searchAddress(query);
    dropSearching = false;
    if (!_disposed) notifyListeners();
  }

  Future<List<AddressSuggestion>> _searchAddress(String query) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_KEY_HERE') return [];
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {'input': query, 'key': apiKey, 'components': 'country:in'},
      );
      final List predictions = res.data['predictions'] as List;
      return predictions.map((e) => AddressSuggestion(
        displayName: e['description'] as String,
        placeId: e['place_id'] as String,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<LocationResult?> _getPlaceDetails(String placeId, String address) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_KEY_HERE') return null;
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {'place_id': placeId, 'key': apiKey, 'fields': 'geometry'},
      );
      final loc = res.data['result']['geometry']['location'];
      return LocationResult(address: address, lat: loc['lat'] as double, lng: loc['lng'] as double);
    } catch (_) {
      return null;
    }
  }

  Future<void> selectPickup(AddressSuggestion suggestion) async {
    pickupSearching = true;
    if (!_disposed) notifyListeners();
    final res = await _getPlaceDetails(suggestion.placeId, suggestion.displayName);
    if (res != null) {
      pickupLocation = res;
      pickupSuggestions = [];
    }
    pickupSearching = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> selectDrop(AddressSuggestion suggestion) async {
    dropSearching = true;
    if (!_disposed) notifyListeners();
    final res = await _getPlaceDetails(suggestion.placeId, suggestion.displayName);
    if (res != null) {
      dropLocation = res;
      dropSuggestions = [];
    }
    dropSearching = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    try {
      if (!kIsWeb) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          errorMsg = 'Location permission denied.';
          if (!_disposed) notifyListeners();
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      final address = await _reverseGeocode(pos.latitude, pos.longitude);
      pickupLocation = LocationResult(address: address, lat: pos.latitude, lng: pos.longitude);
      if (!_disposed) notifyListeners();
    } catch (e) {
      errorMsg = 'Could not get current location. Please enter address manually.';
      if (!_disposed) notifyListeners();
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_KEY_HERE') return 'Current Location';
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {'latlng': '$lat,$lng', 'key': apiKey},
      );
      final results = res.data['results'] as List;
      if (results.isNotEmpty) {
        return results.first['formatted_address'] as String;
      }
      return 'Current Location';
    } catch (_) {
      return 'Current Location';
    }
  }

  Future<void> submitBooking() async {
    if (patientName.isEmpty || patientPhone.isEmpty || pickupLocation == null || dropLocation == null) {
      errorMsg = 'Please fill in all required fields and select valid locations.';
      if (!_disposed) notifyListeners();
      return;
    }

    state = BookingState.loading;
    errorMsg = null;
    if (!_disposed) notifyListeners();

    final idempotencyKey = _uuid.v4();
    final finalNotes = '[${ambulanceType}] $notes'.trim();

    try {
      final response = await _client.client.post(
        ApiEndpoints.patientRequests,
        data: {
          'idempotencyKey': idempotencyKey,
          'priority': priority,
          'pickup': {
            'lat': pickupLocation!.lat,
            'lng': pickupLocation!.lng,
            'address': pickupLocation!.address,
          },
          'drop': {
            'lat': dropLocation!.lat,
            'lng': dropLocation!.lng,
            'address': dropLocation!.address,
          },
          'patient': {
            'name': patientName,
            'phoneE164': patientPhone,
          },
          'notes': finalNotes,
        },
      );
      createdRequestId = response.data['requestId'] as String?;
      state = BookingState.success;
      if (!_disposed) notifyListeners();
    } catch (e) {
      final err = e is DioException ? e.error : null;
      errorMsg = err is Exception ? err.toString() : 'Booking failed. Please try again.';
      state = BookingState.error;
      notifyListeners();
    }
  }

  void reset() {
    state = BookingState.idle;
    errorMsg = null;
    createdRequestId = null;
    patientName = '';
    patientPhone = '';
    priority = 'normal';
    ambulanceType = 'BLS';
    notes = '';
    pickupLocation = null;
    dropLocation = null;
    pickupSuggestions = [];
    dropSuggestions = [];
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
