import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'booking_provider.dart';
import '../payment/payment_screen.dart';

const Color _kChekupGreen = Color(0xFF5BA438);
const Color _kLightBg = Color(0xFFF8FAFC);

class ReviewBookingScreen extends StatefulWidget {
  const ReviewBookingScreen({super.key});

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch real wallet eligibility from server when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchWalletBenefit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          backgroundColor: _kLightBg,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  color: _kChekupGreen,
                  child: Column(
                    children: [
                      _buildAppBar(context),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                        decoration: const BoxDecoration(
                          color: _kLightBg,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    if (prov.errorMsg != null) _errorBanner(prov.errorMsg!),
                                    if (prov.scheduledFor != null) _scheduledBanner(prov),
                                    _buildSection1(context, prov),
                                    const SizedBox(height: 16),
                                    _buildSection2(context, prov),
                                    const SizedBox(height: 16),
                                    _buildSection3(context, prov),
                                    const SizedBox(height: 16),
                                    _buildSection4(context, prov),
                                    const SizedBox(height: 16),
                                    _buildSection5(context, prov),
                                    const SizedBox(height: 16),
                                    _buildSection6(context, prov),
                                    const SizedBox(height: 16),
                                    _buildSection7(context, prov),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                            _buildBottomCTA(context, prov),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              children: [
                Text('Review Ambulance Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                SizedBox(height: 2),
                Text('Please verify the details before requesting', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: const [
              Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
              SizedBox(height: 2),
              Text('24/7\nSupport', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for the Card layout
  Widget _cardWrapper({required BuildContext context, required String step, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24, height: 24, 
                    decoration: const BoxDecoration(color: _kChekupGreen, shape: BoxShape.circle), 
                    child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)))
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
                    Text('Change', style: TextStyle(color: _kChekupGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                    Icon(Icons.chevron_right, color: _kChekupGreen, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSection1(BuildContext context, BookingProvider prov) {
    final typeName = prov.ambulanceType == 'ALS' ? 'Emergency Ambulance' : prov.ambulanceType == 'ICU' ? 'Critical Care Ambulance' : 'Standard Ambulance';
    return _cardWrapper(
      context: context,
      step: '1', title: 'Ambulance Details',
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset('assets/images/ambulance.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                const Text('For general medical needs.', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: _kChekupGreen, size: 16), const SizedBox(width: 4),
                    const Text('Basic Life Support', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Container(height: 12, width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 10)),
                    const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4),
                    const Text('Trained Staff', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduledBanner(BookingProvider prov) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB9D0FF))),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(child: Text('Scheduled for ${DateFormat('EEE, d MMM, h:mm a').format(prov.scheduledFor!.toLocal())}', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildSection2(BuildContext context, BookingProvider prov) {
    return _cardWrapper(
      context: context,
      step: '2', title: 'Pickup & Destination',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.location_on, color: _kChekupGreen, size: 20),
                        Container(
                           height: 40,
                           width: 2,
                           margin: const EdgeInsets.symmetric(vertical: 4),
                           child: ListView.builder(
                             shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                             itemCount: 6, itemBuilder: (c,i) => Container(width: 2, height: 4, color: Colors.grey.shade400, margin: const EdgeInsets.only(bottom: 2)),
                           ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _kChekupGreen)),
                          const SizedBox(height: 4),
                          Text(prov.pickupLocation?.address ?? 'Not selected', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.add_box, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Destination', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red)),
                          const SizedBox(height: 4),
                          Text(prov.dropLocation?.address ?? 'Not selected', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildRouteMap(prov),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMap(BookingProvider prov) {
    final pickup = prov.pickupLocation == null
        ? null
        : LatLng(prov.pickupLocation!.lat, prov.pickupLocation!.lng);
    final drop = prov.dropLocation == null
        ? null
        : LatLng(prov.dropLocation!.lat, prov.dropLocation!.lng);
    final points = <LatLng>[];
    if (pickup != null) points.add(pickup);
    if (drop != null) points.add(drop);

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.isEmpty
          ? const LatLng(17.4065, 78.4772)
          : points.length == 1
            ? points.first
            : LatLng(
              (points.first.latitude + points.last.latitude) / 2,
              (points.first.longitude + points.last.longitude) / 2,
              ),
        initialZoom: 12,
        initialCameraFit: points.length > 1 && points.first != points.last
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(28),
              )
            : null,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.callhealth.ambulance',
        ),
        if (pickup != null && drop != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickup, drop],
                color: const Color(0xFF0B53A8),
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (pickup != null)
              Marker(
                point: pickup,
                width: 42,
                height: 42,
                child: const Icon(Icons.location_on, color: _kChekupGreen, size: 38),
              ),
            if (drop != null)
              Marker(
                point: drop,
                width: 42,
                height: 42,
                child: const Icon(Icons.local_hospital, color: Colors.red, size: 34),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Widget _buildSection3(BuildContext context, BookingProvider prov) {
    final ageStr = prov.patientAge.isNotEmpty ? '${prov.patientAge} Years' : 'N/A';
    final genderStr = prov.patientGender != 'Select gender' ? prov.patientGender : 'N/A';

    return _cardWrapper(
      context: context,
      step: '3', title: 'Patient Details',
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: _kChekupGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: _kChekupGreen, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _infoBlock('Patient Name', prov.patientName.isEmpty ? 'Unknown' : prov.patientName)),
                    Expanded(child: _infoBlock('Phone Number', prov.patientPhone.isEmpty ? 'Unknown' : prov.patientPhone)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _infoBlock('Age', ageStr)),
                    Expanded(child: _infoBlock('Gender', genderStr)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection4(BuildContext context, BookingProvider prov) {
    final condition = prov.patientCondition;

    Color cColor = _kChekupGreen;
    String desc = 'Patient is in stable condition.';
    if (condition == 'Emergency') { cColor = const Color(0xFFE65100); desc = 'Patient requires urgent medical care.'; }
    if (condition == 'Critical') { cColor = const Color(0xFFC62828); desc = 'Patient is in critical life-support condition.'; }

    return _cardWrapper(
      context: context,
      step: '4', title: 'Patient Condition',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF4FBF6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1E8D9))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: const BoxDecoration(color: Color(0xFFE2F3E7), shape: BoxShape.circle), 
              child: Icon(Icons.monitor_heart, color: _kChekupGreen, size: 22)
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: cColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(condition, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: cColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection5(BuildContext context, BookingProvider prov) {
    final requirements = prov.patientRequirements.isNotEmpty
        ? prov.patientRequirements.map((r) {
            if (r == 'Others' && prov.otherRequirementDetails.trim().isNotEmpty) {
              return 'Others: ${prov.otherRequirementDetails.trim()}';
            }
            return r;
          }).toList()
        : ['None specified'];

    return _cardWrapper(
      context: context,
      step: '5', title: 'Patient Requirements',
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: requirements.map((req) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF4F8F4), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: _kChekupGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
                const SizedBox(width: 8),
                Text(req, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection6(BuildContext context, BookingProvider prov) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFDCEDC8))
      ),
      child: Row(
        children: [
          Image.asset('assets/images/ambulance.png', width: 85, height: 60, fit: BoxFit.contain),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ambulance Available', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _kChekupGreen)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Arrival', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Color(0xFF1E293B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  prov.etaStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: const Color(0xFFDCEDC8), margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Distance', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF1E293B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${prov.distanceStr} (Approx.)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection7(BuildContext context, BookingProvider prov) {
    return GestureDetector(
      onTap: () => _showFareDetailsDialog(context, prov),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.currency_rupee, color: Color(0xFFD97706), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Estimated Fare',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('₹${prov.totalPayable.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _kChekupGreen)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Fare confirmed before dispatch', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Details', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 11)),
                Icon(Icons.chevron_right, color: Color(0xFFD97706), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFareDetailsDialog(BuildContext context, BookingProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fare Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Base Fare', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                    Text('₹${prov.baseFare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
                  ],
                ),
                if (!prov.walletBenefitAlreadyUsed) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Apply ₹50 Wallet Benefit', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                      Switch(
                        value: prov.applyWallet,
                        onChanged: (val) {
                          prov.toggleWalletBenefit();
                          setDialogState(() {});
                        },
                        activeColor: _kChekupGreen,
                      )
                    ],
                  ),
                ],
                if (prov.applyWallet && !prov.walletBenefitAlreadyUsed) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet Benefit Discount', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      Text('-₹${prov.ambulanceWalletBenefit.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kChekupGreen)),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                    Text('₹${prov.totalPayable.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kChekupGreen)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kChekupGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, BookingProvider prov) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _kChekupGreen,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Estimated Arrival', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
                                Text(prov.etaStr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                Text('(${prov.distanceStr} away)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white30),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 6,
                    child: GestureDetector(
                      onTap: prov.state == BookingState.loading
                          ? null
                          : () async {
                              final ok = await prov.submitBooking();
                              if (ok && context.mounted) {
                                final rid = prov.createdRequestId!;
                                prov.reset();
                                Navigator.of(context).pushReplacementNamed('/tracking', arguments: rid);
                              }
                            },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            prov.state == BookingState.loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _kChekupGreen, strokeWidth: 2))
                                : const Text('Request Ambulance', style: TextStyle(color: _kChekupGreen, fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, color: _kChekupGreen, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock, color: Color(0xFF0F2851), size: 13),
                SizedBox(width: 6),
                Text('Your safety is our priority. We are here to help you, 24/7.', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red.withOpacity(0.3))),
      child: Row(children: [const Icon(Icons.error, color: AppColors.red, size: 24), const SizedBox(width: 12), Expanded(child: Text(msg, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 14)))]),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double dashHeight = 4, dashSpace = 4, startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
