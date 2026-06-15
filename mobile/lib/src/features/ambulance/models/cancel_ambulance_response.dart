class CancelAmbulanceResponse {
  final String requestId;
  final DateTime cancelledAt;
  final String status;
  final String? message;

  const CancelAmbulanceResponse({required this.requestId, required this.cancelledAt, required this.status, this.message});

  factory CancelAmbulanceResponse.fromJson(Map<String, dynamic> json) => CancelAmbulanceResponse(
        requestId: json['requestId'] as String,
        cancelledAt: DateTime.parse(json['cancelledAt'] as String),
        status: json['status'] as String,
        message: json['message'] as String?,
      );
}
