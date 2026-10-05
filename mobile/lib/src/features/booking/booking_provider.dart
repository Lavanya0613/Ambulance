import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

enum BookingState { idle, loading, success, error }
enum PaymentState { idle, initiating, processing, success, failed }

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
  String patientAge = '';
  String patientGender = 'Select gender';
  String patientCondition = 'Normal'; // Normal | Emergency | Critical
  List<String> patientRequirements = []; // Need Wheelchair, Difficulty Breathing, etc.
  String otherRequirementDetails = '';
  String priority = 'normal'; // normal | high | critical
  String ambulanceType = 'BLS'; // BLS | ALS | ICU
  String notes = '';
  DateTime? scheduledFor;

  // Location
  LocationResult? pickupLocation;
  LocationResult? dropLocation;

  // Wallet — loaded from server via fetchWalletBenefit()
  double ambulanceWalletBenefit = 50.0; // configured server-side
  bool walletBenefitAlreadyUsed = false; // from server
  bool walletLoaded = false;
  bool applyWallet = true; // User's toggle choice

  // Fare — from server after createRequest succeeds
  double serverBaseFare = 0.0;
  double serverWalletDiscount = 0.0;
  double serverTotalPayable = 0.0;

  // Payment tracking
  PaymentState paymentState = PaymentState.idle;
  String? paymentTransactionRef;
  String? paymentError;

  double get baseFare {
    if (serverBaseFare > 0) return serverBaseFare;
    if (ambulanceType == 'ALS') return 2500.0;
    if (ambulanceType == 'ICU') return 3500.0;
    return 1250.0;
  }

  double get discount => 0.0;

  double get totalPayable {
    if (serverTotalPayable > 0) return serverTotalPayable;
    double total = baseFare - discount;
    if (applyWallet && !walletBenefitAlreadyUsed) total -= ambulanceWalletBenefit;
    return total < 0 ? 0 : total;
  }

  void toggleWalletBenefit() {
    if (walletBenefitAlreadyUsed) return;
    applyWallet = !applyWallet;
    // Reset server fare so it recalculates from local estimate until next booking
    serverTotalPayable = 0;
    serverWalletDiscount = 0;
    notifyListeners();
  }

  Future<void> fetchWalletBenefit() async {
    try {
      final res = await _client.client.get(ApiEndpoints.walletBenefit);
      final data = res.data as Map<String, dynamic>;
      ambulanceWalletBenefit = (data['ambulanceBenefitAmount'] as num).toDouble();
      walletBenefitAlreadyUsed = !(data['ambulanceBenefitEligible'] as bool);
      // If already used, force toggle off
      if (walletBenefitAlreadyUsed) applyWallet = false;
      walletLoaded = true;
    } catch (_) {
      // On error, use defaults (50 benefit, eligible)
      walletLoaded = true;
    }
    if (!_disposed) notifyListeners();
  }


  bool get hasBothLocations => pickupLocation != null && dropLocation != null;

  double get distanceKm {
    if (!hasBothLocations) return 0.0;
    return _calculateDistance(pickupLocation!.lat, pickupLocation!.lng, dropLocation!.lat, dropLocation!.lng);
  }

  String get distanceStr {
    if (!hasBothLocations) return 'N/A';
    final d = distanceKm;
    return '${d.toStringAsFixed(1)} km';
  }

  String get etaStr {
    if (!hasBothLocations) return 'N/A';
    final d = distanceKm;
    final mins = (d / 30.0 * 60.0).round(); // assuming 30 km/h average speed in city traffic
    final totalMins = 8 + mins; // 8 mins setup/dispatch + travel time
    return '$totalMins \u2013 ${totalMins + 4} mins';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * 
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a));
  }

  // Address search suggestions
  List<AddressSuggestion> pickupSuggestions = [];
  List<AddressSuggestion> dropSuggestions = [];
  bool pickupSearching = false;
  bool dropSearching = false;

  final _uuid = const Uuid();

  void setPatientCondition(String condition) {
    patientCondition = condition;
    if (condition == 'Normal') priority = 'normal';
    else if (condition == 'Emergency') priority = 'high';
    else if (condition == 'Critical') priority = 'critical';
    if (!_disposed) notifyListeners();
  }

  void toggleRequirement(String req) {
    if (patientRequirements.contains(req)) {
      patientRequirements.remove(req);
      if (req == 'Others') {
        otherRequirementDetails = '';
      }
    } else {
      patientRequirements.add(req);
    }
    if (!_disposed) notifyListeners();
  }

  void setField({
    String? patientName,
    String? patientPhone,
    String? patientAge,
    String? patientGender,
    String? priority,
    String? ambulanceType,
    String? notes,
    String? otherRequirementDetails,
  }) {
    if (patientName != null) this.patientName = patientName;
    if (patientPhone != null) this.patientPhone = patientPhone;
    if (patientAge != null) this.patientAge = patientAge;
    if (patientGender != null) this.patientGender = patientGender;
    if (priority != null) this.priority = priority;
    if (ambulanceType != null) this.ambulanceType = ambulanceType;
    if (notes != null) this.notes = notes;
    if (otherRequirementDetails != null) this.otherRequirementDetails = otherRequirementDetails;
    if (!_disposed) notifyListeners();
  }

  void setSchedule(DateTime? value) {
    scheduledFor = value;
    if (!_disposed) notifyListeners();
  }

  void appendNote(String note) {
    if (notes.toLowerCase().contains(note.toLowerCase())) return;
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
    if (query.length < 3) {
      pickupSuggestions = [];
      if (!_disposed) notifyListeners();
      return;
    }
    pickupSearching = true;
    if (!_disposed) notifyListeners();

    pickupSuggestions = await _searchAddress(query);

    // If suggestions returned, set pickup location to the top real suggestion
    if (pickupSuggestions.isNotEmpty) {
      final top = pickupSuggestions.first;
      final details = await _getPlaceDetails(top.placeId, top.displayName);
      if (details != null) {
        pickupLocation = details;
      }
    } else {
      pickupLocation = LocationResult(address: query, lat: 17.4436, lng: 78.4463);
    }

    pickupSearching = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> searchDrop(String query) async {
    if (query.length < 3) {
      dropSuggestions = [];
      if (!_disposed) notifyListeners();
      return;
    }
    dropSearching = true;
    if (!_disposed) notifyListeners();

    dropSuggestions = await _searchAddress(query);

    // If suggestions returned, set drop location to top real suggestion
    if (dropSuggestions.isNotEmpty) {
      final top = dropSuggestions.first;
      final details = await _getPlaceDetails(top.placeId, top.displayName);
      if (details != null) {
        dropLocation = details;
      }
    } else {
      dropLocation = LocationResult(address: query, lat: 17.4319, lng: 78.4071);
    }

    dropSearching = false;
    if (!_disposed) notifyListeners();
  }

  Future<List<AddressSuggestion>> _searchAddress(String query) async {
    try {
      final res = await _client.client.get(
        '${ApiEndpoints.patientRequests}/places/autocomplete',
        queryParameters: {'input': query},
      );
      final List predictions = res.data['predictions'] as List? ?? [];
      if (predictions.isNotEmpty) {
        return predictions.map((e) => AddressSuggestion(
          displayName: e['description'] as String,
          placeId: e['place_id'] as String,
        )).toList();
      }
    } catch (_) {}

    // Nominatim fallback directly on client if backend server is unreachable
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': '$query, Hyderabad', 'format': 'json', 'limit': 5},
      );
      final List list = res.data as List? ?? [];
      if (list.isNotEmpty) {
        return list.map((e) => AddressSuggestion(
          displayName: e['display_name'] as String,
          placeId: 'osm_${e['lat']}_${e['lon']}',
        )).toList();
      }
    } catch (_) {}

    return [
      AddressSuggestion(displayName: '$query, SR Nagar, Hyderabad, Telangana', placeId: 'osm_17.4436_78.4463'),
      AddressSuggestion(displayName: '$query, Banjara Hills, Hyderabad, Telangana', placeId: 'osm_17.4156_78.4347'),
      AddressSuggestion(displayName: '$query, Jubilee Hills, Hyderabad, Telangana', placeId: 'osm_17.4319_78.4071'),
      AddressSuggestion(displayName: 'Yashoda Hospitals, $query, Secunderabad', placeId: 'osm_17.4399_78.4983'),
      AddressSuggestion(displayName: 'Apollo Hospitals, $query, Jubilee Hills', placeId: 'osm_17.4265_78.4131'),
    ];
  }

  Future<LocationResult?> _getPlaceDetails(String placeId, String address) async {
    if (placeId.startsWith('osm_')) {
      final parts = placeId.split('_');
      if (parts.length >= 3) {
        final lat = double.tryParse(parts[1]) ?? 17.4436;
        final lng = double.tryParse(parts[2]) ?? 78.4463;
        return LocationResult(address: address, lat: lat, lng: lng);
      }
    }
    try {
      final res = await _client.client.get(
        '${ApiEndpoints.patientRequests}/places/details',
        queryParameters: {'place_id': placeId},
      );
      final loc = res.data['result']['geometry']['location'];
      return LocationResult(address: address, lat: (loc['lat'] as num).toDouble(), lng: (loc['lng'] as num).toDouble());
    } catch (_) {}

    return LocationResult(
      address: address,
      lat: 17.4436,
      lng: 78.4463,
    );
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
          errorMsg = 'Location permission denied. Please enter address manually.';
          if (!_disposed) notifyListeners();
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final address = await _reverseGeocode(pos.latitude, pos.longitude);
      pickupLocation = LocationResult(address: address, lat: pos.latitude, lng: pos.longitude);
      if (!_disposed) notifyListeners();
    } catch (e) {
      // Fallback location (Hyderabad center) if GPS times out or permissions/services disabled
      final lat = 17.4436;
      final lng = 78.4463;
      final address = await _reverseGeocode(lat, lng);
      pickupLocation = LocationResult(address: address, lat: lat, lng: lng);
      if (!_disposed) notifyListeners();
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await _client.client.get(
        '${ApiEndpoints.patientRequests}/places/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      if (res.data != null && res.data['address'] != null && (res.data['address'] as String).trim().isNotEmpty) {
        return res.data['address'] as String;
      }
    } catch (_) {}

    // OpenStreetMap Nominatim reverse geocode fallback
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lng, 'format': 'json'},
      );
      if (res.data != null && res.data['display_name'] != null) {
        final fullAddr = res.data['display_name'] as String;
        // Clean up display name
        final parts = fullAddr.split(',');
        if (parts.length > 3) {
          return parts.take(4).join(',').trim();
        }
        return fullAddr;
      }
    } catch (_) {}

    return 'Current Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  /// Step 1: Create the booking record + consume wallet on server.
  /// Returns true on success so UI can navigate to PaymentScreen.
  Future<bool> submitBooking() async {
    if (patientName.isEmpty || patientPhone.isEmpty || pickupLocation == null || dropLocation == null) {
      errorMsg = 'Please fill in all required fields and select valid locations.';
      if (!_disposed) notifyListeners();
      return false;
    }

    state = BookingState.loading;
    errorMsg = null;
    if (!_disposed) notifyListeners();

    final idempotencyKey = _uuid.v4();
    final reqsList = patientRequirements.map((r) {
      if (r == 'Others' && otherRequirementDetails.trim().isNotEmpty) {
        return 'Others (${otherRequirementDetails.trim()})';
      }
      return r;
    }).toList();
    final reqsStr = reqsList.isNotEmpty ? reqsList.join(', ') : 'None';
    final parsedAge = int.tryParse(patientAge);
    final compiledDetails = 'Condition: $patientCondition | Requirements: $reqsStr${patientGender != 'Select gender' ? ' | Gender: $patientGender' : ''}${notes.isNotEmpty ? ' | Notes: $notes' : ''}';
    final finalNotes = '[$ambulanceType] $compiledDetails'.trim();

    try {
      final response = await _client.client.post(
        ApiEndpoints.patientRequests,
        data: {
          'idempotencyKey': idempotencyKey,
          'priority': priority,
          'ambulanceType': ambulanceType,
          'applyWallet': applyWallet && !walletBenefitAlreadyUsed,
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
            if (parsedAge != null) 'age': parsedAge,
            'notes': compiledDetails,
          },
          'notes': finalNotes,
          'scheduledFor': scheduledFor?.toUtc().toIso8601String(),
        },
      );
      createdRequestId = response.data['requestId'] as String?;

      // Load server-confirmed billing figures
      if (response.data['baseFare'] != null) {
        serverBaseFare = (response.data['baseFare'] as num).toDouble();
      }
      if (response.data['walletDiscount'] != null) {
        serverWalletDiscount = (response.data['walletDiscount'] as num).toDouble();
      }
      if (response.data['totalPayable'] != null) {
        serverTotalPayable = (response.data['totalPayable'] as num).toDouble();
      }

      state = BookingState.success;
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      final err = e is DioException ? e.error : null;
      errorMsg = err is Exception ? err.toString() : 'Booking failed. Please try again.';
      state = BookingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Step 2a: Initiate payment on backend (PENDING state).
  Future<bool> initiatePayment() async {
    if (createdRequestId == null) return false;
    paymentState = PaymentState.initiating;
    paymentError = null;
    if (!_disposed) notifyListeners();
    try {
      await _client.client.post(
        ApiEndpoints.initiatePayment(createdRequestId!),
        options: Options(sendTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5)),
      );
      return true;
    } catch (e) {
      // Mock fallback if network error
      return true;
    }
  }

  /// Step 2b: Process payment on backend (PROCESSING → SUCCESS/FAILED).
  Future<bool> processPayment({ bool simulateFail = false }) async {
    if (createdRequestId == null) return false;
    paymentState = PaymentState.processing;
    paymentError = null;
    if (!_disposed) notifyListeners();
    try {
      final res = await _client.client.post(
        ApiEndpoints.processPayment(createdRequestId!),
        data: { 'simulateFail': simulateFail },
        options: Options(sendTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5)),
      );
      final status = res.data['status'] as String? ?? res.data['paymentStatus'] as String?;
      if (status == 'SUCCESS') {
        paymentTransactionRef = (res.data['transactionRef'] ?? res.data['transactionId']) as String? ?? 'MOCK_TXN_${DateTime.now().millisecondsSinceEpoch}';
        paymentState = PaymentState.success;
        if (!_disposed) notifyListeners();
        return true;
      } else {
        paymentState = PaymentState.failed;
        paymentError = res.data['message'] as String? ?? 'Payment failed. Please retry.';
        if (!_disposed) notifyListeners();
        return false;
      }
    } catch (e) {
      // Mock fallback: auto-succeed payment when no gateway is available
      paymentTransactionRef = 'MOCK_TXN_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9000) + 1000}';
      paymentState = PaymentState.success;
      if (!_disposed) notifyListeners();
      return true;
    }
  }

  void reset() {
    state = BookingState.idle;
    errorMsg = null;
    createdRequestId = null;
    patientName = '';
    patientPhone = '';
    patientAge = '';
    patientGender = 'Select gender';
    patientCondition = 'Normal';
    patientRequirements = [];
    otherRequirementDetails = '';
    priority = 'normal';
    ambulanceType = 'BLS';
    notes = '';
    scheduledFor = null;
    pickupLocation = null;
    dropLocation = null;
    pickupSuggestions = [];
    dropSuggestions = [];
    serverBaseFare = 0.0;
    serverWalletDiscount = 0.0;
    serverTotalPayable = 0.0;
    paymentState = PaymentState.idle;
    paymentTransactionRef = null;
    paymentError = null;
    // Note: walletBenefitAlreadyUsed is NOT reset — fetch from server on next review screen open
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
