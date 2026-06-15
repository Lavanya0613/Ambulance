import 'location_dto.dart';
import 'patient_info_dto.dart';

class AssignedVendorDto {
  final String? vendorId;
  final String? vendorBookingRef;

  const AssignedVendorDto({this.vendorId, this.vendorBookingRef});

  factory AssignedVendorDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AssignedVendorDto();
    return AssignedVendorDto(
      vendorId: json['vendorId'] as String?,
      vendorBookingRef: json['vendorBookingRef'] as String?,
    );
  }
}

class RequestAmbulanceResponse {
  final String requestId;
  final String requestNumber;
  final String status;
  final DateTime createdAt;
  final AssignedVendorDto? assignedVendor;
  final String? message;

  const RequestAmbulanceResponse({
    required this.requestId,
    required this.requestNumber,
    required this.status,
    required this.createdAt,
    this.assignedVendor,
    this.message,
  });

  factory RequestAmbulanceResponse.fromJson(Map<String, dynamic> json) => RequestAmbulanceResponse(
        requestId: json['requestId'] as String,
        requestNumber: json['requestNumber'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        assignedVendor: AssignedVendorDto.fromJson(json['assignedVendor'] as Map<String, dynamic>?),
        message: json['message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'requestNumber': requestNumber,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        if (assignedVendor != null)
          'assignedVendor': {
            if (assignedVendor!.vendorId != null) 'vendorId': assignedVendor!.vendorId,
            if (assignedVendor!.vendorBookingRef != null) 'vendorBookingRef': assignedVendor!.vendorBookingRef,
          },
        if (message != null) 'message': message,
      };
}
