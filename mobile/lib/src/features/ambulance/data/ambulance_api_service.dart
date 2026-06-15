import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/cancel_ambulance_request.dart';
import '../models/cancel_ambulance_response.dart';
import '../models/request_ambulance_request.dart';
import '../models/request_ambulance_response.dart';
import '../models/tracking_snapshot_response.dart';

class AmbulanceApiService {
  AmbulanceApiService(this._dioClient);

  final DioClient _dioClient;

  Future<RequestAmbulanceResponse> requestAmbulance(RequestAmbulanceRequest request) async {
    final response = await _dioClient.client.post(
      ApiEndpoints.patientRequests,
      data: request.toJson(),
    );
    return RequestAmbulanceResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CancelAmbulanceResponse> cancelAmbulance(String requestId, CancelAmbulanceRequest request) async {
    final response = await _dioClient.client.post(
      ApiEndpoints.cancelRequest(requestId),
      data: request.toJson(),
    );
    return CancelAmbulanceResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TrackingSnapshotResponse> getPatientTrackingSnapshot(String requestId) async {
    final response = await _dioClient.client.get(ApiEndpoints.trackPatientRequest(requestId));
    return TrackingSnapshotResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TrackingSnapshotResponse> getDispatcherTrackingSnapshot(String requestId, {DateTime? since}) async {
    final response = await _dioClient.client.get(
      ApiEndpoints.dispatcherTracking(requestId),
      queryParameters: since == null ? null : {'since': since.toIso8601String()},
    );
    return TrackingSnapshotResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
