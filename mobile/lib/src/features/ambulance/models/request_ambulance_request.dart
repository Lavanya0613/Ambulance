import 'location_dto.dart';
import 'patient_info_dto.dart';

class RequestAmbulanceRequest {
  final String idempotencyKey;
  final LocationDto pickup;
  final LocationDto drop;
  final String priority;
  final PatientInfoDto patient;
  final String? notes;

  const RequestAmbulanceRequest({
    required this.idempotencyKey,
    required this.pickup,
    required this.drop,
    required this.patient,
    this.priority = 'normal',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'pickup': pickup.toJson(),
        'drop': drop.toJson(),
        'priority': priority,
        'patient': patient.toJson(),
        if (notes != null) 'notes': notes,
      };
}
