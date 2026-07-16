import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class AmbulanceRequest {
  final String requestId;
  final String requestNumber;
  final String status;
  final String patientName;
  final String? pickupAddress;
  final String? dropAddress;
  final String createdAt;
  final String updatedAt;
  final int? etaSeconds;

  const AmbulanceRequest({
    required this.requestId,
    required this.requestNumber,
    required this.status,
    required this.patientName,
    this.pickupAddress,
    this.dropAddress,
    required this.createdAt,
    required this.updatedAt,
    this.etaSeconds,
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
      etaSeconds: j['etaSeconds'] as int?,
    );
  }
}

class RequestsProvider extends ChangeNotifier {
  final DioClient _client;
  RequestsProvider(this._client);

  bool _disposed = false;
  List<AmbulanceRequest> _all = [];
  bool isLoading = false;
  String? errorMsg;
  String searchQuery = '';
  String statusFilter = 'ALL';

  List<AmbulanceRequest> get filtered {
    return _all.where((r) {
      final matchStatus = statusFilter == 'ALL' || r.status == statusFilter;
      final q = searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          r.patientName.toLowerCase().contains(q) ||
          (r.pickupAddress ?? '').toLowerCase().contains(q) ||
          (r.dropAddress ?? '').toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  void setSearch(String q) {
    searchQuery = q;
    if (!_disposed) notifyListeners();
  }

  void setFilter(String f) {
    statusFilter = f;
    if (!_disposed) notifyListeners();
  }

  Future<void> fetchRequests() async {
    isLoading = true;
    errorMsg = null;
    if (!_disposed) notifyListeners();
    try {
      final res = await _client.client.get(ApiEndpoints.patientRequests);
      final data = res.data['data'] ?? res.data;
      if (data is List) {
        _all = data.map((e) => AmbulanceRequest.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      errorMsg = 'Failed to load requests. Check your connection.';
    } catch (e) {
      errorMsg = 'Unexpected error.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _client.client.post(
        ApiEndpoints.patientRequestCancel(requestId),
        data: {'reasonCode': 'patient_cancelled'},
      );
      await fetchRequests();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
