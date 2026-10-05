import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ambulance_app/src/core/theme/app_theme.dart';
import '../driver_auth_provider.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  String _locationPermissionStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationPermissionStatus = 'Disabled (Location Services Off)');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      setState(() {
        switch (permission) {
          case LocationPermission.always:
            _locationPermissionStatus = 'Granted (Always Allow Background GPS)';
            break;
          case LocationPermission.whileInUse:
            _locationPermissionStatus = 'Granted (While In Use Only)';
            break;
          case LocationPermission.denied:
            _locationPermissionStatus = 'Denied (Tap to Request)';
            break;
          case LocationPermission.deniedForever:
            _locationPermissionStatus = 'Denied Forever (Open App Settings)';
            break;
          case LocationPermission.unableToDetermine:
            _locationPermissionStatus = 'Unknown (Tap to Check)';
            break;
        }
      });
    } catch (e) {
      setState(() => _locationPermissionStatus = 'Error checking permission');
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    await _checkLocationPermission();
  }

  void _showBatteryOptimizationGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.battery_saver, color: AppColors.primary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Battery Optimization Guide',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'To ensure continuous background GPS tracking during active ambulance dispatches, disable battery optimization for this app:',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildBatteryGuideStep('1. Samsung / OneUI', 'Settings ➔ Apps ➔ Driver App ➔ Battery ➔ Select "Unrestricted".'),
              _buildBatteryGuideStep('2. Xiaomi / MIUI', 'Settings ➔ Apps ➔ Permissions ➔ Autostart ➔ Enable for Driver App.'),
              _buildBatteryGuideStep('3. OnePlus / OxygenOS', 'Settings ➔ Battery ➔ Battery Optimization ➔ Driver App ➔ "Don\'t optimize".'),
              _buildBatteryGuideStep('4. Vivo & Oppo', 'Settings ➔ Battery ➔ High background power consumption ➔ Turn ON.'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBlue),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatteryGuideStep(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkBlue)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: AppColors.darkBlue, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CallHealth Driver Privacy & GPS Compliance',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkBlue),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '1. Location Data Collection:\n'
                        'This application collects continuous real-time location data (GPS coordinates, speed, and heading) only while you are logged in and marked "Online". Location tracking is used exclusively to route ambulance dispatches, compute accurate patient ETA, and update emergency dispatchers.\n\n'
                        '2. Background Location Access:\n'
                        'Location collection runs in the background while on duty even when the app is minimized or the screen is turned off. Background tracking automatically pauses when you toggle duty status to "Offline".\n\n'
                        '3. Health Data Privacy (HIPAA / GDPR):\n'
                        'Patient names, pickup locations, and medical notes are protected by strict encryption protocols and accessible only during active dispatch requests.\n\n'
                        '4. Data Retention & Sharing:\n'
                        'Audit logs and route coordinates are securely stored in compliance with healthcare dispatch regulations and are never sold to third parties.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProv = context.watch<DriverAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Preferences
            _buildSectionHeader('Preferences'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: driverProv.isDarkMode,
                    activeColor: AppColors.primary,
                    secondary: const Icon(Icons.dark_mode, color: AppColors.darkBlue),
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable dark theme interface', style: TextStyle(fontSize: 12)),
                    onChanged: (val) => driverProv.toggleDarkMode(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: driverProv.isSoundEnabled,
                    activeColor: AppColors.primary,
                    secondary: const Icon(Icons.volume_up, color: AppColors.primary),
                    title: const Text('Notification Sound', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Play audio alert on new dispatch request', style: TextStyle(fontSize: 12)),
                    onChanged: (val) => driverProv.toggleSoundEnabled(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Permissions & Performance
            _buildSectionHeader('Permissions & System'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.green),
                    title: const Text('Location Permission', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_locationPermissionStatus, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: TextButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('Check'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.battery_alert, color: Colors.orange),
                    title: const Text('Battery Optimization Guide', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Configure OS background location settings', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showBatteryOptimizationGuide(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: About & Privacy
            _buildSectionHeader('About'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.darkBlue),
                    title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('CallHealth Driver v2.4.0 (Build 20260805)', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.darkBlue),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Read health data & GPS tracking terms', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await driverProv.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/driver/login', (route) => false);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
