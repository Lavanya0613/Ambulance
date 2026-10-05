import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ambulance_app/src/core/theme/app_theme.dart';
import '../driver_auth_provider.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProv = context.watch<DriverAuthProvider>();
    final profile = driverProv.driverProfile;
    final activeRequest = driverProv.activeRequest;

    if (driverProv.isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: const Center(child: Text('Profile not available')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Driver Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.pushNamed(context, '/driver/notifications');
                },
              ),
              if (driverProv.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${driverProv.unreadCount > 9 ? '9+' : driverProv.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/driver/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Driver Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/driver/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              driverProv.fetchProfile();
              driverProv.fetchDashboard();
              driverProv.fetchNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              driverProv.logout();
              Navigator.pushReplacementNamed(context, '/driver/login');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!driverProv.isNetworkConnected)
                  _buildOfflineBanner(driverProv),
                if (activeRequest != null)
                  _buildTripCard(context, activeRequest, driverProv)
                else
                  _buildNoActiveTripView(context, profile, driverProv.completedToday),
              ],
            ),
          ),
          if (driverProv.pendingAssignment != null)
            _buildAssignmentOverlay(context, driverProv),
        ],
      ),
    );
  }

  Widget _buildAssignmentOverlay(BuildContext context, DriverAuthProvider prov) {
    final request = prov.pendingAssignment!;
    final countdown = prov.countdown;

    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing Alert Header
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                onEnd: () {
                  // Loop handled by reversing if we were using an explicit controller,
                  // but a simple static scale is fine or we can just rely on the layout.
                },
                child: const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              const Text(
                'NEW ASSIGNMENT',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Request Details Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['patientName'] ?? 'Unknown Patient', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                      const SizedBox(height: 16),
                      _buildLocationRow(Icons.my_location, 'Pickup', request['pickupAddress'] ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _buildLocationRow(Icons.local_hospital, 'Destination', request['dropAddress'] ?? 'Unknown'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn('Est. Time', request['etaSeconds'] != null ? '${(request['etaSeconds'] / 60).round()} mins' : '--'),
                          if (request['priority'] != null)
                            Text(
                              request['priority'].toString().toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800, fontSize: 18),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Countdown Timer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: countdown <= 10 ? Colors.red : Colors.orange, width: 4),
                ),
                child: Text(
                  countdown.toString(),
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold, 
                    color: countdown <= 10 ? Colors.red : Colors.white
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => prov.rejectTrip(request['id'] ?? request['requestId']),
                      child: const Text('REJECT', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => prov.acceptTrip(request['id'] ?? request['requestId']),
                      child: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveTripView(BuildContext context, Map<String, dynamic> profile, int completedToday) {
    final isOnline = profile['status'] != 'OFFLINE';

    return Column(
      children: [
        // Welcome and Status
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 64, color: AppColors.green),
                const SizedBox(height: 16),
                const Text(
                  'No Active Trip',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are currently ${isOnline ? 'ONLINE' : 'OFFLINE'}',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: isOnline ? AppColors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Go Offline', style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: isOnline,
                      onChanged: (val) {
                        // In a real app we'd call an API to toggle status here
                        // driverProv.toggleStatus(val ? 'AVAILABLE' : 'OFFLINE');
                      },
                      activeColor: AppColors.green,
                    ),
                    const Text('Go Online', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Stats
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/driver/history'),
                child: _buildStatCard('Completed Today (View History)', completedToday.toString(), Icons.history, AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Vehicle', profile['vehicleNumber'] ?? 'N/A', Icons.directions_car, AppColors.darkBlue),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> request, DriverAuthProvider prov) {
    final status = request['status'];
    final isNewAssignment = status == 'DRIVER_ASSIGNED';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isNewAssignment ? Colors.orange.shade100 : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isNewAssignment ? 'NEW ASSIGNMENT' : status.toString().replaceAll('_', ' '),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isNewAssignment ? Colors.orange.shade800 : AppColors.primary
                    ),
                  ),
                ),
                if (request['priority'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request['priority'].toString().toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Request #${request['requestNumber'] ?? request['id']?.substring(0,8)}', 
              style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(request['patientName'] ?? 'Unknown Patient', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
            const SizedBox(height: 24),
            
            _buildLocationRow(Icons.my_location, 'Pickup', request['pickupAddress'] ?? 'Unknown'),
            const Padding(
              padding: EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
              child: SizedBox(height: 24, child: VerticalDivider(color: Colors.grey, thickness: 2)),
            ),
            _buildLocationRow(Icons.local_hospital, 'Destination', request['dropAddress'] ?? 'Unknown'),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Est. Distance', 'Unknown'), // Distance calc can be added
                _buildInfoColumn('Est. Time', request['etaSeconds'] != null ? '${(request['etaSeconds'] / 60).round()} mins' : 'Calc...'),
                _buildInfoColumn('Assigned', _formatTime(request['updatedAt'] ?? request['createdAt'])),
              ],
            ),
            const SizedBox(height: 20),

            // Open Full-Screen Driver Navigation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text(
                  'OPEN MAP NAVIGATION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/driver/navigation');
                },
              ),
            ),
            const SizedBox(height: 12),

            // Step-by-Step Lifecycle Status Update Button
            _buildNextStatusButton(context, request, prov),

            if (isNewAssignment) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        // The user can still reject the trip if they accepted it but haven't started?
                        // Or if the trip is just an active trip, maybe we don't show accept/reject here.
                        // Let's only show these if the status is EN_ROUTE and we want to Cancel, but for now we just show it for new assignments.
                        // Wait, isNewAssignment was previously used when DRIVER_ASSIGNED was the status.
                        // Now, DRIVER_ASSIGNED triggers the full screen overlay.
                        // So this block might not even be hit.
                      },
                      child: const Text('Cancel Trip', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(address, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
      ],
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '--:--';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildNextStatusButton(BuildContext context, Map<String, dynamic> request, DriverAuthProvider prov) {
    final status = request['status'];
    String? nextStatus;
    String label = '';
    Color color = AppColors.green;
    IconData icon = Icons.arrow_forward;

    switch (status) {
      case 'DRIVER_ASSIGNED':
        nextStatus = 'ARRIVED';
        label = 'ARRIVED AT PICKUP';
        icon = Icons.location_on;
        color = Colors.teal;
        break;
      case 'ARRIVED':
        nextStatus = 'PATIENT_ONBOARD';
        label = 'PATIENT ONBOARD';
        icon = Icons.accessible_forward;
        color = Colors.indigo;
        break;
      case 'PATIENT_ONBOARD':
        nextStatus = 'EN_ROUTE';
        label = 'EN ROUTE HOSPITAL';
        icon = Icons.navigation;
        color = Colors.orange.shade800;
        break;
      case 'EN_ROUTE':
        nextStatus = 'DESTINATION_REACHED';
        label = 'ARRIVED AT HOSPITAL';
        icon = Icons.local_hospital;
        color = Colors.purple;
        break;
      case 'DESTINATION_REACHED':
        nextStatus = 'COMPLETED';
        label = 'COMPLETE TRIP';
        icon = Icons.check_circle;
        color = AppColors.green;
        break;
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        onPressed: prov.isLoading
            ? null
            : () async {
                final success = await prov.updateTripStatus(request['id'] ?? request['requestId'], nextStatus!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Trip status updated to $nextStatus')),
                  );
                }
              },
      ),
    );
  }

  Widget _buildOfflineBanner(DriverAuthProvider prov) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ Offline - Connection lost. Queueing updates locally (${prov.pendingSyncCount} pending).',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
