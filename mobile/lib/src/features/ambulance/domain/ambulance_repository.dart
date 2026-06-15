import '../data/ambulance_api_service.dart';
import '../models/cancel_ambulance_request.dart';
import '../models/cancel_ambulance_response.dart';
import '../models/request_ambulance_request.dart';
import '../models/request_ambulance_response.dart';
import '../models/tracking_snapshot_response.dart';

class AmbulanceRepository {
  AmbulanceRepository(this._apiService);

  final AmbulanceApiService _apiService;

  Future<RequestAmbulanceResponse> requestAmbulance(RequestAmbulanceRequest request) {
    return _apiService.requestAmbulance(request);
  }

  Future<CancelAmbulanceResponse> cancelAmbulance(String requestId, CancelAmbulanceRequest request) {
    return _apiService.cancelAmbulance(requestId, request);
  }

  Future<TrackingSnapshotResponse> getPatientTrackingSnapshot(String requestId) {
    return _apiService.getPatientTrackingSnapshot(requestId);
  }

  Future<TrackingSnapshotResponse> getDispatcherTrackingSnapshot(String requestId, {DateTime? since}) {
    return _apiService.getDispatcherTrackingSnapshot(requestId, since: since);
  }
}
