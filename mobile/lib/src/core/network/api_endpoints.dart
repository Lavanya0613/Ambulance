import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String nodeBackendUrlDefault = String.fromEnvironment(
  'NODE_BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);

const String javaBackendUrlDefault = String.fromEnvironment(
  'JAVA_BACKEND_URL',
  defaultValue: 'http://localhost:8081',
);

const String activeBackendDefault = String.fromEnvironment(
  'ACTIVE_BACKEND',
  defaultValue: 'JAVA',
);

const String apiBaseUrlDefault = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String get nodeBackendUrl => dotenv.env['NODE_BACKEND_URL'] ?? nodeBackendUrlDefault;
String get javaBackendUrl {
  final raw = dotenv.env['JAVA_BACKEND_URL'] ?? javaBackendUrlDefault;
  if (kIsWeb && raw.contains('localhost')) {
    final currentHost = Uri.base.host;
    if (currentHost.isNotEmpty && currentHost != 'localhost' && currentHost != '127.0.0.1') {
      return raw.replaceAll('localhost', currentHost).replaceAll('127.0.0.1', currentHost);
    }
  }
  return raw;
}

String get activeBackend => dotenv.env['ACTIVE_BACKEND'] ?? activeBackendDefault;

String get apiBaseUrl {
  if (apiBaseUrlDefault.isNotEmpty) return apiBaseUrlDefault;
  final envExplicitUrl = dotenv.env['API_BASE_URL'];
  if (envExplicitUrl != null && envExplicitUrl.isNotEmpty) return envExplicitUrl;

  return activeBackend.toUpperCase() == 'NODE' ? nodeBackendUrl : javaBackendUrl;
}


class ApiEndpoints {
  // Patient
  static const String patientRequests = '/patient/requests';
  static String patientRequestTrack(String id) => '/patient/requests/$id/track';
  static String patientRequestCancel(String id) => '/patient/requests/$id/cancel';

  // Payment
  static String initiatePayment(String id) => '/patient/requests/$id/payment/initiate';
  static String processPayment(String id) => '/patient/requests/$id/payment/process';
  static String paymentStatus(String id) => '/patient/requests/$id/payment/status';

  // Wallet
  static const String walletBenefit = '/patient/requests/wallet';

  // WebSocket
  static String get wsUrl {
    final explicitWs = dotenv.env['JAVA_WS_URL'];
    if (activeBackend.toUpperCase() == 'JAVA' && explicitWs != null && explicitWs.isNotEmpty) {
      return explicitWs;
    }
    if (activeBackend.toUpperCase() == 'JAVA') {
      if (kIsWeb) {
        final currentHost = Uri.base.host;
        if (currentHost.isNotEmpty && currentHost != 'localhost' && currentHost != '127.0.0.1') {
          return 'http://$currentHost:8085';
        }
      }
      return 'http://localhost:8085';
    }
    return apiBaseUrl;
  }
  static const String wsNamespace = '/ws';
}


