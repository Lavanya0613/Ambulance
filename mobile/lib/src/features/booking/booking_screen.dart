import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'booking_provider.dart';

const Color _kDarkGreen = Color(0xFF5BA438);
const Color _kTopGreen = Color(0xFF5BA438);
const Color _kBgColor = Color(0xFFF8FAFC);
const Color _kBorderColor = Color(0xFFE2E8F0);

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
  final _ageCtrl = TextEditingController();
  
  bool _showPickupSuggestions = false;
  bool _showDropSuggestions = false;

  final List<String> _selectedRequirements = [];

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _toggleRequirement(String req) {
    setState(() {
      if (_selectedRequirements.contains(req)) {
        _selectedRequirements.remove(req);
      } else {
        _selectedRequirements.add(req);
      }
    });
    // Update provider notes
    context.read<BookingProvider>().setField(notes: _selectedRequirements.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        if (prov.state == BookingState.success && prov.createdRequestId != null) {
          return _SuccessOverlay(requestId: prov.createdRequestId!, onTrack: () {
            final rid = prov.createdRequestId!;
            prov.reset();
            _pickupCtrl.clear(); _dropCtrl.clear();
            _nameCtrl.clear(); _phoneCtrl.clear(); _ageCtrl.clear();
            Navigator.of(context).pushReplacementNamed('/tracking', arguments: rid);
          });
        }
        return Scaffold(
          backgroundColor: _kBgColor,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTopBanner(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            if (prov.errorMsg != null) _errorBanner(prov.errorMsg!),
                            _build247Card(),
                            if (prov.scheduledFor != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB9D0FF))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month, color: Color(0xFF1565C0)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('Scheduled for ${DateFormat('EEE, d MMM, h:mm a').format(prov.scheduledFor!.toLocal())}', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700))),
                                    TextButton(onPressed: () => prov.setSchedule(null), child: const Text('Change')),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _buildFormBody(context, prov),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomStickyBar(prov),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kDarkGreen,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Book Ambulance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
            Positioned(
              right: 12,
              top: 14,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBanner() {
    return Column(
      children: [
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/ambulance_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 140, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('We\'re Here to', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F2851))),
                      const Text('Save Lives', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _kDarkGreen)),
                      const SizedBox(height: 8),
                      const Text('24/7 emergency ambulance\nservice at your fingertips.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F2851))),
                      const Spacer(),
                      Row(
                        children: [
                          _bannerFeature(Icons.verified_user_outlined, 'Trained\nProfessionals'),
                          const SizedBox(width: 8),
                          _bannerFeature(Icons.access_time, 'Quick\nResponse'),
                          const SizedBox(width: 8),
                          _bannerFeature(Icons.health_and_safety_outlined, 'Safe &\nReliable'),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -30,
                  bottom: -15,
                  child: Image.asset(
                    'assets/images/ambulance_transparent.png',
                    width: 250,
                    height: 140,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: const BoxDecoration(color: _kDarkGreen, shape: BoxShape.circle)),
            Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
            Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
          ],
        )
      ],
    );
  }

  Widget _bannerFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _kTopGreen, size: 18),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.secondary)),
      ],
    );
  }

  Widget _build247Card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.phone, color: _kDarkGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Need an Ambulance?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F2851))),
                SizedBox(height: 4),
                Text('Request an ambulance in just a few steps.\nWe\'ll locate the nearest available unit.', style: TextStyle(fontSize: 10, color: Color(0xFF0F2851))),
              ],
            ),
          ),
          Column(
            children: const [
              Text('24/7', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kDarkGreen)),
              Text('Service', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kDarkGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody(BuildContext context, BookingProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section 1: Location Details ───
        _buildSectionHeader('1', 'Location Details', action: TextButton.icon(
          onPressed: () async {
            _pickupCtrl.text = 'Locating...';
            await prov.getCurrentLocation();
            if (prov.pickupLocation != null) {
              _pickupCtrl.text = prov.pickupLocation!.address;
            } else {
              _pickupCtrl.clear();
            }
          },
          icon: const Icon(Icons.my_location, size: 16, color: _kDarkGreen),
          label: const Text('Locate Me', style: TextStyle(color: _kDarkGreen, fontSize: 11, fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(backgroundColor: const Color(0xFFF1F8F4), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), minimumSize: const Size(0, 30)),
        )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pickup Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F2851))),
              const SizedBox(height: 6),
              _addressField(
                icon: Icons.location_on,
                controller: _pickupCtrl, hint: 'Enter pickup address',
                selected: prov.pickupLocation, suggestions: prov.pickupSuggestions,
                isSearching: prov.pickupSearching, showSuggestions: _showPickupSuggestions,
                onChanged: (q) { prov.searchPickup(q); setState(() => _showPickupSuggestions = true); },
                onSelect: (s) { prov.selectPickup(s); _pickupCtrl.text = s.displayName; setState(() => _showPickupSuggestions = false); },
                onTap: () => setState(() => _showPickupSuggestions = true),
                onUseCurrentLocation: () async {
                  setState(() => _showPickupSuggestions = false);
                  _pickupCtrl.text = 'Locating...';
                  await prov.getCurrentLocation();
                  if (prov.pickupLocation != null) {
                    _pickupCtrl.text = prov.pickupLocation!.address;
                  } else {
                    _pickupCtrl.clear();
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Destination (Hospital / Facility)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F2851))),
              const SizedBox(height: 6),
              _addressField(
                icon: Icons.business,
                controller: _dropCtrl, hint: 'Search hospital or destination',
                selected: prov.dropLocation, suggestions: prov.dropSuggestions,
                isSearching: prov.dropSearching, showSuggestions: _showDropSuggestions,
                onChanged: (q) { prov.searchDrop(q); setState(() => _showDropSuggestions = true); },
                onSelect: (s) { prov.selectDrop(s); _dropCtrl.text = s.displayName; setState(() => _showDropSuggestions = false); },
                onTap: () => setState(() => _showDropSuggestions = true),
              ),
            ],
          ),
        ),
        
        // ─── Section 2: Select Ambulance Type ───
        const SizedBox(height: 24),
        _buildSectionHeader('2', 'Select Ambulance Type'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildAmbulanceTypeCard(prov, 'BLS', 'Standard', 'For general\nmedical needs.', Icons.health_and_safety, const Color(0xFFE8F5E9), const Color(0xFF2E7D32))),
            const SizedBox(width: 8),
            Expanded(child: _buildAmbulanceTypeCard(prov, 'ALS', 'Emergency', 'For serious\nemergencies.', Icons.warning_amber_rounded, const Color(0xFFFFF3E0), const Color(0xFFE65100))),
            const SizedBox(width: 8),
            Expanded(child: _buildAmbulanceTypeCard(prov, 'ICU', 'Critical Care', 'For life-support\npatients.', Icons.monitor_heart, const Color(0xFFFFEBEE), const Color(0xFFC62828))),
          ],
        ),

        // ─── Section 3: Patient Details ───
        const SizedBox(height: 24),
        _buildSectionHeader('3', 'Patient Details'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            children: [
              _buildInputCol('Patient Name', 'Enter patient name', Icons.person_outline, _nameCtrl, (v) => prov.setField(patientName: v)),
              const SizedBox(height: 16),
              _buildInputCol('Phone Number', 'Enter mobile number', Icons.phone_outlined, _phoneCtrl, (v) => prov.setField(patientPhone: v), prefixText: '+91   '),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputCol('Age (Optional)', 'Enter age', Icons.calendar_today_outlined, _ageCtrl, (v) => prov.setField(patientAge: v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdownCol('Gender (Optional)', prov.patientGender, Icons.person_outline, (val) {
                    if (val != null) prov.setField(patientGender: val);
                  })),
                ],
              ),
            ],
          ),
        ),

        // ─── Section 4: Patient Condition ───
        const SizedBox(height: 24),
        _buildSectionHeader('4', 'Patient Condition'),
        const SizedBox(height: 4),
        const Text('Select the current condition of the patient.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPatientConditionCard(prov, 'Normal', const Color(0xFFE8F5E9), const Color(0xFF2E7D32))),
            const SizedBox(width: 8),
            Expanded(child: _buildPatientConditionCard(prov, 'Emergency', const Color(0xFFFFF3E0), const Color(0xFFE65100))),
            const SizedBox(width: 8),
            Expanded(child: _buildPatientConditionCard(prov, 'Critical', const Color(0xFFFFEBEE), const Color(0xFFC62828))),
          ],
        ),

        // ─── Section 5: Patient Requirements ───
        const SizedBox(height: 24),
        _buildSectionHeader('5', 'Patient Requirements'),
        const SizedBox(height: 4),
        const Text('Select all that apply.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            _buildRequirementCheck(prov, 'Need Wheelchair'),
            _buildRequirementCheck(prov, 'Difficulty Breathing'),
            _buildRequirementCheck(prov, 'Unconscious'),
            _buildRequirementCheck(prov, 'Chest Pain'),
            _buildRequirementCheck(prov, 'Serious Injured'),
            _buildRequirementCheck(prov, 'Bleeding'),
            _buildRequirementCheck(prov, 'Others'),
          ],
        ),
        if (prov.patientRequirements.contains('Others')) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kDarkGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.edit_note, size: 18, color: _kDarkGreen),
                    SizedBox(width: 6),
                    Text(
                      'Describe Other Requirements',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F2851)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please specify any additional equipment, medical condition, or special assistance required (e.g., Portable Oxygen, Stretcher, Specialist Doctor on board).',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: prov.otherRequirementDetails,
                  onChanged: (val) => prov.setField(otherRequirementDetails: val),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F2851)),
                  decoration: InputDecoration(
                    hintText: 'Type your specific requirements here...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kDarkGreen, width: 1.5)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0.0),
        ],

        // ─── Estimated Arrival Summary Card (At Last of Page Content) ───
        if (prov.hasBothLocations) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FBF6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1E8D9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2F3E7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: _kDarkGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Arrival: ${prov.etaStr}',
                            style: const TextStyle(color: _kDarkGreen, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kDarkGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              prov.distanceStr,
                              style: const TextStyle(color: _kDarkGreen, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Calculated from pickup to destination location.',
                        style: TextStyle(color: Color(0xFF334155), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String number, String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 26, height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: _kDarkGreen, shape: BoxShape.circle),
              child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F2851))),
          ],
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildInputCol(String label, String hint, IconData icon, TextEditingController ctrl, Function(String) onChanged, {String? prefixText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F2851))),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 14),
                  Icon(icon, size: 18, color: const Color(0xFF334155)),
                  if (prefixText != null) ...[
                    const SizedBox(width: 8),
                    Text(prefixText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F2851))),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCol(String label, String currentValue, IconData icon, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F2851))),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ['Male', 'Female', 'Other'].contains(currentValue) ? currentValue : null,
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF334155)),
                  const SizedBox(width: 8),
                  Text(currentValue, style: const TextStyle(color: Color(0xFF334155), fontSize: 12)),
                ],
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF334155)),
              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: const TextStyle(fontSize: 13, color: Color(0xFF0F2851))),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmbulanceTypeCard(BookingProvider prov, String typeCode, String label, String subtitle, IconData icon, Color bg, Color border) {
    final selected = prov.ambulanceType == typeCode;
    return GestureDetector(
      onTap: () {
        prov.setField(ambulanceType: typeCode);
        if (typeCode == 'ALS') prov.setField(priority: 'high');
        else if (typeCode == 'ICU') prov.setField(priority: 'critical');
        else prov.setField(priority: 'normal');
      },
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FBF6) : Colors.white,
          border: Border.all(color: selected ? _kDarkGreen : const Color(0xFFE2E8F0), width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected ? bg : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: selected ? border : Colors.grey),
                ),
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? _kDarkGreen : Colors.grey, width: 1.5),
                    color: selected ? _kDarkGreen : Colors.white,
                  ),
                  child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F2851))),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientConditionCard(BookingProvider prov, String condition, Color bg, Color border) {
    final selected = prov.patientCondition == condition;
    return GestureDetector(
      onTap: () => prov.setPatientCondition(condition),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? bg.withOpacity(0.4) : Colors.white,
          border: Border.all(color: selected ? border : const Color(0xFFE2E8F0), width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? border : Colors.grey, width: 1.5),
                color: selected ? bg : Colors.white,
              ),
              child: selected ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: border, shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(condition, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF0F2851)))),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementCheck(BookingProvider prov, String label) {
    final selected = prov.patientRequirements.contains(label);
    return GestureDetector(
      onTap: () => prov.toggleRequirement(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FBF6) : Colors.white,
          border: Border.all(color: selected ? _kDarkGreen : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: selected ? _kDarkGreen : Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(4),
                color: selected ? _kDarkGreen : Colors.white,
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: const Color(0xFF0F2851))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomStickyBar(BookingProvider prov) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDarkGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: prov.state == BookingState.loading
                ? null
                : () => Navigator.of(context).pushNamed('/review'),
            child: prov.state == BookingState.loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Continue to Review',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _addressField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required LocationResult? selected,
    required List<AddressSuggestion> suggestions,
    required bool isSearching,
    required bool showSuggestions,
    required Function(String) onChanged,
    required Function(AddressSuggestion) onSelect,
    VoidCallback? onTap,
    VoidCallback? onUseCurrentLocation,
  }) {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onTap: onTap,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              prefixIcon: Icon(icon, size: 20, color: _kDarkGreen),
              suffixIcon: isSearching
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  : selected != null
                      ? const Icon(Icons.check_circle, color: _kDarkGreen, size: 20)
                      : const Icon(Icons.my_location, color: Colors.grey, size: 20),
            ),
          ),
        ),
        if (showSuggestions)
          if (suggestions.isNotEmpty || onUseCurrentLocation != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorderColor),
              ),
              child: Column(
                children: [
                  if (onUseCurrentLocation != null)
                    InkWell(
                      onTap: onUseCurrentLocation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.my_location, color: _kTopGreen, size: 16),
                            SizedBox(width: 10),
                            Expanded(child: Text('Use Current Location', style: TextStyle(fontSize: 13, color: _kTopGreen, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                  ...suggestions.map((s) => InkWell(
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
                ],
              ),
            )
          else if (controller.text.length < 3)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorderColor),
              ),
              child: const Text('Type at least 3 characters to search...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            )
          else if (!isSearching)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorderColor),
              ),
              child: const Text('No locations found', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
      ],
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFFE57373), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.w600, fontSize: 13))),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              ScaleTransition(
                scale: _scale,
                child: const Icon(Icons.check_circle, color: _kTopGreen, size: 80),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ambulance Requested!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.darkBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your request has been confirmed.\nAssigning the nearest driver...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFf0f4f8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    Text('ESTIMATED ARRIVAL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.2)),
                    SizedBox(height: 4),
                    Text('5 min', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _kTopGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: widget.onTrack,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Track Ambulance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDarkGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  context.read<BookingProvider>().reset();
                },
                child: const Text('Dismiss & Book New Ambulance', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
