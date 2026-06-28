import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/admin_dashboard_models.dart';
import 'dart:convert';

// Base URL configuration (modify as needed for your environment)
const String apiBaseUrl = 'http://localhost:3000'; // Or use your local IP e.g. 'http://10.0.2.2:3000' for Android emulator

// Define the Riverpod provider for global access
final adminDashboardProvider = ChangeNotifierProvider((ref) => AdminDashboardProvider());

class AdminDashboardProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  IO.Socket? _socket;

  DashboardMetrics? metrics;
  List<AdminRequestItem> requests = [];
  bool isLoading = true;
  String? errorMessage;

  AdminDashboardProvider() {
    _init();
  }

  Future<void> _init() async {
    await fetchInitialData();
    _connectWebsocket();
  }

  Future<void> fetchInitialData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // NOTE: For a real app, an interceptor should add the access_token to headers.
      // Assuming headers are configured or added here.
      
      final metricsRes = await _dio.get('/admin/dashboard');
      final requestsRes = await _dio.get('/admin/requests?limit=100');

      metrics = DashboardMetrics.fromJson(metricsRes.data);
      
      final List dataList = requestsRes.data['data'] ?? [];
      requests = dataList.map((e) => AdminRequestItem.fromJson(e)).toList();

    } catch (e) {
      errorMessage = 'Failed to load dashboard data: $e';
      print(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _connectWebsocket() {
    // For admin namespace, adjust URL and auth token logic as necessary
    _socket = IO.io('$apiBaseUrl/ws', IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': 'TEMP_ADMIN_TOKEN_IF_NEEDED'}) // Replace with real token access
      .build());

    _socket!.onConnect((_) {
      print('Admin websocket connected');
    });

    _socket!.on('request_created', (data) => _handleEvent('request_created', data));
    _socket!.on('request_updated', (data) => _handleEvent('request_updated', data));
    _socket!.on('driver_assigned', (data) => _handleEvent('driver_assigned', data));
    _socket!.on('tracking_updated', (data) => _handleEvent('tracking_updated', data));
    _socket!.on('eta_updated', (data) => _handleEvent('eta_updated', data));
    _socket!.on('request_completed', (data) => _handleEvent('request_completed', data));

    _socket!.connect();
  }

  void _handleEvent(String event, dynamic payload) {
    if (payload is String) {
      payload = jsonDecode(payload);
    }
    
    print('WS Event received: $event');

    // Update requests list
    final id = payload['requestId'] ?? payload['id'];
    if (id != null) {
      final idx = requests.indexWhere((r) => r.id == id);

      if (event == 'request_created') {
        if (idx == -1) {
          requests.insert(0, AdminRequestItem.fromJson(payload));
        }
      } else if (idx != -1) {
        if (event == 'eta_updated') {
          requests[idx] = requests[idx].copyWith(etaSeconds: payload['etaSeconds']);
        } else if (event == 'driver_assigned') {
          requests[idx] = requests[idx].copyWith(
            status: 'DRIVER_ASSIGNED',
            vendorName: payload['vendorDriverName'] ?? payload['vendorName'],
          );
        } else {
          // General status update
          requests[idx] = requests[idx].copyWith(
            status: payload['status'],
          );
        }
      }
    }

    // Update local metrics estimate
    if (metrics != null) {
      if (event == 'request_created') {
        metrics = metrics!.copyWith(
          totalRequests: metrics!.totalRequests + 1,
          pendingRequests: metrics!.pendingRequests + 1,
        );
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
