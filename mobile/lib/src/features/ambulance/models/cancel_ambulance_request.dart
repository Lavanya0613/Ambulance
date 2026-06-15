class CancelAmbulanceRequest {
  final String reasonCode;
  final String? reasonText;

  const CancelAmbulanceRequest({required this.reasonCode, this.reasonText});

  Map<String, dynamic> toJson() => {
        'reasonCode': reasonCode,
        if (reasonText != null) 'reasonText': reasonText,
      };
}
