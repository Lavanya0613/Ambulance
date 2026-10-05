import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'requests_provider.dart';
import 'cancel_booking_modal.dart';

const Color _kChekupGreen = Color(0xFF5BA438);
const Color _kLightBg = Color(0xFFF8FAFC);

const _kStatusMeta = {
  'PENDING':           {'label': 'Pending',       'color': AppColors.secondary, 'bg': AppColors.border},
  'REQUEST_CREATED':   {'label': 'Created',       'color': AppColors.secondary, 'bg': AppColors.border},
  'SEARCHING_DRIVER':  {'label': 'Searching',     'color': AppColors.amber,     'bg': Color(0xFFFEF3C7)},
  'VENDOR_ACCEPTED':   {'label': 'Accepted',      'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5)},
  'DRIVER_ASSIGNED':   {'label': 'Driver Assigned','color': _kChekupGreen,      'bg': Color(0xFFD1FAE5)},
  'EN_ROUTE':          {'label': 'En Route',      'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5)},
  'ARRIVED':           {'label': 'Arrived',       'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5)},
  'PATIENT_ONBOARD':   {'label': 'Onboard',       'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5)},
  'DESTINATION_REACHED':{'label': 'At Hospital',  'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5)},
  'COMPLETED':         {'label': 'Completed',     'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5)},
  'CANCELLED':         {'label': 'Cancelled',     'color': AppColors.red,       'bg': Color(0xFFFEE2E2)},
  'FAILED':            {'label': 'Failed',        'color': AppColors.red,       'bg': Color(0xFFFEE2E2)},
};

const _kActiveStatuses = {
  'REQUEST_CREATED', 'PENDING', 'SEARCHING_DRIVER', 'VENDOR_ACCEPTED',
  'DRIVER_ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'PATIENT_ONBOARD'
};

const _kCancelableStatuses = {
  'REQUEST_CREATED', 'PENDING', 'SEARCHING_DRIVER'
};

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat('d MMMM y, hh:mm a').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as AmbulanceRequest?;
    if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    final meta = _kStatusMeta[order.status] ?? _kStatusMeta['PENDING']!;
    final color = meta['color'] as Color;
    final bg = meta['bg'] as Color;
    final label = meta['label'] as String;

    final isActive = _kActiveStatuses.contains(order.status);
    final canCancel = _kCancelableStatuses.contains(order.status);

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
                  _buildAppBar(context, order),
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
                                  _buildStatusCard(order, label, color, bg),
                                  const SizedBox(height: 16),
                                  _buildRouteCard(order),
                                  if (order.driver != null) const SizedBox(height: 16),
                                  if (order.driver != null) _buildDriverCard(order),
                                  const SizedBox(height: 16),
                                  _buildPatientFareCard(order),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                          _buildBottomCTA(context, order, isActive, canCancel),
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
  }

  Widget _buildAppBar(BuildContext context, AmbulanceRequest order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Booking Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 2),
                Text(order.requestNumber.isNotEmpty ? order.requestNumber : 'ID: ${order.requestId.substring(0, 8)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  Widget _cardWrapper({required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusCard(AmbulanceRequest order, String label, Color color, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
            child: Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          Text(order.requestNumber.isNotEmpty ? order.requestNumber : 'Booking', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.secondary)),
          const SizedBox(height: 4),
          Text(_formatDate(order.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(AmbulanceRequest order) {
    return _cardWrapper(
      title: 'Route',
      child: Row(
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
              const Icon(Icons.add_box, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _kChekupGreen)),
                const SizedBox(height: 4),
                Text(order.pickupAddress ?? 'Not available', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.4)),
                const SizedBox(height: 16),
                const Text('Destination', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red)),
                const SizedBox(height: 4),
                Text(order.dropAddress ?? 'Not available', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(AmbulanceRequest order) {
    return _cardWrapper(
      title: 'Ambulance Assigned',
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: _kChekupGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.person, color: _kChekupGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.driver!.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _kChekupGreen, borderRadius: BorderRadius.circular(4)),
                      child: Text(order.driver!.ambulanceType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(order.driver!.vehicleNumber, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
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

  Widget _buildPatientFareCard(AmbulanceRequest order) {
    return _cardWrapper(
      title: 'Additional Details',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Patient Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(order.patientName.isNotEmpty ? order.patientName : 'Self', textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.border)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Estimated Fare', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('N/A', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _kChekupGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, AmbulanceRequest order, bool isActive, bool canCancel) {
    if (!isActive && !canCancel) return const SizedBox.shrink();

    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: order.requestId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kChekupGreen, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('Track Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          if (canCancel) ...[
            if (isActive) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: () => _handleCancel(context, order.requestId),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.red, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.red.withOpacity(0.3))),
                  backgroundColor: Colors.white,
                ),
                child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, String requestId) async {
    final success = await CancelBookingModal.show(
      context,
      requestId: requestId,
      onConfirmCancel: (reason) async {
        return await context.read<RequestsProvider>().cancelRequest(requestId, reason);
      },
    );

    if (success == true && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
    }
  }
}
