import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kToken = 'access_token';
const String _kPatientId = 'patient_id';
const String _kPatientName = 'patient_name';
const String _kPatientPhone = 'patient_phone';

// Fallback mock JWT for development (matches React app behavior)
// This token has role=patient and a long expiry for development testing
const String _kMockToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJzdWIiOiJtb2NrLXBhdGllbnQtaWQiLCJpZCI6Im1vY2stcGF0aWVudC1pZCIsInJvbGUiOiJwYXRpZW50IiwiaWF0IjoxNzgxODQzMDA1LCJleHAiOjQ5Mzc2MDMwMDV9'
    '.mock_signature';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String _patientId = 'mock-patient-id';
  String _patientName = '';
  String _patientPhone = '';
  bool _initialized = false;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get initialized => _initialized;
  String get token => _token ?? _kMockToken;
  String get patientId => _patientId;
  String get patientName => _patientName;
  String get patientPhone => _patientPhone;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _patientId = prefs.getString(_kPatientId) ?? 'mock-patient-id';
    _patientName = prefs.getString(_kPatientName) ?? '';
    _patientPhone = prefs.getString(_kPatientPhone) ?? '';
    _initialized = true;
    notifyListeners();
  }

  /// Login with credentials. For now uses a mock token (no real auth endpoint).
  /// Replace with real API call when auth backend is ready.
  Future<void> login({
    required String name,
    required String phone,
    String password = '',
  }) async {
    // Store patient info, use mock token (matching React's behavior)
    _patientName = name;
    _patientPhone = phone;
    _patientId = 'mock-patient-id';
    _token = _kMockToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token!);
    await prefs.setString(_kPatientId, _patientId);
    await prefs.setString(_kPatientName, _patientName);
    await prefs.setString(_kPatientPhone, _patientPhone);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _patientName = '';
    _patientPhone = '';
    _patientId = 'mock-patient-id';
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
