import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ambulance_app/src/core/theme/app_theme.dart';
import '../driver_auth_provider.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProv = context.read<DriverAuthProvider>();
      driverProv.fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverProv = context.watch<DriverAuthProvider>();
    final profile = driverProv.driverProfile;

    if (driverProv.isLoading && profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver Profile'),
          backgroundColor: AppColors.darkBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver Profile'),
          backgroundColor: AppColors.darkBlue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Could not load profile from backend'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => driverProv.fetchProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final String name = profile['name'] ?? 'N/A';
    final String vendor = profile['vendorName'] ?? profile['vendorId'] ?? 'Emergency Fleet Provider';
    final String vehicleNumber = profile['vehicleNumber'] ?? 'N/A';
    final String vehicleType = profile['ambulanceType'] ?? profile['vehicleType'] ?? 'ALS (Advanced Life Support)';
    final String phone = profile['phone'] ?? 'N/A';
    final String licenseNumber = profile['licenseNumber'] ?? 'DL-98421458';
    final int todayTrips = (profile['todayTrips'] as num?)?.toInt() ?? driverProv.completedToday;
    final int completedTrips = (profile['completedTrips'] as num?)?.toInt() ?? 0;
    final String status = profile['status'] ?? 'AVAILABLE';
    final bool isOffline = status == 'OFFLINE';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Driver Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => driverProv.fetchProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Avatar Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.darkBlue.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 50, color: AppColors.darkBlue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOffline ? Colors.grey.shade200 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isOffline ? Colors.grey : Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOffline ? 'OFFLINE' : status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOffline ? Colors.grey.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Performance Metrics Row (Today's Trips & Completed Trips)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/driver/history'),
                    child: _buildMetricCard(
                      'Today\'s Trips',
                      todayTrips.toString(),
                      Icons.today,
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/driver/history'),
                    child: _buildMetricCard(
                      'Completed Trips',
                      completedTrips.toString(),
                      Icons.verified_outlined,
                      AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Details Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROFILE INFORMATION',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.business, 'Vendor', vendor),
                    const Divider(height: 20),
                    _buildDetailRow(Icons.directions_car, 'Vehicle Number', vehicleNumber),
                    const Divider(height: 20),
                    _buildDetailRow(Icons.medical_services, 'Vehicle Type', vehicleType),
                    const Divider(height: 20),
                    _buildDetailRow(Icons.phone, 'Phone', phone),
                    const Divider(height: 20),
                    _buildDetailRow(Icons.badge, 'License Number', licenseNumber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons: [Go Offline / Go Online] and [Logout]
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOffline ? AppColors.green : Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(isOffline ? Icons.power_settings_new : Icons.no_accounts, color: Colors.white),
              label: Text(
                isOffline ? 'GO ONLINE' : 'GO OFFLINE',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              onPressed: driverProv.isLoading
                  ? null
                  : () async {
                      final newStatus = isOffline ? 'AVAILABLE' : 'OFFLINE';
                      final success = await driverProv.toggleDutyStatus(newStatus);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Duty status updated to $newStatus')),
                        );
                      }
                    },
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkBlue,
                side: const BorderSide(color: AppColors.darkBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.settings, color: AppColors.darkBlue),
              label: const Text(
                'SETTINGS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/driver/settings');
              },
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'LOGOUT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              onPressed: () async {
                await driverProv.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/driver/login', (route) => false);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
