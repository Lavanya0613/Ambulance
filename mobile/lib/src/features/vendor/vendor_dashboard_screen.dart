import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vendor_provider.dart';
import 'driver_provider.dart';
import 'fleet_provider.dart';
import 'assign_driver_modal.dart';
import 'vendor_drivers_screen.dart';
import 'vendor_fleet_screen.dart';
import 'vendor_home_screen.dart';
import 'vendor_bookings_screen.dart';
import '../../core/theme/app_theme.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _selectedIndex = 0;

  void _onMenuTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onRefresh() {
    if (_selectedIndex == 0) {
      context.read<VendorProvider>().fetchDashboardStats();
    } else if (_selectedIndex == 1) {
      context.read<VendorProvider>().fetchRequests();
    } else if (_selectedIndex == 2) {
      context.read<DriverProvider>().fetchDrivers();
    } else if (_selectedIndex == 3) {
      context.read<FleetProvider>().fetchAmbulances();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Vendor Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  actions: [
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _onRefresh, tooltip: 'Refresh Data'),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Logout',
                      onPressed: () {
                        context.read<VendorProvider>().logout();
                        Navigator.pushReplacementNamed(context, '/vendor/login');
                      },
                    )
                  ],
                ),
          drawer: isDesktop ? null : Drawer(child: _buildDrawerContent()),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop) _buildDesktopHeader(),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          const VendorHomeScreen(),
                          const VendorBookingsScreen(),
                          const VendorDriversScreen(),
                          const VendorFleetScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader() {
    String title = 'Dashboard';
    if (_selectedIndex == 1) title = 'All Bookings';
    if (_selectedIndex == 2) title = 'Driver Management';
    if (_selectedIndex == 3) title = 'Ambulance Fleet';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _onRefresh,
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.business, color: AppColors.darkBlue, size: 20),
                SizedBox(width: 8),
                Text('Vendor Manager', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: AppColors.darkBlue,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Icon(Icons.medical_services, color: AppColors.darkBlue, size: 28),
                ),
                SizedBox(height: 16),
                Text('Vendor Portal', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('mock-vendor@callhealth.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.dashboard, 'Home Dashboard', 0),
          _buildSidebarItem(Icons.list_alt, 'All Bookings', 1),
          _buildSidebarItem(Icons.people_alt, 'Drivers', 2),
          _buildSidebarItem(Icons.local_hospital, 'Ambulances', 3),
          const Spacer(),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Logout', style: TextStyle(color: Colors.white70)),
            onTap: () {
              context.read<VendorProvider>().logout();
              Navigator.pushReplacementNamed(context, '/vendor/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () => _onMenuTapped(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDrawerContent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: AppColors.darkBlue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.business_center, color: AppColors.darkBlue),
              ),
              SizedBox(height: 12),
              Text('Vendor Fleet Manager', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('mock-vendor@callhealth.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home Dashboard'),
          selected: _selectedIndex == 0,
          onTap: () {
            _onMenuTapped(0);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.list_alt),
          title: const Text('All Bookings'),
          selected: _selectedIndex == 1,
          onTap: () {
            _onMenuTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.people_alt),
          title: const Text('Drivers'),
          selected: _selectedIndex == 2,
          onTap: () {
            _onMenuTapped(2);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.local_hospital),
          title: const Text('Ambulances'),
          selected: _selectedIndex == 3,
          onTap: () {
            _onMenuTapped(3);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class VendorRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String? loadingActionId;

  const VendorRequestCard({super.key, required this.request, this.loadingActionId});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String;
    final isNew = status == 'REQUEST_CREATED' || status == 'SEARCHING_DRIVER' || status == 'REQUEST_RECEIVED';
    final isAssigned = status == 'VENDOR_ACCEPTED' || status == 'DRIVER_ASSIGNED';
    final isActive = status == 'EN_ROUTE' || status == 'ARRIVED' || status == 'PATIENT_ONBOARD' || status == 'TRIP_STARTED' || status == 'DESTINATION_REACHED';
    final isCompleted = status == 'COMPLETED' || status == 'CANCELLED';

    final patientObj = request['patient'] is Map ? request['patient'] as Map : {};
    final pickupObj = request['pickup'] is Map ? request['pickup'] as Map : {};
    final destObj = request['destination'] is Map ? request['destination'] as Map : {};

    final patientName = (request['patientName'] ?? patientObj['name'] ?? 'Patient').toString();
    final patientPhone = (request['patientPhone'] ?? patientObj['phone'] ?? '').toString();
    final pickupAddr = (request['pickupAddress'] ?? pickupObj['address'] ?? 'Pickup Location').toString();
    final dropAddr = (request['dropAddress'] ?? request['destinationAddress'] ?? destObj['address'] ?? 'Destination Location').toString();

    final pLat = request['pickupLat'];
    final pLng = request['pickupLng'];
    final dLat = request['dropLat'];
    final dLng = request['dropLng'];

    final coordsSubtitle = (pLat != null && pLng != null) ? ' ($pLat, $pLng)' : '';
    final dropCoordsSubtitle = (dLat != null && dLng != null) ? ' ($dLat, $dLng)' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Flexible(
                  child: Text(
                    request['requestNumber'] ?? 'REQ-${request['id']?.toString().substring(0, 8)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildInfoRow(Icons.person, patientName, patientPhone.isNotEmpty ? patientPhone : 'No contact specified'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Pickup', '$pickupAddr$coordsSubtitle'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.local_hospital, 'Destination', '$dropAddr$dropCoordsSubtitle'),
            
            if (request['emergencyLevel'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text('Emergency Level: ${request['emergencyLevel']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              )
            ],

            const Divider(height: 32),

            // SPECIFIC STATUS ACTIONS
            if (isNew) ...[
              _buildNewActions(context),
              const SizedBox(height: 12),
            ] else if (isAssigned) ...[
              _buildAssignDriverAction(context),
              const SizedBox(height: 12),
            ] else if (isActive) ...[
              _buildActiveActions(context),
              const SizedBox(height: 12),
            ] else if (isCompleted) ...[
              _buildCompletedInfo(),
              const SizedBox(height: 12),
            ],

            // ALWAYS SHOW TRACK LIVE PROGRESS BUTTON FOR EVERY REQUEST
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (request['id'] != null) {
                    Navigator.pushNamed(context, '/tracking', arguments: {'requestId': request['id']});
                  }
                },
                icon: const Icon(Icons.map, color: Colors.white, size: 18),
                label: const Text(
                  'Track Live Progress / Map',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.darkBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.darkBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkBlue)),
              const SizedBox(height: 2),
              if (subtitle.isNotEmpty) 
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewActions(BuildContext context) {
    final prov = context.read<VendorProvider>();
    final isLoading = loadingActionId == request['id'];

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : () => prov.rejectRequest(request['id']),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reject Booking', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : () => prov.acceptRequest(request['id']),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.darkBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Accept Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignDriverAction(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => AssignDriverModal(requestId: request['id']),
          );
        },
        icon: const Icon(Icons.assignment_ind, color: Colors.white),
        label: const Text('Assign Driver & Ambulance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildActiveActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: const [
          Icon(Icons.directions_car, color: AppColors.green, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trip In Progress — Ambulance Active',
              style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, color: AppColors.green),
          SizedBox(width: 12),
          Text('Trip Completed Successfully', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'REQUEST_CREATED' || status == 'SEARCHING_DRIVER') return Colors.orange;
    if (status == 'COMPLETED') return AppColors.green;
    if (status == 'CANCELLED' || status == 'FAILED') return Colors.red;
    return AppColors.darkBlue;
  }
}
