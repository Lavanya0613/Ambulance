import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vendor_provider.dart';
import 'driver_provider.dart';
import 'fleet_provider.dart';
import '../../core/theme/app_theme.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: 'vendor@callhealth.com');
    _passCtrl = TextEditingController(text: 'demo123');
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final prov = context.read<VendorProvider>();
    final driverProv = context.read<DriverProvider>();
    final fleetProv = context.read<FleetProvider>();
    final success = await prov.login(_emailCtrl.text, _passCtrl.text);
    
    if (success) {
      driverProv.updateApiClient(prov.apiClient!);
      fleetProv.updateApiClient(prov.apiClient!);
    }

    setState(() => _loading = false);
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/vendor/dashboard');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.business_center, size: 64, color: AppColors.darkBlue),
                  const SizedBox(height: 16),
                  const Text(
                    'Vendor Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.darkBlue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to manage your fleet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                      child: _loading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Patient App'),
                  )
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
