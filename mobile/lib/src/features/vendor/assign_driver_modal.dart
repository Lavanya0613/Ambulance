import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vendor_provider.dart';
import 'driver_provider.dart';
import 'fleet_provider.dart';
import '../../core/theme/app_theme.dart';

class AssignDriverModal extends StatefulWidget {
  final String requestId;
  const AssignDriverModal({super.key, required this.requestId});

  @override
  State<AssignDriverModal> createState() => _AssignDriverModalState();
}

class _AssignDriverModalState extends State<AssignDriverModal> {
  String? _selectedDriverId;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().setStatusFilter('AVAILABLE');
      context.read<FleetProvider>().setStatusFilter('AVAILABLE');
    });
  }

  void _submit() {
    if (_selectedDriverId == null || _selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both a driver and a vehicle')));
      return;
    }
    context.read<VendorProvider>().assignDriver(widget.requestId, _selectedDriverId!, _selectedVehicleId!);
    Navigator.pop(context);
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
          const Text('Assign Driver & Vehicle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
          const SizedBox(height: 16),
          
          const Text('Select Driver', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Consumer<DriverProvider>(
            builder: (context, prov, _) {
              if (prov.isLoading) return const LinearProgressIndicator();
              if (prov.drivers.isEmpty) return const Text('No available drivers.', style: TextStyle(color: Colors.red));
              
              return DropdownButtonFormField<String>(
                value: _selectedDriverId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Choose a Driver'),
                items: prov.drivers.map((d) => DropdownMenuItem(
                  value: d['id'].toString(),
                  child: Text('${d['name']} - ${d['phone']}'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedDriverId = val),
              );
            },
          ),
          
          const SizedBox(height: 16),
          const Text('Select Ambulance', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Consumer<FleetProvider>(
            builder: (context, prov, _) {
              if (prov.isLoading) return const LinearProgressIndicator();
              if (prov.ambulances.isEmpty) return const Text('No available ambulances.', style: TextStyle(color: Colors.red));
              
              return DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Choose an Ambulance'),
                items: prov.ambulances.map((a) => DropdownMenuItem(
                  value: a['id'].toString(),
                  child: Text('${a['vehicleNumber']} (${a['ambulanceType']})'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedVehicleId = val),
              );
            },
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }
}
