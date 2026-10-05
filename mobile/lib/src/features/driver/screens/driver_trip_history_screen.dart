import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ambulance_app/src/core/theme/app_theme.dart';
import '../driver_auth_provider.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() => _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  bool _isLoading = false;
  List<dynamic> _trips = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalTrips = 0;
  bool _hasMore = false;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadHistory(_currentPage);
  }

  Future<void> _loadHistory(int page) async {
    setState(() => _isLoading = true);
    final driverProv = context.read<DriverAuthProvider>();
    final result = await driverProv.fetchTripHistory(page: page, limit: _limit);

    if (!mounted) return;

    if (result != null && result['data'] != null) {
      final pagination = result['pagination'] ?? {};
      setState(() {
        _trips = result['data'] ?? [];
        _currentPage = pagination['page'] ?? page;
        _totalPages = pagination['totalPages'] ?? 1;
        _totalTrips = pagination['total'] ?? 0;
        _hasMore = pagination['hasMore'] ?? false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(_currentPage),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(1),
        child: Column(
          children: [
            // Header stats banner
            Container(
              color: AppColors.darkBlue,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Completed Trips: $_totalTrips',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _trips.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No completed trips found',
                                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            final trip = _trips[index];
                            return _buildTripCard(trip);
                          },
                        ),
            ),

            // Pagination Control Bar
            if (!_isLoading && _totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage > 1 ? AppColors.darkBlue : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                      onPressed: _currentPage > 1 ? () => _loadHistory(_currentPage - 1) : null,
                    ),
                    Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasMore ? AppColors.darkBlue : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Next'),
                      onPressed: _hasMore ? () => _loadHistory(_currentPage + 1) : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final String reqNum = trip['requestNumber'] ?? 'REQ-${trip['id']?.toString().substring(0, 8).toUpperCase()}';
    final String dateStr = _formatDate(trip['date']);
    final String patientName = trip['patientName'] ?? 'Emergency Patient';
    final String pickup = trip['pickupAddress'] ?? 'Pickup Location';
    final String destination = trip['destinationAddress'] ?? 'Hospital Destination';
    final double distanceKm = (trip['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final int durationMins = (trip['durationMinutes'] as num?)?.toInt() ?? 0;
    final String status = trip['status'] ?? 'COMPLETED';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Request ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reqNum,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),

            // Patient Name
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  patientName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pickup Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location, size: 18, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      Text(pickup, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Destination Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_hospital, size: 18, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destination', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      Text(destination, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Distance & Duration Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$distanceKm km',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkBlue),
                    ),
                    const SizedBox(width: 4),
                    const Text('Distance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '$durationMins min',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkBlue),
                    ),
                    const SizedBox(width: 4),
                    const Text('Duration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
