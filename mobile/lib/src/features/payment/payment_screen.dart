import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../booking/booking_provider.dart';
import '../../core/theme/app_theme.dart';

const Color _kGreen = Color(0xFF5BA438);
const Color _kRed = Color(0xFFEF4444);
const Color _kLightBg = Color(0xFFF8FAFC);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Auto-start payment flow on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPaymentFlow());
  }

  Future<void> _runPaymentFlow() async {
    if (_started) return;
    _started = true;
    final prov = context.read<BookingProvider>();

    // Step 1: Initiate → PENDING
    final initiated = await prov.initiatePayment();
    if (!initiated) return; // will show failed state

    // Small delay for UX (show "Processing" for at least 1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Step 2: Process → SUCCESS or FAILED
    await prov.processPayment();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          backgroundColor: _kLightBg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildBody(context, prov),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BookingProvider prov) {
    switch (prov.paymentState) {
      case PaymentState.initiating:
      case PaymentState.processing:
        return _buildProcessingView(prov);
      case PaymentState.success:
        return _buildSuccessView(prov);
      case PaymentState.failed:
        return _buildFailedView(context, prov);
      default:
        return _buildProcessingView(prov);
    }
  }

  // ─────────────────────────── PROCESSING ────────────────────────────────────
  Widget _buildProcessingView(BookingProvider prov) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated spinner
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: _kGreen, strokeWidth: 3),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: _kGreen.withOpacity(0.1)),
          const SizedBox(height: 40),
          const Text(
            'Processing Payment',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Text(
            prov.paymentState == PaymentState.initiating
                ? 'Initiating secure payment...'
                : 'Verifying and confirming your payment...',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildBillingSummary(prov),
          const SizedBox(height: 24),
          const Text(
            'Do not press back or close the app.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── SUCCESS ───────────────────────────────────────
  Widget _buildSuccessView(BookingProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Green animated check icon
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_circle_rounded, color: _kGreen, size: 52),
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          
          const Text(
            'Payment Successful \u2713',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 6),
          const Text(
            'Ambulance booking confirmed & searching nearby driver.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 28),

          // Formal Healthcare Receipt Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID & Type Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BOOKING ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            prov.createdRequestId != null
                                ? prov.createdRequestId!.split('-').first.toUpperCase()
                                : 'CONFIRMED',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${prov.ambulanceType} Ambulance',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _kGreen),
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),

                // Pickup & Destination Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, color: _kGreen, size: 12),
                        Container(width: 2, height: 28, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 2)),
                        const Icon(Icons.location_on, color: Colors.red, size: 14),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PICKUP LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            prov.pickupLocation?.address ?? 'Not specified',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          const Text('DESTINATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            prov.dropLocation?.address ?? 'Not specified',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),

                // Payment Details
                _detailRow('Amount Paid', '\u20B9${prov.totalPayable.toInt()}', isBold: true, valueColor: const Color(0xFF0F172A)),
                if (prov.serverWalletDiscount > 0 || (prov.applyWallet && !prov.walletBenefitAlreadyUsed)) ...[
                  const SizedBox(height: 8),
                  _detailRow('Wallet Discount', '-\u20B9${prov.serverWalletDiscount > 0 ? prov.serverWalletDiscount.toInt() : prov.ambulanceWalletBenefit.toInt()}', valueColor: _kGreen),
                ],
                if (prov.paymentTransactionRef != null) ...[
                  const SizedBox(height: 8),
                  _detailRow('Payment Ref', prov.paymentTransactionRef!),
                ],
                const SizedBox(height: 8),
                _detailRow('Booking Time', _formatTime(DateTime.now())),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 28),

          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (prov.createdRequestId != null) {
                  final rid = prov.createdRequestId!;
                  prov.reset();
                  Navigator.of(context).pushReplacementNamed(
                    '/tracking',
                    arguments: rid,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Track Ambulance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color valueColor = AppColors.textSecondary}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 15 : 12,
              color: valueColor,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────── FAILED ────────────────────────────────────────
  Widget _buildFailedView(BuildContext context, BookingProvider prov) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.cancel_rounded, color: _kRed, size: 72),
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          const Text(
            'Payment Failed',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your payment was not completed.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildBillingSummary(prov),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                _started = false;
                _runPaymentFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back to Booking', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── BILLING SUMMARY ───────────────────────────────
  Widget _buildBillingSummary(BookingProvider prov) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _summaryRow('Base Fare', '₹${prov.baseFare.toInt()}', color: const Color(0xFF1E293B)),
          if (prov.serverWalletDiscount > 0 || (prov.applyWallet && !prov.walletBenefitAlreadyUsed)) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Wallet Benefit',
              '-₹${prov.serverWalletDiscount > 0 ? prov.serverWalletDiscount.toInt() : prov.ambulanceWalletBenefit.toInt()}',
              color: _kGreen,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _summaryRow('Total Payable', '₹${prov.totalPayable.toInt()}', bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color color = AppColors.textSecondary, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: bold ? 16 : 13, color: color, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }
}
