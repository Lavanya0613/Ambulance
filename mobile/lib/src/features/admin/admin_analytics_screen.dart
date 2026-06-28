import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_analytics_provider.dart';
import '../../models/admin_analytics_models.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminAnalyticsProvider.notifier).fetchAnalytics(),
          )
        ],
      ),
      body: _buildBody(state, context),
    );
  }

  Widget _buildBody(AdminAnalyticsState state, BuildContext context) {
    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    final data = state.data!;
    
    return RefreshIndicator(
      onRefresh: () => ref.read(adminAnalyticsProvider.notifier).fetchAnalytics(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKPICards(data, isDesktop),
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRequestsPerDayChart(data.requestsPerDay)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildRequestsPerStatusChart(data.requestsPerStatus)),
                    ],
                  )
                else ...[
                  _buildRequestsPerDayChart(data.requestsPerDay),
                  const SizedBox(height: 24),
                  _buildRequestsPerStatusChart(data.requestsPerStatus),
                ],
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildVendorPerformanceChart(data.vendorPerformance)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTopPickupAreas(data.topPickupAreas)),
                    ],
                  )
                else ...[
                  _buildVendorPerformanceChart(data.vendorPerformance),
                  const SizedBox(height: 24),
                  _buildTopPickupAreas(data.topPickupAreas),
                ],
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICards(AnalyticsDashboardData data, bool isDesktop) {
    final avgEtaMins = (data.averageEtaSeconds / 60).toStringAsFixed(1);
    final avgCompMins = (data.averageCompletionTimeSeconds / 60).toStringAsFixed(1);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSingleKPI('Avg ETA', '$avgEtaMins min', Icons.timer, Colors.blue, isDesktop),
        _buildSingleKPI('Completion Time', '$avgCompMins min', Icons.check_circle_outline, Colors.green, isDesktop),
        _buildSingleKPI('Cancel Rate', '${data.cancellationRate}%', Icons.cancel_outlined, Colors.red, isDesktop),
      ],
    );
  }

  Widget _buildSingleKPI(String title, String value, IconData icon, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 240 : 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildRequestsPerDayChart(List<DailyRequestData> dailyData) {
    return _buildChartCard(
      title: 'Requests per Day',
      child: SizedBox(
        height: 300,
        child: dailyData.isEmpty
            ? const Center(child: Text('No Data'))
            : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= dailyData.length) return const SizedBox.shrink();
                          final date = DateTime.parse(dailyData[value.toInt()].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
                      isCurved: true,
                      color: const Color(0xFF76B82A),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF76B82A).withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRequestsPerStatusChart(List<StatusRequestData> statusData) {
    if (statusData.isEmpty) return _buildChartCard(title: 'Requests by Status', child: const SizedBox(height: 300, child: Center(child: Text('No Data'))));
    
    int total = statusData.fold(0, (sum, item) => sum + item.count);

    return _buildChartCard(
      title: 'Requests by Status',
      child: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: statusData.map((e) {
              final percentage = (e.count / total) * 100;
              Color color = Colors.blue;
              if (e.status == 'COMPLETED') color = Colors.green;
              if (e.status == 'CANCELLED') color = Colors.red;
              if (e.status == 'PENDING') color = Colors.orange;

              return PieChartSectionData(
                color: color,
                value: e.count.toDouble(),
                title: '${percentage.toStringAsFixed(1)}%',
                radius: 50,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorPerformanceChart(List<VendorPerformanceData> vendorData) {
    if (vendorData.isEmpty) return _buildChartCard(title: 'Vendor Performance', child: const SizedBox(height: 300, child: Center(child: Text('No Data'))));

    double maxCompleted = vendorData.fold(0.0, (max, item) => item.completed.toDouble() > max ? item.completed.toDouble() : max);

    return _buildChartCard(
      title: 'Vendor Performance (Completed Rides)',
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCompleted * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 || value.toInt() >= vendorData.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(vendorData[value.toInt()].name, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: vendorData.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.completed.toDouble(),
                    color: const Color(0xFF1E3A5F),
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPickupAreas(List<TopPickupArea> areas) {
    return _buildChartCard(
      title: 'Top Pickup Areas',
      child: SizedBox(
        height: 300,
        child: areas.isEmpty
            ? const Center(child: Text('No Data'))
            : ListView.separated(
                itemCount: areas.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = areas[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF76B82A).withOpacity(0.1),
                      child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF76B82A), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item.area, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text('${item.count} rides', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
