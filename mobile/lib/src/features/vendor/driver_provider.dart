import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';

class DriverProvider extends ChangeNotifier {
  DioClient? _apiClient;

  List<Map<String, dynamic>> drivers = [];
  bool isLoading = false;
  
  String? searchQuery;
  String? statusFilter; // 'AVAILABLE', 'BUSY', 'OFFLINE'
  
  bool _disposed = false;

  void updateApiClient(DioClient client) {
    _apiClient = client;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    fetchDrivers();
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    if (_apiClient == null) return;
    isLoading = true;
    if (!_disposed) notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (statusFilter != null && statusFilter!.isNotEmpty) {
        queryParams['status'] = statusFilter;
      }

      final response = await _apiClient!.client.get(
        '/vendor/drivers',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      drivers = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> createDriver(String name, String phone, String vehicleNumber, String ambulanceType) async {
    if (_apiClient == null) return false;
    
    try {
      await _apiClient!.client.post('/vendor/drivers', data: {
        'name': name,
        'phone': phone,
        'vehicleNumber': vehicleNumber,
        'ambulanceType': ambulanceType,
      });
      await fetchDrivers();
      return true;
    } catch (e) {
      debugPrint('Error creating driver: $e');
      return false;
    }
  }

  Future<bool> updateDriverStatus(String id, String status) async {
    if (_apiClient == null) return false;
    
    // Optimistic update
    final driverIndex = drivers.indexWhere((d) => d['id'] == id);
    String? previousStatus;
    if (driverIndex != -1) {
      previousStatus = drivers[driverIndex]['status'];
      drivers[driverIndex]['status'] = status;
      if (!_disposed) notifyListeners();
    }

    try {
      await _apiClient!.client.patch('/vendor/drivers/$id/status', data: {
        'status': status,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      // Revert optimistic update
      if (driverIndex != -1 && previousStatus != null) {
        drivers[driverIndex]['status'] = previousStatus;
        if (!_disposed) notifyListeners();
      }
      return false;
    }
  }
}
