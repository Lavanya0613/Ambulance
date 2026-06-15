import '../models/cancel_ambulance_request.dart';
import '../models/cancel_ambulance_response.dart';
import '../models/location_dto.dart';
import '../models/patient_info_dto.dart';
import '../models/request_ambulance_request.dart';
import '../models/request_ambulance_response.dart';
import '../models/tracking_snapshot_response.dart';
import 'ambulance_repository.dart';

class AmbulanceService {
  AmbulanceService(this._repository);

  final AmbulanceRepository _repository;

  Future<RequestAmbulanceResponse> requestAmbulance({
    required String idempotencyKey,
    required LocationDto pickup,
    required LocationDto drop,
    required PatientInfoDto patient,
    String priority = 'normal',
    String? notes,
  }) {
    final request = RequestAmbulanceRequest(
      idempotencyKey: idempotencyKey,
      pickup: pickup,
      drop: drop,
      patient: patient,
      priority: priority,
      notes: notes,
    );
    return _repository.requestAmbulance(request);
  }

  Future<CancelAmbulanceResponse> cancelAmbulance({
    required String requestId,
    required String reasonCode,
    String? reasonText,
  }) {
    final request = CancelAmbulanceRequest(reasonCode: reasonCode, reasonText: reasonText);
    return _repository.cancelAmbulance(requestId, request);
  }

  Future<TrackingSnapshotResponse> getPatientTrackingSnapshot(String requestId) {
    return _repository.getPatientTrackingSnapshot(requestId);
  }

  Future<TrackingSnapshotResponse> getDispatcherTrackingSnapshot(String requestId, {DateTime? since}) {
    return _repository.getDispatcherTrackingSnapshot(requestId, since: since);
  }
}
