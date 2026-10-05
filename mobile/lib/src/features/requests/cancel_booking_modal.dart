import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

const Color _kDarkGreen = Color(0xFF00561B);

class CancelBookingModal extends StatefulWidget {
  final String requestId;
  final Future<bool> Function(String reason) onConfirmCancel;

  const CancelBookingModal({
    super.key,
    required this.requestId,
    required this.onConfirmCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
    required Future<bool> Function(String reason) onConfirmCancel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelBookingModal(
        requestId: requestId,
        onConfirmCancel: onConfirmCancel,
      ),
    );
  }

  @override
  State<CancelBookingModal> createState() => _CancelBookingModalState();
}

class _CancelBookingModalState extends State<CancelBookingModal> {
  String _selectedReason = 'eta_too_high';
  final TextEditingController _customCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  final List<Map<String, String>> _reasons = [
    {
      'code': 'eta_too_high',
      'title': 'Ambulance Delayed / High ETA',
      'subtitle': 'Estimated arrival time is taking longer than expected.',
      'icon': '⏱️',
    },
    {
      'code': 'found_other_transport',
      'title': 'Found Alternative Transport',
      'subtitle': 'Patient is being transported by private vehicle or taxi.',
      'icon': '🚗',
    },
    {
      'code': 'booked_by_mistake',
      'title': 'Booked by Mistake',
      'subtitle': 'Incorrect address, details, or duplicate booking.',
      'icon': '📍',
    },
    {
      'code': 'wrong_ambulance_type',
      'title': 'Wrong Ambulance Type Selected',
      'subtitle': 'Need a different type of medical equipment or vehicle.',
      'icon': '🚑',
    },
    {
      'code': 'other',
      'title': 'Other Reason',
      'subtitle': 'Specify additional details for cancellation.',
      'icon': '✏️',
    },
  ];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final finalReason = _selectedReason == 'other' && _customCtrl.text.trim().isNotEmpty
        ? 'Other: ${_customCtrl.text.trim()}'
        : _selectedReason;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final success = await widget.onConfirmCancel(finalReason);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isLoading = false;
            _errorMsg = 'Failed to cancel request. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'An error occurred while processing cancellation.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Cancel Ambulance Request?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Please tell us why you need to cancel this emergency request.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_errorMsg != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Select Cancellation Reason',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F2851)),
            ),
            const SizedBox(height: 12),

            // Reasons List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reasons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _reasons[index];
                  final isSelected = _selectedReason == item['code'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReason = item['code']!;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.red : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(item['icon']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppColors.red : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle']!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: item['code']!,
                            groupValue: _selectedReason,
                            activeColor: AppColors.red,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedReason = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Custom Text Field if "other" is selected
            if (_selectedReason == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Type your cancellation reason here...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.red, width: 1.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kDarkGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Keep Booking',
                        style: TextStyle(color: _kDarkGreen, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Confirm Cancel',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
