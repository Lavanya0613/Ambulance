import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import 'vendor_provider.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VendorProvider>();
    final stats = prov.dashboardStats;

    if (stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final metrics = (stats['metrics'] as Map<String, dynamic>?) ?? {
      'pendingRequests': stats['pendingRequests'] ?? stats['pending'] ?? 0,
      'assignedRequests': stats['assignedRequests'] ?? stats['assigned'] ?? 0,
      'activeTrips': stats['activeTrips'] ?? stats['active'] ?? 0,
      'completedToday': stats['completedToday'] ?? stats['completed'] ?? 0,
      'availableDrivers': stats['availableDrivers'] ?? stats['driversAvailable'] ?? 0,
      'availableAmbulances': stats['availableAmbulances'] ?? stats['fleetSize'] ?? 0,
    };
    final charts = (stats['charts'] as Map<String, dynamic>?) ?? {
      'hourlyRequests': [2, 4, 3, 7, 5, 8, 4],
      'completionRate': 94.5,
    };
    final tables = (stats['tables'] as Map<String, dynamic>?) ?? {
      'latestRequests': <dynamic>[],
      'activeTrips': <dynamic>[],
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final crossAxisCount = containerWidth > 1100
            ? 6
            : containerWidth > 700
                ? 3
                : containerWidth > 400
                    ? 2
                    : 1;
        final aspectRatio = containerWidth > 1100
            ? 1.4
            : containerWidth > 700
                ? 1.3
                : containerWidth > 400
                    ? 1.4
                    : 2.2;

        return RefreshIndicator(
          onRefresh: () => prov.fetchDashboardStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.darkBlue, AppColors.darkBlue.withOpacity(0.88)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Vendor Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Live operations, trip status, and fleet activity',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                      children: [
                        _buildKpiCard('Pending Requests', metrics['pendingRequests'], Icons.pending_actions, Colors.orange),
                        _buildKpiCard('Assigned Requests', metrics['assignedRequests'], Icons.assignment_ind, Colors.blue),
                        _buildKpiCard('Active Trips', metrics['activeTrips'], Icons.directions_car, Colors.indigo),
                        _buildKpiCard('Completed Today', metrics['completedToday'], Icons.check_circle, Colors.green),
                        _buildKpiCard('Available Drivers', metrics['availableDrivers'], Icons.person, Colors.teal),
                        _buildKpiCard('Available Ambulances', metrics['availableAmbulances'], Icons.medical_services, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (containerWidth > 768)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildBarChartCard(charts)),
                          const SizedBox(width: 16),
                          Expanded(flex: 1, child: _buildPieChartCard(charts)),
                        ],
                      )
                    else ...[
                      _buildBarChartCard(charts),
                      const SizedBox(height: 16),
                      _buildPieChartCard(charts),
                    ],
                    const SizedBox(height: 20),
                    if (containerWidth > 900)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLatestRequestsTable(tables['latestRequests'])),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActiveTripsTable(tables['activeTrips'])),
                        ],
                      )
                    else ...[
                      _buildLatestRequestsTable(tables['latestRequests']),
                      const SizedBox(height: 16),
                      _buildActiveTripsTable(tables['activeTrips']),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(Map<String, dynamic> charts) {
    final List<dynamic> hourly = charts['hourlyRequests'] ?? [];
    
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Requests Today (Hourly)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: hourly.isEmpty ? 10 : (hourly.reduce((a, b) => a > b ? a : b) as int).toDouble() + 2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${value.toInt() * 2}h', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(hourly.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (hourly[i] as int).toDouble(),
                        color: AppColors.darkBlue,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, dynamic> charts) {
    final double completionRate = (charts['completionRate'] as num).toDouble();
    
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Completion Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
          const Spacer(),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.green,
                        value: completionRate,
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: Colors.grey.shade200,
                        value: 100 - completionRate,
                        title: '',
                        radius: 15,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    '${completionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLatestRequestsTable(List<dynamic> requests) {
    return _buildTableCard(
      'Latest Requests',
      requests,
      (req) => DataRow(
        onSelectChanged: (_) {
          if (req['id'] != null) {
            Navigator.pushNamed(context, '/tracking', arguments: {'requestId': req['id']});
          }
        },
        cells: [
          DataCell(Text(req['requestNumber'] ?? req['id']?.toString().substring(0, 8) ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(req['patientName'] ?? req['patient']?['name'] ?? '-')),
          DataCell(_buildStatusChip(req['status'] ?? '')),
          DataCell(
            IconButton(
              icon: const Icon(Icons.location_searching, color: AppColors.darkBlue, size: 20),
              tooltip: 'Track Live Progress',
              onPressed: () {
                if (req['id'] != null) {
                  Navigator.pushNamed(context, '/tracking', arguments: {'requestId': req['id']});
                }
              },
            ),
          ),
        ],
      ),
      ['ID', 'Patient', 'Status', 'Track'],
    );
  }

  Widget _buildActiveTripsTable(List<dynamic> trips) {
    return _buildTableCard(
      'Active Trips',
      trips,
      (trip) => DataRow(
        onSelectChanged: (_) {
          if (trip['id'] != null) {
            Navigator.pushNamed(context, '/tracking', arguments: {'requestId': trip['id']});
          }
        },
        cells: [
          DataCell(Text(trip['requestNumber'] ?? trip['id']?.toString().substring(0, 8) ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(trip['vendorDriverName'] ?? trip['driver']?['name'] ?? 'Assigned Driver')),
          DataCell(Text(trip['vendorVehicleNumber'] ?? trip['vehicle']?['vehicleNumber'] ?? 'Ambulance')),
          DataCell(
            IconButton(
              icon: const Icon(Icons.map, color: AppColors.darkBlue, size: 20),
              tooltip: 'Track Live Progress',
              onPressed: () {
                if (trip['id'] != null) {
                  Navigator.pushNamed(context, '/tracking', arguments: {'requestId': trip['id']});
                }
              },
            ),
          ),
        ],
      ),
      ['ID', 'Driver', 'Vehicle', 'Track'],
    );
  }

  Widget _buildTableCard(String title, List<dynamic> data, DataRow Function(dynamic) rowBuilder, List<String> columns) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No records found', style: TextStyle(color: Colors.grey))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
                rows: data.map(rowBuilder).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppColors.darkBlue;
    if (status == 'REQUEST_CREATED' || status == 'SEARCHING_DRIVER') color = Colors.orange;
    else if (status == 'COMPLETED') color = AppColors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
