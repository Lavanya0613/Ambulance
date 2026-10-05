import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fleet_provider.dart';
import '../../core/theme/app_theme.dart';

class VendorFleetScreen extends StatefulWidget {
  const VendorFleetScreen({super.key});

  @override
  State<VendorFleetScreen> createState() => _VendorFleetScreenState();
}

class _VendorFleetScreenState extends State<VendorFleetScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchAmbulances();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddAmbulanceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAmbulanceModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<FleetProvider>(
        builder: (context, prov, _) {
          return Column(
            children: [
              _buildSearchBar(prov),
              _buildFilterChips(prov),
              Expanded(
                child: prov.isLoading && prov.ambulances.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : prov.ambulances.isEmpty
                        ? const Center(child: Text('No ambulances found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: prov.ambulances.length,
                            itemBuilder: (context, index) {
                              return _buildAmbulanceCard(prov.ambulances[index], prov);
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAmbulanceModal(context),
        backgroundColor: AppColors.darkBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Ambulance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar(FleetProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => prov.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search by vehicle number...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips(FleetProvider prov) {
    final statusList = [null, 'AVAILABLE', 'BUSY', 'OUT_OF_SERVICE'];
    final statusLabels = ['All', 'Available', 'Busy', 'Out of Service'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(statusList.length, (index) {
          final status = statusList[index];
          final label = statusLabels[index];
          final isSelected = prov.statusFilter == status;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label, style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              selected: isSelected,
              selectedColor: AppColors.darkBlue,
              backgroundColor: Colors.white,
              onSelected: (_) => prov.setStatusFilter(status),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAmbulanceCard(Map<String, dynamic> ambulance, FleetProvider prov) {
    final status = ambulance['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'AVAILABLE') statusColor = AppColors.green;
    if (status == 'BUSY') statusColor = Colors.orange;
    if (status == 'OUT_OF_SERVICE') statusColor = Colors.red;

    final gpsStatus = ambulance['gpsStatus'] ?? 'OFFLINE';
    final gpsColor = gpsStatus == 'ACTIVE' ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.darkBlue.withOpacity(0.1),
                  radius: 24,
                  child: const Icon(Icons.local_hospital, color: AppColors.darkBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ambulance['vehicleNumber'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${ambulance['ambulanceType'] ?? 'Unknown'} Type', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                      isDense: true,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'AVAILABLE', child: Text('AVAILABLE')),
                        DropdownMenuItem(value: 'BUSY', child: Text('BUSY')),
                        DropdownMenuItem(value: 'OUT_OF_SERVICE', child: Text('OUT OF SERVICE')),
                      ],
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != status) {
                          prov.updateAmbulanceStatus(ambulance['id'], newStatus);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(ambulance['assignedDriverName'] ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: gpsColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('GPS $gpsStatus', style: TextStyle(color: gpsColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AddAmbulanceModal extends StatefulWidget {
  @override
  State<_AddAmbulanceModal> createState() => _AddAmbulanceModalState();
}

class _AddAmbulanceModalState extends State<_AddAmbulanceModal> {
  final _vehicleCtrl = TextEditingController();
  String _type = 'ALS';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_vehicleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter vehicle number')));
      return;
    }
    setState(() => _isLoading = true);
    final prov = context.read<FleetProvider>();
    final success = await prov.createAmbulance(_vehicleCtrl.text, _type);
    setState(() => _isLoading = false);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add New Ambulance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
          const SizedBox(height: 16),
          TextField(controller: _vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g., TS09 EA 1234)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Ambulance Type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'ALS', child: Text('ALS (Advanced Life Support)')),
              DropdownMenuItem(value: 'BLS', child: Text('BLS (Basic Life Support)')),
              DropdownMenuItem(value: 'ICU', child: Text('ICU Ambulance')),
            ],
            onChanged: (val) => setState(() => _type = val!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Ambulance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }
}
