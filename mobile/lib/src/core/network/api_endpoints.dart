class ApiEndpoints {
  static const String patientRequests = '/patient/requests';
  static String cancelRequest(String requestId) => '/patient/requests/$requestId/cancel';
  static String trackPatientRequest(String requestId) => '/patient/requests/$requestId/track';
  static const String dispatcherRequests = '/dispatcher/requests';
  static String dispatcherTracking(String requestId) => '/dispatcher/requests/$requestId/tracking';
}
