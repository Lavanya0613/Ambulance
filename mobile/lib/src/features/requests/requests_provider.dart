import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class OrderDriverInfo {
  final String name;
  final String phoneE164;
  final String vehicleNumber;
  final String ambulanceType;

  const OrderDriverInfo({
    required this.name,
    required this.phoneE164,
    required this.vehicleNumber,
    required this.ambulanceType,
  });

  factory OrderDriverInfo.fromJson(Map<String, dynamic> j) {
    return OrderDriverInfo(
      name: j['name'] as String? ?? 'Unknown',
      phoneE164: j['phoneE164'] as String? ?? '',
      vehicleNumber: j['vehicleNumber'] as String? ?? '',
      ambulanceType: j['ambulanceType'] as String? ?? 'Standard',
    );
  }
}

class AmbulanceRequest {
  final String requestId;
  final String requestNumber;
  final String status;
  final String patientName;
  final String? pickupAddress;
  final String? dropAddress;
  final String createdAt;
  final String updatedAt;
  final String? scheduledFor;
  final int? etaSeconds;
  final OrderDriverInfo? driver;
  final double? totalPayable;
  final double? baseFare;

  const AmbulanceRequest({
    required this.requestId,
    required this.requestNumber,
    required this.status,
    required this.patientName,
    this.pickupAddress,
    this.dropAddress,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledFor,
    this.etaSeconds,
    this.driver,
    this.totalPayable,
    this.baseFare,
  });

  factory AmbulanceRequest.fromJson(Map<String, dynamic> j) {
    return AmbulanceRequest(
      requestId: j['requestId'] as String? ?? j['id'] as String? ?? '',
      requestNumber: j['requestNumber'] as String? ?? '',
      status: j['status'] as String? ?? 'PENDING',
      patientName: j['patientName'] as String? ?? '',
      pickupAddress: j['pickupAddress'] as String?,
      dropAddress: j['dropAddress'] as String? ?? j['destinationAddress'] as String?,
      createdAt: j['createdAt'] as String? ?? '',
      updatedAt: j['updatedAt'] as String? ?? '',
      scheduledFor: j['scheduledFor'] as String?,
      etaSeconds: j['etaSeconds'] as int?,
      driver: j['driver'] != null ? OrderDriverInfo.fromJson(j['driver']) : null,
      totalPayable: (j['totalPayable'] as num?)?.toDouble(),
      baseFare: (j['baseFare'] as num?)?.toDouble(),
    );
  }

  AmbulanceRequest copyWith({
    String? status,
    int? etaSeconds,
    OrderDriverInfo? driver,
    double? totalPayable,
    double? baseFare,
    String? scheduledFor,
  }) {
    return AmbulanceRequest(
      requestId: requestId,
      requestNumber: requestNumber,
      status: status ?? this.status,
      patientName: patientName,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      createdAt: createdAt,
      updatedAt: updatedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      driver: driver ?? this.driver,
      totalPayable: totalPayable ?? this.totalPayable,
      baseFare: baseFare ?? this.baseFare,
    );
  }
}

class RequestsProvider extends ChangeNotifier {
  final DioClient _client;
  RequestsProvider(this._client) {
    _initSocket();
  }

  bool _disposed = false;
  IO.Socket? _socket;
  
  List<AmbulanceRequest> orders = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMsg;

  @override
  void dispose() {
    _disposed = true;
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    _socket = IO.io(ApiEndpoints.wsUrl.replaceFirst('/api', ''), IO.OptionBuilder()
      .setPath('/ws/socket.io')
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    _socket!.on('status_updated', _handleEvent);
    _socket!.on('trip_updated', _handleEvent);
    _socket!.on('driver_assigned', _handleEvent);
    _socket!.on('eta_updated', _handleEvent);
    _socket!.connect();
  }

  void _handleEvent(dynamic data) {
    if (data is! Map || _disposed) return;
    
    final String? reqId = data['requestId'];
    if (reqId == null) return;

    final index = orders.indexWhere((o) => o.requestId == reqId);
    if (index == -1) return;

    final existing = orders[index];
    final String? newStatus = data['status'];
    final int? newEta = data['etaSeconds'] is int ? data['etaSeconds'] : null;
    final driverData = data['driver'];
    final OrderDriverInfo? newDriver = driverData is Map ? OrderDriverInfo.fromJson(driverData as Map<String, dynamic>) : null;

    // Only update if there are changes
    if (newStatus != null || newEta != null || newDriver != null) {
      orders[index] = existing.copyWith(
        status: newStatus,
        etaSeconds: newEta,
        driver: newDriver,
      );
      
      // If the new status makes it no longer match the current filter, optionally remove it.
      // But it's usually better to just leave it until refresh so it doesn't vanish while looking at it.
      notifyListeners();
    }
  }
  
  String statusFilter = 'ALL';
  int currentPage = 1;
  bool hasMore = true;

  void setFilter(String f) {
    if (statusFilter == f) return;
    statusFilter = f;
    fetchRequests(refresh: true);
  }

  Future<void> fetchRequests({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      hasMore = true;
      isLoading = true;
      errorMsg = null;
    } else {
      if (!hasMore || isLoadingMore || isLoading) return;
      isLoadingMore = true;
    }
    
    if (!_disposed) notifyListeners();

    try {
      final queryParams = {
        'page': currentPage,
        'limit': 10,
        'sortBy': 'createdAt',
        'sortOrder': 'DESC',
      };
      
      if (statusFilter != 'ALL') {
        // Map UI tabs to backend statuses if needed, or send exactly as is.
        queryParams['status'] = statusFilter;
      }

      final res = await _client.client.get(ApiEndpoints.patientRequests, queryParameters: queryParams);
      
      final data = res.data['data'] as List?;
      final meta = res.data['meta'] as Map?;

      if (data != null) {
        final fetched = data.map((e) => AmbulanceRequest.fromJson(e as Map<String, dynamic>)).toList();
        
        if (refresh) {
          orders = fetched;
        } else {
          orders.addAll(fetched);
        }
        
        if (meta != null) {
          final totalPages = meta['totalPages'] as int? ?? 1;
          hasMore = currentPage < totalPages;
        } else {
          hasMore = fetched.length >= 10;
        }
        
        if (hasMore) currentPage++;
      }
    } on DioException catch (_) {
      if (refresh) {
        errorMsg = 'Failed to load requests. Check your connection.';
      }
    } catch (_) {
      if (refresh) {
        errorMsg = 'Unexpected error.';
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> cancelRequest(String requestId, [String reasonCode = 'patient_cancelled']) async {
    try {
      await _client.client.post(
        ApiEndpoints.patientRequestCancel(requestId),
        data: {'reasonCode': reasonCode},
      );
      
      // Update local state without full refresh if possible, or just refresh
      final index = orders.indexWhere((r) => r.requestId == requestId);
      if (index != -1) {
        final old = orders[index];
        orders[index] = AmbulanceRequest(
          requestId: old.requestId,
          requestNumber: old.requestNumber,
          status: 'CANCELLED',
          patientName: old.patientName,
          pickupAddress: old.pickupAddress,
          dropAddress: old.dropAddress,
          createdAt: old.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          etaSeconds: old.etaSeconds,
          driver: old.driver,
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

}
