import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vendor_provider.dart';
import '../../core/theme/app_theme.dart';
import 'vendor_dashboard_screen.dart'; // To reuse VendorRequestCard

class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Assigned', 'Active', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prov.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    prov.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => prov.fetchRequests(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          );
        }

        // Combine all requests
        List<Map<String, dynamic>> allRequests = [...prov.activeRequests, ...prov.completedRequests];

        // Sort by newest first
        allRequests.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA); // Descending
        });

        // Apply Filter
        if (_selectedFilter != 'All') {
          allRequests = allRequests.where((req) {
            final status = req['status'] as String? ?? '';
            switch (_selectedFilter) {
              case 'Pending':
                return status == 'REQUEST_CREATED' || status == 'SEARCHING_DRIVER';
              case 'Assigned':
                return status == 'VENDOR_ACCEPTED' || status == 'DRIVER_ASSIGNED';
              case 'Active':
                return status == 'EN_ROUTE' || status == 'ARRIVED' || status == 'PATIENT_ONBOARD';
              case 'Completed':
                return status == 'COMPLETED';
              case 'Cancelled':
                return status == 'CANCELLED' || status == 'FAILED';
              default:
                return true;
            }
          }).toList();
        }

        // Apply Search
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          allRequests = allRequests.where((req) {
            final reqNum = (req['requestNumber'] ?? req['id'] ?? '').toString().toLowerCase();
            final patientName = (req['patientName'] ?? req['patient']?['name'] ?? '').toString().toLowerCase();
            final patientPhone = (req['patientPhone'] ?? req['patient']?['phone'] ?? '').toString().toLowerCase();
            
            return reqNum.contains(query) || patientName.contains(query) || patientPhone.contains(query);
          }).toList();
        }

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Booking ID, Patient Name, or Phone...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter Chips
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(top: 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = filter);
                        },
                        selectedColor: AppColors.darkBlue,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const Divider(height: 1, thickness: 1),

            // List View
            Expanded(
              child: allRequests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 80, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No Bookings Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty ? 'Try adjusting your search query.' : 'There are no bookings matching this filter.', 
                            textAlign: TextAlign.center, 
                            style: const TextStyle(color: AppColors.textSecondary)
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allRequests.length,
                    itemBuilder: (context, index) {
                      return VendorRequestCard(
                        request: allRequests[index],
                        loadingActionId: prov.loadingActionId,
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
}
