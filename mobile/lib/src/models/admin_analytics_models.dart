class DailyRequestData {
  final String date;
  final int count;

  DailyRequestData({required this.date, required this.count});

  factory DailyRequestData.fromJson(Map<String, dynamic> json) {
    return DailyRequestData(
      date: json['date'] as String,
      count: json['count'] as int,
    );
  }
}

class StatusRequestData {
  final String status;
  final int count;

  StatusRequestData({required this.status, required this.count});

  factory StatusRequestData.fromJson(Map<String, dynamic> json) {
    return StatusRequestData(
      status: json['status'] as String,
      count: json['count'] as int,
    );
  }
}

class TopPickupArea {
  final String area;
  final int count;

  TopPickupArea({required this.area, required this.count});

  factory TopPickupArea.fromJson(Map<String, dynamic> json) {
    return TopPickupArea(
      area: json['area'] as String,
      count: json['count'] as int,
    );
  }
}

class VendorPerformanceData {
  final String vendorId;
  final String name;
  final int completed;
  final int cancelled;
  final double avgEta;

  VendorPerformanceData({
    required this.vendorId,
    required this.name,
    required this.completed,
    required this.cancelled,
    required this.avgEta,
  });

  factory VendorPerformanceData.fromJson(Map<String, dynamic> json) {
    return VendorPerformanceData(
      vendorId: json['vendorId'] as String,
      name: json['name'] as String,
      completed: json['completed'] as int,
      cancelled: json['cancelled'] as int,
      avgEta: (json['avgEta'] as num).toDouble(),
    );
  }
}

class AnalyticsDashboardData {
  final List<DailyRequestData> requestsPerDay;
  final List<StatusRequestData> requestsPerStatus;
  final int averageEtaSeconds;
  final int averageCompletionTimeSeconds;
  final List<TopPickupArea> topPickupAreas;
  final double cancellationRate;
  final List<VendorPerformanceData> vendorPerformance;

  AnalyticsDashboardData({
    required this.requestsPerDay,
    required this.requestsPerStatus,
    required this.averageEtaSeconds,
    required this.averageCompletionTimeSeconds,
    required this.topPickupAreas,
    required this.cancellationRate,
    required this.vendorPerformance,
  });

  factory AnalyticsDashboardData.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboardData(
      requestsPerDay: (json['requestsPerDay'] as List).map((e) => DailyRequestData.fromJson(e)).toList(),
      requestsPerStatus: (json['requestsPerStatus'] as List).map((e) => StatusRequestData.fromJson(e)).toList(),
      averageEtaSeconds: json['averageEtaSeconds'] as int,
      averageCompletionTimeSeconds: json['averageCompletionTimeSeconds'] as int,
      topPickupAreas: (json['topPickupAreas'] as List).map((e) => TopPickupArea.fromJson(e)).toList(),
      cancellationRate: (json['cancellationRate'] as num).toDouble(),
      vendorPerformance: (json['vendorPerformance'] as List).map((e) => VendorPerformanceData.fromJson(e)).toList(),
    );
  }
}
