import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.darkBlue)),
            const SizedBox(height: 4),
            const Text('Manage your account details.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),

            // Avatar + Name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.green.withOpacity(0.12),
                  child: Text(
                    auth.patientName.isNotEmpty ? auth.patientName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.green),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    auth.patientName.isNotEmpty ? auth.patientName : 'Guest Patient',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.patientPhone.isNotEmpty ? auth.patientPhone : 'No phone set',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 16),

            // Info Tiles
            _tile(Icons.person_outline, 'Patient Name', auth.patientName.isNotEmpty ? auth.patientName : 'Guest Patient'),
            _tile(Icons.phone_outlined, 'Phone Number', auth.patientPhone.isNotEmpty ? auth.patientPhone : 'Not set'),
            _tile(Icons.medical_services_outlined, 'Account Type', 'Patient'),
            _tile(Icons.shield_outlined, 'Version', '1.0.0'),

            const SizedBox(height: 24),

            // Service Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFf0f4f8),
                borderRadius: BorderRadius.circular(20),
                border: const Border(left: BorderSide(color: AppColors.green, width: 5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('CallHealth Ambulance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkBlue)),
                SizedBox(height: 6),
                Text('24/7 emergency ambulance service. Nearest ambulance dispatched within minutes of request.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.check_circle, color: AppColors.green, size: 16),
                  SizedBox(width: 6),
                  Text('Service Area: Active', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // No logout needed — app integrates into existing platform
            // Patient identity is managed by the host application
          ],
        ),
      );
    });
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        ])),
      ]),
    );
  }
}
