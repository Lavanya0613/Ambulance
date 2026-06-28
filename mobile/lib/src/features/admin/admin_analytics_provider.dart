import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/admin_analytics_models.dart';
import 'package:dio/dio.dart';

final adminAnalyticsProvider = StateNotifierProvider<AdminAnalyticsNotifier, AdminAnalyticsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AdminAnalyticsNotifier(apiService);
});

class AdminAnalyticsState {
  final bool isLoading;
  final String? errorMessage;
  final AnalyticsDashboardData? data;

  AdminAnalyticsState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  AdminAnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    AnalyticsDashboardData? data,
  }) {
    return AdminAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
    );
  }
}

class AdminAnalyticsNotifier extends StateNotifier<AdminAnalyticsState> {
  final ApiService _apiService;

  AdminAnalyticsNotifier(this._apiService) : super(AdminAnalyticsState()) {
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.dio.get('/admin/analytics');
      if (response.statusCode == 200) {
        final data = AnalyticsDashboardData.fromJson(response.data);
        state = state.copyWith(isLoading: false, data: data);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load analytics: ${response.statusCode}');
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message ?? 'Failed to load analytics');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
