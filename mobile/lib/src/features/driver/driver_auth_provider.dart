import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ambulance_app/src/core/network/dio_client.dart';
import 'package:ambulance_app/src/core/network/api_endpoints.dart';
import 'sound/sound_service.dart';

const String _kDriverToken = 'driver_token';
const String _kDriverNotifications = 'driver_notifications';
const String _kQueuedGpsUpdates = 'queued_gps_updates';
const String _kQueuedStatusUpdates = 'queued_status_updates';
const String _kDriverDarkMode = 'driver_dark_mode';
const String _kDriverSoundEnabled = 'driver_sound_enabled';

class DriverAuthProvider extends ChangeNotifier {
  DioClient? _apiClient;
  IO.Socket? _socket;
  
  String? _token;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isNetworkConnected = true;
  bool _isDarkMode = false;
  bool _isSoundEnabled = true;

  Map<String, dynamic>? _driverProfile;
  Map<String, dynamic>? _activeRequest;
  int _completedToday = 0;
  List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> _queuedGpsUpdates = [];
  List<Map<String, dynamic>> _queuedStatusUpdates = [];

  Map<String, dynamic>? _pendingAssignment;
  Timer? _assignmentTimer;
  int _countdown = 30;
  final SoundService _soundService = SoundService();

  DriverAuthProvider() {
    _apiClient = DioClient(tokenProvider: () async => _token);
  }

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isNetworkConnected => _isNetworkConnected;
  bool get isDarkMode => _isDarkMode;
  bool get isSoundEnabled => _isSoundEnabled;
  String? get token => _token;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  Map<String, dynamic>? get activeRequest => _activeRequest;
  int get completedToday => _completedToday;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['read'] != true).length;
  int get pendingSyncCount => _queuedGpsUpdates.length + _queuedStatusUpdates.length;

  Map<String, dynamic>? get pendingAssignment => _pendingAssignment;
  int get countdown => _countdown;

  Future<void> toggleDarkMode(bool val) async {
    _isDarkMode = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDriverDarkMode, val);
    notifyListeners();
  }

  Future<void> toggleSoundEnabled(bool val) async {
    _isSoundEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDriverSoundEnabled, val);
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_kDriverDarkMode) ?? false;
      _isSoundEnabled = prefs.getBool(_kDriverSoundEnabled) ?? true;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kDriverToken);
    _initialized = true;
    
    await _loadSettings();
    await _loadLocalNotifications();
    await _loadLocalQueues();
    if (_token != null) {
      await fetchProfile();
      await fetchDashboard();
      await fetchNotifications();
      _initWebSocket();
    } else {
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String otp) async {
    if (_apiClient == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient!.client.post('/driver-app/auth/login', data: {
        'phone': phone,
        'otp': otp,
      });

      if (response.data['token'] != null) {
        _token = response.data['token'];
        _driverProfile = response.data['driver'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kDriverToken, _token!);
        
        _apiClient = DioClient(tokenProvider: () async => _token);
        
        await fetchProfile();
        await fetchDashboard();
        _initWebSocket();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Driver login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    if (_apiClient == null || _token == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient!.client.get('/driver-app/profile');
      if (response.data['success'] == true) {
        _driverProfile = response.data['data'];
        _checkGpsTrackingState();
      }
    } catch (e) {
      debugPrint('Driver profile fetch error: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboard() async {
    if (_apiClient == null) return;
    try {
      final response = await _apiClient!.client.get('/driver-app/dashboard');
      _activeRequest = response.data['activeRequest'];
      _completedToday = response.data['stats']['completedToday'] ?? 0;
      _checkGpsTrackingState();
      notifyListeners();
    } catch (e) {
      debugPrint('Driver dashboard fetch error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchTripHistory({int page = 1, int limit = 10}) async {
    if (_apiClient == null) return null;
    try {
      final response = await _apiClient!.client.get('/driver-app/history', queryParameters: {
        'page': page,
        'limit': limit,
      });
      if (response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Driver fetchTripHistory error: $e');
    }
    return null;
  }

  Future<bool> acceptTrip(String requestId) async {
    _clearTimer();
    _pendingAssignment = null;
    notifyListeners();

    if (_apiClient == null) return false;
    try {
      await _apiClient!.client.post('/driver-app/requests/$requestId/accept');
      // The websocket will send an update, but we can optimistically fetch again or let socket do it.
      await fetchDashboard();
      return true;
    } catch (e) {
      debugPrint('Driver accept error: $e');
      return false;
    }
  }

  Future<bool> rejectTrip(String requestId) async {
    _clearTimer();
    _pendingAssignment = null;
    notifyListeners();

    if (_apiClient == null) return false;
    try {
      await _apiClient!.client.post('/driver-app/requests/$requestId/reject');
      await fetchDashboard();
      return true;
    } catch (e) {
      debugPrint('Driver reject error: $e');
      return false;
    }
  }

  Future<bool> updateTripStatus(String requestId, String targetStatus) async {
    _isLoading = true;
    // Optimistically apply local status update so driver progress is never lost
    if (_activeRequest != null) {
      _activeRequest!['status'] = targetStatus;
    }
    notifyListeners();

    if (_isNetworkConnected && _apiClient != null) {
      try {
        final response = await _apiClient!.client.post('/driver-app/requests/$requestId/status', data: {
          'status': targetStatus,
        });
        if (response.data['success'] == true) {
          await fetchDashboard();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('Driver updateTripStatus network error, queueing offline: $e');
        _isNetworkConnected = false;
      }
    }

    // Queue status update locally for later sync
    _queuedStatusUpdates.add({
      'requestId': requestId,
      'status': targetStatus,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _saveLocalQueues();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> toggleDutyStatus(String newStatus) async {
    if (_apiClient == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient!.client.post('/driver-app/profile/status', data: {
        'status': newStatus,
      });
      if (response.data['success'] == true) {
        if (_driverProfile != null) {
          _driverProfile!['status'] = newStatus;
        }
        await fetchProfile();
        _checkGpsTrackingState();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Driver toggleDutyStatus error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void _initWebSocket() {
    if (_socket != null) {
      _socket!.disconnect();
    }

    _socket = IO.io(ApiEndpoints.wsUrl, IO.OptionBuilder()
      .setPath('/ws/socket.io')
      .setTransports(['websocket'])
      .setAuth({'token': _token})
      .build());

    _socket!.onConnect((_) {
      debugPrint('DriverApp WS connected');
      _isNetworkConnected = true;
      _syncPendingUpdates();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('DriverApp WS disconnected');
      _isNetworkConnected = false;
      notifyListeners();
    });

    _socket!.onConnectError((_) {
      debugPrint('DriverApp WS connect error');
      _isNetworkConnected = false;
      notifyListeners();
    });

    _socket!.on('trip_assigned', (data) {
      debugPrint('DriverApp: New request assigned: $data');
      _pendingAssignment = data;
      _startCountdown(data['requestId'] ?? data['id']);
      _addNotification('NEW_TRIP', 'New Trip Assigned', 'Request #${data['requestId'] ?? data['id']} assigned.', data['requestId'] ?? data['id']);
      _soundService.playNotificationSound();
      _soundService.vibrate();
      notifyListeners();
    });

    _socket!.on('assignment_cancelled', (data) {
      debugPrint('DriverApp: assignment cancelled: $data');
      final reqId = data['requestId'] ?? data['id'];
      _addNotification('TRIP_CANCELLED', 'Trip Cancelled', 'Booking #$reqId has been cancelled by patient or system.', reqId);
      if (_pendingAssignment != null && (_pendingAssignment!['requestId'] == reqId || _pendingAssignment!['id'] == reqId)) {
        _clearTimer();
        _pendingAssignment = null;
        notifyListeners();
      }
      fetchDashboard();
    });

    _socket!.on('route_changed', (data) {
      debugPrint('DriverApp: route_changed: $data');
      _addNotification('ROUTE_CHANGED', 'Route Changed', 'Pickup or destination updated for active trip.', data['requestId']);
      fetchDashboard();
    });

    _socket!.on('emergency_alert', (data) {
      debugPrint('DriverApp: emergency_alert: $data');
      _addNotification('EMERGENCY_ALERT', 'Emergency Priority Dispatch', data['message'] ?? 'High priority emergency alert!', data['requestId']);
      _soundService.playNotificationSound();
      notifyListeners();
    });

    _socket!.on('trip_updated', (data) {
      debugPrint('DriverApp: trip_updated: $data');
      fetchDashboard();
    });

    _socket!.on('request_completed', (data) {
      debugPrint('DriverApp: request_completed: $data');
      fetchDashboard();
    });
  }

  Future<void> _loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kDriverNotifications);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local notifications: $e');
    }
  }

  Future<void> _saveLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDriverNotifications, jsonEncode(_notifications));
    } catch (e) {
      debugPrint('Error saving local notifications: $e');
    }
  }

  void _addNotification(String type, String title, String message, String? requestId) {
    final newItem = {
      'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'title': title,
      'message': message,
      'requestId': requestId,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };
    _notifications.insert(0, newItem);
    _saveLocalNotifications();
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    if (_apiClient == null) return;
    try {
      final response = await _apiClient!.client.get('/driver-app/notifications');
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> backendList = response.data['data'];
        final mapBackend = backendList.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Merge backend notifications with local storage avoiding duplicates
        for (var bItem in mapBackend) {
          if (!_notifications.any((n) => n['id'] == bItem['id'])) {
            _notifications.add(bItem);
          }
        }
        _notifications.sort((a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()));
        await _saveLocalNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Driver fetchNotifications error: $e');
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    final item = _notifications.firstWhere((n) => n['id'] == id, orElse: () => {});
    if (item.isNotEmpty) {
      item['read'] = true;
      await _saveLocalNotifications();
      notifyListeners();
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.client.patch('/driver-app/notifications/$id/read');
      } catch (e) {
        debugPrint('Driver markNotificationAsRead error: $e');
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    for (var n in _notifications) {
      n['read'] = true;
    }
    await _saveLocalNotifications();
    notifyListeners();

    if (_apiClient != null) {
      try {
        await _apiClient!.client.patch('/driver-app/notifications/read-all');
      } catch (e) {
        debugPrint('Driver markAllNotificationsAsRead error: $e');
      }
    }
  }

  StreamSubscription<dynamic>? _gpsSubscription;
  Timer? _bgGpsTimer;

  bool get isOnline => _driverProfile != null && _driverProfile!['status'] != 'OFFLINE';

  void _checkGpsTrackingState() {
    if (isLoggedIn && isOnline) {
      _startBackgroundGpsTracking();
    } else {
      _stopBackgroundGpsTracking();
    }
  }

  void _startBackgroundGpsTracking() {
    if (_bgGpsTimer != null) return; // Already tracking

    debugPrint('Background GPS Tracking STARTED for Driver');
    _bgGpsTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      await _captureAndSendGpsLocation();
    });
  }

  void _stopBackgroundGpsTracking() {
    if (_bgGpsTimer != null) {
      debugPrint('Background GPS Tracking PAUSED (Driver Offline)');
      _bgGpsTimer?.cancel();
      _bgGpsTimer = null;
    }
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  Future<void> _captureAndSendGpsLocation() async {
    if (!isLoggedIn || !isOnline) return;

    try {
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
        }
      } catch (e) {
        // Fallback to active trip request progression
      }

      double lat = position?.latitude ?? 17.4399;
      double lng = position?.longitude ?? 78.4482;
      double speed = position?.speed ?? 36.0;
      double heading = position?.heading ?? 90.0;

      if (position == null && _activeRequest != null && _activeRequest!['pickupLat'] != null) {
        lat = (_activeRequest!['pickupLat'] as num).toDouble();
        lng = (_activeRequest!['pickupLng'] as num).toDouble();
      }

      sendLocationUpdate(lat: lat, lng: lng, speed: speed, heading: heading);
    } catch (e) {
      debugPrint('Error in background GPS capture: $e');
    }
  }

  Future<void> _loadLocalQueues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gpsStr = prefs.getString(_kQueuedGpsUpdates);
      if (gpsStr != null) {
        final List<dynamic> decoded = jsonDecode(gpsStr);
        _queuedGpsUpdates = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      final statusStr = prefs.getString(_kQueuedStatusUpdates);
      if (statusStr != null) {
        final List<dynamic> decoded = jsonDecode(statusStr);
        _queuedStatusUpdates = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local queues: $e');
    }
  }

  Future<void> _saveLocalQueues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kQueuedGpsUpdates, jsonEncode(_queuedGpsUpdates));
      await prefs.setString(_kQueuedStatusUpdates, jsonEncode(_queuedStatusUpdates));
    } catch (e) {
      debugPrint('Error saving local queues: $e');
    }
  }

  Future<void> _syncPendingUpdates() async {
    if (_apiClient == null || !_isNetworkConnected) return;

    if (_queuedStatusUpdates.isNotEmpty) {
      final statusCopy = List<Map<String, dynamic>>.from(_queuedStatusUpdates);
      for (var item in statusCopy) {
        try {
          await _apiClient!.client.post('/driver-app/requests/${item['requestId']}/status', data: {
            'status': item['status'],
          });
          _queuedStatusUpdates.remove(item);
        } catch (e) {
          debugPrint('Error syncing status update: $e');
          break;
        }
      }
    }

    if (_queuedGpsUpdates.isNotEmpty) {
      final gpsCopy = List<Map<String, dynamic>>.from(_queuedGpsUpdates);
      try {
        await _apiClient!.client.post('/driver-app/location/batch', data: {
          'updates': gpsCopy,
        });
        _queuedGpsUpdates.clear();
      } catch (e) {
        debugPrint('Error syncing GPS batch: $e');
      }
    }

    await _saveLocalQueues();
    notifyListeners();
  }

  void sendLocationUpdate({required double lat, required double lng, double speed = 0, double heading = 0}) {
    final payload = {
      'driverId': _driverProfile?['id'],
      'requestId': _activeRequest?['id'] ?? _activeRequest?['requestId'],
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_socket != null && _socket!.connected) {
      _socket!.emit('driver:location', payload);
    } else {
      _isNetworkConnected = false;
      _queuedGpsUpdates.add(payload);
      _saveLocalQueues();
      notifyListeners();
      return;
    }

    // Also send to REST API as fallback
    if (_apiClient != null) {
      _apiClient!.client.post('/driver-app/location', data: payload).catchError((err) {
        _isNetworkConnected = false;
        _queuedGpsUpdates.add(payload);
        _saveLocalQueues();
        notifyListeners();
      });
    }
  }

  void _startCountdown(String requestId) {
    _clearTimer();
    _countdown = 30;
    _assignmentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _countdown--;
        notifyListeners();
      } else {
        rejectTrip(requestId);
      }
    });
  }

  void _clearTimer() {
    _assignmentTimer?.cancel();
    _assignmentTimer = null;
  }

  Future<void> logout() async {
    _clearTimer();
    _stopBackgroundGpsTracking();
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _token = null;
    _driverProfile = null;
    _activeRequest = null;
    _completedToday = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDriverToken);
    notifyListeners();
  }
}
