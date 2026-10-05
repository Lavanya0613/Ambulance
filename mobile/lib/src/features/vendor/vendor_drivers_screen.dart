import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'driver_provider.dart';
import '../../core/theme/app_theme.dart';

class VendorDriversScreen extends StatefulWidget {
  const VendorDriversScreen({super.key});

  @override
  State<VendorDriversScreen> createState() => _VendorDriversScreenState();
}

class _VendorDriversScreenState extends State<VendorDriversScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().fetchDrivers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddDriverModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDriverModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<DriverProvider>(
        builder: (context, prov, _) {
          return Column(
            children: [
              _buildSearchBar(prov),
              _buildFilterChips(prov),
              Expanded(
                child: prov.isLoading && prov.drivers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : prov.drivers.isEmpty
                        ? const Center(child: Text('No drivers found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: prov.drivers.length,
                            itemBuilder: (context, index) {
                              return _buildDriverCard(prov.drivers[index], prov);
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDriverModal(context),
        backgroundColor: AppColors.darkBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar(DriverProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => prov.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search by name or vehicle number...',
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

  Widget _buildFilterChips(DriverProvider prov) {
    final statusList = [null, 'AVAILABLE', 'BUSY', 'OFFLINE'];
    final statusLabels = ['All', 'Available', 'Busy', 'Offline'];
    
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

  Widget _buildDriverCard(Map<String, dynamic> driver, DriverProvider prov) {
    final status = driver['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'AVAILABLE') statusColor = AppColors.green;
    if (status == 'BUSY') statusColor = Colors.orange;
    if (status == 'OFFLINE') statusColor = Colors.red;

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
                  child: const Icon(Icons.person, color: AppColors.darkBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(driver['phone'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                        DropdownMenuItem(value: 'OFFLINE', child: Text('OFFLINE')),
                      ],
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != status) {
                          prov.updateDriverStatus(driver['id'], newStatus);
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
                    const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(driver['vehicleNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.medical_services, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(driver['ambulanceType'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
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

class _AddDriverModal extends StatefulWidget {
  @override
  State<_AddDriverModal> createState() => _AddDriverModalState();
}

class _AddDriverModalState extends State<_AddDriverModal> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  String _type = 'ALS';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _vehicleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isLoading = true);
    final prov = context.read<DriverProvider>();
    final success = await prov.createDriver(_nameCtrl.text, _phoneCtrl.text, _vehicleCtrl.text, _type);
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
          const Text('Add New Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
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
                : const Text('Save Driver', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }
}
