import 'package:flutter/material.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../../main.dart';

class VendorProvider extends ChangeNotifier {
  bool _disposed = false;
  socket_io.Socket? _socket;
  DioClient? _apiClient;

  DioClient? get apiClient => _apiClient;

  // Mock Authentication state
  bool isLoggedIn = false;
  
  // This is a mock token generated with { role: 'admin' } so we can join the dispatcher-room
  final String vendorToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtb2NrLXZlbmRvci1pZCIsImlkIjoibW9jay12ZW5kb3ItaWQiLCJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3ODE4NDMwMDUsImV4cCI6NDkzNzYwMzAwNX0.mock_signature';

  // Requests Data
  List<Map<String, dynamic>> activeRequests = [];
  List<Map<String, dynamic>> completedRequests = [];
  bool isLoading = false;
  String? errorMessage;
  
  Map<String, dynamic>? dashboardStats;

  // Track action loading state by request ID
  String? loadingActionId;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    if (!_disposed) notifyListeners();

    // Mock login delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (email.isNotEmpty && password.isNotEmpty) {
      isLoggedIn = true;
      _apiClient = DioClient(tokenProvider: () async => vendorToken);
      
      await fetchRequests();
      _initWebSocket();
      
      isLoading = false;
      if (!_disposed) notifyListeners();
      return true;
    }
    
    isLoading = false;
    if (!_disposed) notifyListeners();
    return false;
  }

  Future<void> fetchRequests() async {
    if (_apiClient == null) return;
    errorMessage = null;
    try {
      final response = await _apiClient!.client.get('/dispatcher/requests?limit=100');
      final data = response.data['data'] as List;
      
      final active = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];
      
      for (var item in data) {
        final map = item as Map<String, dynamic>;
        final reqNum = (map['requestNumber'] ?? '').toString();
        
        // Skip AR-DEMO seed data if present
        if (reqNum.startsWith('AR-DEMO')) continue;

        map['isNew'] = false; // Initialize flag
        if (map['status'] == 'COMPLETED' || map['status'] == 'CANCELLED') {
          completed.add(map);
        } else {
          active.add(map);
        }
      }
      
      activeRequests = active;
      completedRequests = completed;
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      errorMessage = 'Unable to load bookings. Check backend connection.';
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> acceptRequest(String id) async {
    if (_apiClient == null) return;
    loadingActionId = id;
    if (!_disposed) notifyListeners();

    try {
      await _apiClient!.client.post('/dispatcher/requests/$id/accept');
      // Success: status_updated websocket event will automatically move it!
    } catch (e) {
      debugPrint('Error accepting request: $e');
    } finally {
      loadingActionId = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> rejectRequest(String id) async {
    if (_apiClient == null) return;
    loadingActionId = id;
    if (!_disposed) notifyListeners();

    try {
      await _apiClient!.client.post('/dispatcher/requests/$id/reject');
      // Success: status_updated websocket event will automatically move it!
      await fetchRequests();
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    } finally {
      loadingActionId = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> assignDriver(String requestId, String driverId, String vehicleId) async {
    if (_apiClient == null) return;
    loadingActionId = requestId;
    if (!_disposed) notifyListeners();

    try {
      await _apiClient!.client.post('/dispatcher/requests/$requestId/assign-driver', data: {
        'driverId': driverId,
        'vehicleId': vehicleId,
        'etaSeconds': 300,
      });
      await fetchRequests();
    } catch (e) {
      debugPrint('Error assigning driver: $e');
    } finally {
      loadingActionId = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> updateTripStatus(String requestId, String status) async {
    if (_apiClient == null) return;
    loadingActionId = requestId;
    if (!_disposed) notifyListeners();

    try {
      await _apiClient!.client.patch('/dispatcher/requests/$requestId/status', data: {
        'status': status,
      });
      await fetchRequests();
    } catch (e) {
      debugPrint('Error updating trip status: $e');
    } finally {
      loadingActionId = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> fetchDashboardStats() async {
    if (_apiClient == null) return;
    try {
      final response = await _apiClient!.client.get('/vendor/dashboard');
      dashboardStats = response.data;
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
    }
  }



  void logout() {
    isLoggedIn = false;
    activeRequests.clear();
    completedRequests.clear();
    _socket?.disconnect();
    _socket = null;
    _apiClient = null;
    if (!_disposed) notifyListeners();
  }

  void _initWebSocket() {
    _socket = socket_io.io(ApiEndpoints.wsUrl, socket_io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setPath('/ws/socket.io')
        .setAuth({'token': vendorToken})
        .enableForceNew()
        .build());

    _socket?.onConnect((_) {
      debugPrint('Vendor Socket connected to dispatcher-room');
    });

    _socket?.on('request_created', (data) {
      debugPrint('New request created: $data');
      final map = Map<String, dynamic>.from(data);
      map['isNew'] = true;
      // In request_created, the object may not have all fields if it's sparse, 
      // but usually the backend sends the full entity.
      activeRequests.insert(0, map);
      if (!_disposed) notifyListeners();
      
      _showNotification('New Booking Received!', Colors.orange);
      fetchDashboardStats();
    });

    _socket?.on('status_updated', (data) {
      debugPrint('Status updated: $data');
      final id = data['requestId'];
      final status = data['status'];
      
      // Find in active requests
      final index = activeRequests.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        if (status == 'COMPLETED' || status == 'CANCELLED') {
          final req = activeRequests.removeAt(index);
          req['status'] = status;
          req['isNew'] = false;
          completedRequests.insert(0, req);
          
          if (status == 'COMPLETED') _showNotification('Trip Completed!', Colors.green);
          if (status == 'CANCELLED') _showNotification('Booking Cancelled', Colors.red);
        } else {
          activeRequests[index]['status'] = status;
          if (status == 'DRIVER_ASSIGNED') _showNotification('Driver Assigned!', Colors.blue);
        }
        if (!_disposed) notifyListeners();
        fetchDashboardStats();
      } else {
        // If not found locally, refetch requests list
        fetchRequests();
        fetchDashboardStats();
      }
    });

    _socket?.on('location_updated', (data) {
      final id = data['requestId'];
      final lat = data['lat'];
      final lng = data['lng'];
      final index = activeRequests.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        activeRequests[index]['lat'] = lat;
        activeRequests[index]['lng'] = lng;
        if (!_disposed) notifyListeners();
      }
    });

    _socket?.on('driver_assigned', (data) {
      debugPrint('Driver assigned: $data');
      fetchRequests();
      fetchDashboardStats();
    });

    _socket?.onDisconnect((_) {
      debugPrint('Vendor Socket disconnected');
    });
  }

  void _showNotification(String message, Color color) {
    if (scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
