import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'booking_provider.dart';

const _kAmbulanceTypes = [
  {'id': 'BLS', 'title': '🟢 Standard Ambulance', 'desc': 'General medical emergencies and patient transport.', 'color': AppColors.green},
  {'id': 'ALS', 'title': '🟠 Emergency Ambulance', 'desc': 'For serious emergencies requiring advanced medical care.', 'color': AppColors.amber},
  {'id': 'ICU', 'title': '🔴 Critical Care Ambulance', 'desc': 'For ICU-level patients needing life-support equipment.', 'color': AppColors.red},
];

const _kUrgencyLevels = [
  {'id': 'normal', 'label': 'Normal', 'color': AppColors.green, 'bg': AppColors.greenLight},
  {'id': 'high', 'label': 'High', 'color': AppColors.amber, 'bg': AppColors.amberLight},
  {'id': 'critical', 'label': 'Critical', 'color': AppColors.red, 'bg': AppColors.redLight},
];

const _kCommonNotes = [
  'Difficulty breathing', 'Needs wheelchair', 'Severe bleeding',
  'Chest pain', 'Unconscious', 'Fever & Chills',
];

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _showPickupSuggestions = false;
  bool _showDropSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from auth can be done if needed
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        // Show success overlay
        if (prov.state == BookingState.success && prov.createdRequestId != null) {
          return _SuccessOverlay(requestId: prov.createdRequestId!, onTrack: () {
            final rid = prov.createdRequestId!;
            prov.reset();
            _pickupCtrl.clear(); _dropCtrl.clear();
            _nameCtrl.clear(); _phoneCtrl.clear(); _notesCtrl.clear();
            Navigator.of(context).pushNamed('/tracking', arguments: rid);
          });
        }
        return _buildForm(context, prov);
      },
    );
  }

  Widget _buildForm(BuildContext context, BookingProvider prov) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const SizedBox(height: 8),
          const Text(
            'Book Emergency Ambulance',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.darkBlue),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fast, reliable emergency ambulance service. Enter your pickup location and destination.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFf0f4f8),
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: AppColors.green, width: 5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Need an Ambulance? We\'re Here to Help',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkBlue, fontSize: 15)),
                SizedBox(height: 4),
                Text('Request an ambulance in just a few steps. We\'ll locate the nearest available unit.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error
          if (prov.errorMsg != null) _errorBanner(prov.errorMsg!),

          // Location Card
          _card(
            icon: Icons.location_on,
            title: 'Location Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
                    TextButton.icon(
                      onPressed: () => prov.getCurrentLocation(),
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Locate Me', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkBlue,
                        backgroundColor: const Color(0xFFf0f4f8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _addressField(
                  controller: _pickupCtrl,
                  hint: 'Enter pickup address...',
                  selected: prov.pickupLocation,
                  suggestions: prov.pickupSuggestions,
                  isSearching: prov.pickupSearching,
                  showSuggestions: _showPickupSuggestions,
                  onChanged: (q) {
                    prov.searchPickup(q);
                    setState(() => _showPickupSuggestions = true);
                  },
                  onSelect: (s) {
                    prov.selectPickup(s);
                    _pickupCtrl.text = s.displayName;
                    setState(() => _showPickupSuggestions = false);
                  },
                ),

                const SizedBox(height: 16),

                // Drop
                const Text('Destination', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                _addressField(
                  controller: _dropCtrl,
                  hint: 'Search hospital or destination...',
                  selected: prov.dropLocation,
                  suggestions: prov.dropSuggestions,
                  isSearching: prov.dropSearching,
                  showSuggestions: _showDropSuggestions,
                  onChanged: (q) {
                    prov.searchDrop(q);
                    setState(() => _showDropSuggestions = true);
                  },
                  onSelect: (s) {
                    prov.selectDrop(s);
                    _dropCtrl.text = s.displayName;
                    setState(() => _showDropSuggestions = false);
                  },
                ),
              ],
            ),
          ),

          // Patient Info Card
          _card(
            icon: Icons.person_outline,
            title: 'Patient Information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Patient Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (v) => prov.setField(patientName: v),
                        decoration: const InputDecoration(hintText: 'e.g. John Doe'),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => prov.setField(patientPhone: v),
                        decoration: const InputDecoration(hintText: '+91...'),
                      ),
                    ])),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Emergency Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: _kUrgencyLevels.map((level) {
                    final id = level['id'] as String;
                    final label = level['label'] as String;
                    final color = level['color'] as Color;
                    final bg = level['bg'] as Color;
                    final selected = prov.priority == id;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => prov.setField(priority: id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? bg : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: selected ? color : AppColors.cardBorder, width: selected ? 2 : 1),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, color: selected ? color : AppColors.textMuted),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Medical Needs Card
          _card(
            icon: Icons.local_hospital_outlined,
            title: 'Medical Needs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ambulance Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                ..._kAmbulanceTypes.map((type) {
                  final id = type['id'] as String;
                  final title = type['title'] as String;
                  final desc = type['desc'] as String;
                  final color = type['color'] as Color;
                  final selected = prov.ambulanceType == id;
                  return GestureDetector(
                    onTap: () => prov.setField(ambulanceType: id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? color : AppColors.cardBorder, width: selected ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.darkBlue : AppColors.darkBlue, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                const Text('Patient Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _kCommonNotes.map((note) => ActionChip(
                    label: Text('+ $note'),
                    onPressed: () => prov.appendNote(note),
                    backgroundColor: const Color(0xFFf0f4f8),
                    labelStyle: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w600, fontSize: 12),
                    side: BorderSide.none,
                  )).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  onChanged: (v) => prov.setField(notes: v),
                  decoration: const InputDecoration(hintText: 'e.g. Difficulty breathing, needs wheelchair...'),
                ),
              ],
            ),
          ),

          // CTA Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFf0f4f8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('NEAREST AMBULANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
                      SizedBox(height: 2),
                      Text('~5 mins away', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkBlue)),
                      Text('Service Area: Active', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: prov.state == BookingState.loading ? null : () => prov.submitBooking(),
                      child: prov.state == BookingState.loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Request Ambulance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressField({
    required TextEditingController controller,
    required String hint,
    required LocationResult? selected,
    required List<AddressSuggestion> suggestions,
    required bool isSearching,
    required bool showSuggestions,
    required Function(String) onChanged,
    required Function(AddressSuggestion) onSelect,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            suffixIcon: isSearching
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : selected != null
                    ? const Icon(Icons.check_circle, color: AppColors.green, size: 20)
                    : null,
          ),
        ),
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: suggestions.map((s) => InkWell(
                onTap: () => onSelect(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.displayName, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _card({required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.green, size: 22),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkBlue)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

// ─── Success Overlay ───────────────────────────────────────────────────────────
class _SuccessOverlay extends StatefulWidget {
  final String requestId;
  final VoidCallback onTrack;
  const _SuccessOverlay({required this.requestId, required this.onTrack});
  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: const Icon(Icons.check_circle, color: AppColors.green, size: 120),
              ),
              const SizedBox(height: 24),
              const Text('Ambulance Requested!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.darkBlue), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Your request has been confirmed.\nAssigning the nearest driver...', style: TextStyle(color: AppColors.textSecondary, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(color: const Color(0xFFf0f4f8), borderRadius: BorderRadius.circular(20)),
                child: Column(children: const [
                  Text('ESTIMATED ARRIVAL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text('5 min', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.green)),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: widget.onTrack,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Track Ambulance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
