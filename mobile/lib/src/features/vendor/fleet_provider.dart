import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';

class FleetProvider extends ChangeNotifier {
  DioClient? _apiClient;

  List<Map<String, dynamic>> ambulances = [];
  bool isLoading = false;
  
  String? searchQuery;
  String? statusFilter; // 'AVAILABLE', 'OUT_OF_SERVICE', 'BUSY'
  
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
    fetchAmbulances();
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    fetchAmbulances();
  }

  Future<void> fetchAmbulances() async {
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
        '/vendor/ambulances',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      ambulances = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching ambulances: $e');
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> createAmbulance(String vehicleNumber, String ambulanceType) async {
    if (_apiClient == null) return false;
    
    try {
      await _apiClient!.client.post('/vendor/ambulances', data: {
        'vehicleNumber': vehicleNumber,
        'ambulanceType': ambulanceType,
      });
      await fetchAmbulances();
      return true;
    } catch (e) {
      debugPrint('Error creating ambulance: $e');
      return false;
    }
  }

  Future<bool> updateAmbulanceStatus(String id, String status) async {
    if (_apiClient == null) return false;
    
    // Optimistic update
    final index = ambulances.indexWhere((a) => a['id'] == id);
    String? previousStatus;
    if (index != -1) {
      previousStatus = ambulances[index]['status'];
      ambulances[index]['status'] = status;
      if (!_disposed) notifyListeners();
    }

    try {
      await _apiClient!.client.patch('/vendor/ambulances/$id/status', data: {
        'status': status,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating ambulance status: $e');
      // Revert optimistic update
      if (index != -1 && previousStatus != null) {
        ambulances[index]['status'] = previousStatus;
        if (!_disposed) notifyListeners();
      }
      return false;
    }
  }
}
