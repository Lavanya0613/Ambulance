class DashboardMetrics {
  final int totalRequests;
  final int pendingRequests;
  final int assignedRequests;
  final int inProgressRequests;
  final int completedRequests;
  final int cancelledRequests;

  DashboardMetrics({
    required this.totalRequests,
    required this.pendingRequests,
    required this.assignedRequests,
    required this.inProgressRequests,
    required this.completedRequests,
    required this.cancelledRequests,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalRequests: json['totalRequests'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      assignedRequests: json['assignedRequests'] ?? 0,
      inProgressRequests: json['inProgressRequests'] ?? 0,
      completedRequests: json['completedRequests'] ?? 0,
      cancelledRequests: json['cancelledRequests'] ?? 0,
    );
  }

  DashboardMetrics copyWith({
    int? totalRequests,
    int? pendingRequests,
    int? assignedRequests,
    int? inProgressRequests,
    int? completedRequests,
    int? cancelledRequests,
  }) {
    return DashboardMetrics(
      totalRequests: totalRequests ?? this.totalRequests,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      assignedRequests: assignedRequests ?? this.assignedRequests,
      inProgressRequests: inProgressRequests ?? this.inProgressRequests,
      completedRequests: completedRequests ?? this.completedRequests,
      cancelledRequests: cancelledRequests ?? this.cancelledRequests,
    );
  }
}

class AdminRequestItem {
  final String id;
  final String requestNumber;
  final String patientName;
  final String pickupAddress;
  final String destinationAddress;
  final String status;
  final String? vendorName;
  final DateTime? createdAt;
  final int? etaSeconds;

  AdminRequestItem({
    required this.id,
    required this.requestNumber,
    required this.patientName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.status,
    this.vendorName,
    this.createdAt,
    this.etaSeconds,
  });

  factory AdminRequestItem.fromJson(Map<String, dynamic> json) {
    return AdminRequestItem(
      id: json['id'] ?? json['requestId'] ?? '',
      requestNumber: json['requestNumber'] ?? '',
      patientName: json['patientName'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      status: json['status'] ?? 'PENDING',
      vendorName: json['vendorName'] ?? json['vendorDriverName'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      etaSeconds: json['etaSeconds'],
    );
  }

  AdminRequestItem copyWith({
    String? status,
    int? etaSeconds,
    String? vendorName,
  }) {
    return AdminRequestItem(
      id: this.id,
      requestNumber: this.requestNumber,
      patientName: this.patientName,
      pickupAddress: this.pickupAddress,
      destinationAddress: this.destinationAddress,
      status: status ?? this.status,
      vendorName: vendorName ?? this.vendorName,
      createdAt: this.createdAt,
      etaSeconds: etaSeconds ?? this.etaSeconds,
    );
  }
}
