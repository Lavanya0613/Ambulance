import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/ambulance_api_service.dart';
import '../domain/ambulance_repository.dart';
import '../domain/ambulance_service.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final ambulanceApiServiceProvider = Provider<AmbulanceApiService>((ref) {
  return AmbulanceApiService(ref.read(dioClientProvider));
});

final ambulanceRepositoryProvider = Provider<AmbulanceRepository>((ref) {
  return AmbulanceRepository(ref.read(ambulanceApiServiceProvider));
});

final ambulanceServiceProvider = Provider<AmbulanceService>((ref) {
  return AmbulanceService(ref.read(ambulanceRepositoryProvider));
});
