import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../models/admin_request_details_model.dart';

const String apiBaseUrl = 'http://localhost:3000'; 

// Family provider so we can pass the request ID
final adminRequestDetailsProvider = ChangeNotifierProvider.family<AdminRequestDetailsProvider, String>((ref, id) {
  return AdminRequestDetailsProvider(id);
});

class AdminRequestDetailsProvider extends ChangeNotifier {
  final String requestId;
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  
  AdminRequestDetails? details;
  bool isLoading = true;
  String? errorMessage;

  AdminRequestDetailsProvider(this.requestId) {
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _dio.get('/admin/requests/$requestId');
      details = AdminRequestDetails.fromJson(res.data);
    } catch (e) {
      errorMessage = 'Failed to load request details: $e';
      print(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
