const String apiBaseUrl = 'http://localhost:3000';

class ApiEndpoints {
  // Patient
  static const String patientRequests = '/patient/requests';
  static String patientRequestTrack(String id) => '/patient/requests/$id/track';
  static String patientRequestCancel(String id) => '/patient/requests/$id/cancel';

  // WebSocket
  static const String wsNamespace = '/ws';
}
