import '../data/request_repository.dart';

class RequestService {
  final RequestRepository repository;
  RequestService(this.repository);

  Future createRequest(Map<String, dynamic> payload) async {
    // business logic, validation, enrich payload, etc.
    return repository.createRequest(payload);
  }

  Future cancelRequest(String requestId, String reasonCode, {String? reasonText}) async {
    final body = {'reasonCode': reasonCode, 'reasonText': reasonText};
    return repository.cancelRequest(requestId, body);
  }
}
