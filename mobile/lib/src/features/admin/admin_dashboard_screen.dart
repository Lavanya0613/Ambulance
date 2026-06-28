import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_dashboard_provider.dart';
import '../../models/admin_dashboard_models.dart';
import 'package:intl/intl.dart';
import 'admin_request_details_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to rebuild when state changes
    final provider = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF76B82A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!provider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                    SizedBox(width: 8),
                    Text('Live Sync', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'View Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading && provider.metrics == null
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: () => provider.fetchInitialData(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Operations Overview',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E3A5F)),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricsRow(provider.metrics!),
                        const SizedBox(height: 32),
                        const Text(
                          'Recent Requests',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E3A5F)),
                        ),
                        const SizedBox(height: 16),
                        _buildRequestsTable(provider.requests),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMetricsRow(DashboardMetrics metrics) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMetricCard('Pending\nRequests', metrics.pendingRequests, Colors.orange),
          _buildMetricCard('Assigned', metrics.assignedRequests, Colors.blue),
          _buildMetricCard('In Progress', metrics.inProgressRequests, Colors.purple),
          _buildMetricCard('Completed', metrics.completedRequests, Colors.green),
          _buildMetricCard('Cancelled', metrics.cancelledRequests, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, int count, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTable(List<AdminRequestItem> requests) {
    if (requests.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No recent requests found.')),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Request No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Pickup', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Vendor', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Created Time', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: requests.map((req) {
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminRequestDetailsScreen(requestId: req.id),
                  ),
                );
              },
              cells: [
                DataCell(Text(req.requestNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(req.patientName)),
                DataCell(SizedBox(width: 150, child: Text(req.pickupAddress, overflow: TextOverflow.ellipsis))),
                DataCell(_buildStatusChip(req.status)),
                DataCell(Text(req.vendorName ?? '-')),
                DataCell(Text(req.createdAt != null ? DateFormat('HH:mm').format(req.createdAt!) : '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String displayStatus;

    switch (status) {
      case 'PENDING':
      case 'REQUEST_CREATED':
        displayStatus = 'Pending';
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'SEARCHING_DRIVER':
      case 'SEARCHING_VENDOR':
        displayStatus = 'Searching Vendor';
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'VENDOR_ACCEPTED':
      case 'DRIVER_ASSIGNED':
        displayStatus = 'Assigned';
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'EN_ROUTE':
        displayStatus = 'Driver Arriving';
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'ARRIVED':
      case 'PATIENT_ONBOARD':
        displayStatus = 'Patient Picked';
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'COMPLETED':
        displayStatus = 'Completed';
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'CANCELLED':
      case 'FAILED':
        displayStatus = 'Cancelled';
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        displayStatus = status;
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
