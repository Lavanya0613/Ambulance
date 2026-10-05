import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../booking/booking_provider.dart';
import '../requests/requests_provider.dart';

import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

const Color _kNavGreen = Color(0xFF5BA438);
const Color _kNavBlue = Color(0xFF1565C0);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onBookAmbulance(DateTime? scheduledFor) {
    context.read<BookingProvider>().setSchedule(scheduledFor);
    Navigator.pushNamed(context, '/booking');
  }

  void _showImmediateCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 12,
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8EA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBE9BD), width: 2),
                      ),
                    ),
                    const Icon(Icons.phone_in_talk_rounded, color: _kNavGreen, size: 36),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Book an Ambulance Now',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Call our 24/7 ambulance dispatch center to arrange immediate emergency transport.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FBF6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD1E8D9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.phone, color: _kNavGreen, size: 22),
                      SizedBox(width: 10),
                      Text(
                        '9133557799',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kNavGreen, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final uri = Uri.parse('tel:9133557799');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.call, color: Colors.white, size: 20),
                    label: const Text(
                      'Call Ambulance',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavGreen,
                      elevation: 2,
                      shadowColor: _kNavGreen.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBookingOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 18),
              const Text('Book Ambulance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Choose when you need the ambulance.', style: TextStyle(color: Colors.black54, fontSize: 15)),
              const SizedBox(height: 20),
              _bookingChoice(
                sheetContext,
                value: 'now',
                color: const Color(0xFFEFF8EA),
                accent: _kNavGreen,
                icon: Icons.emergency,
                title: 'Book for Now',
                subtitle: 'Call our 24/7 service immediately.',
              ),
              const SizedBox(height: 12),
              _bookingChoice(
                sheetContext,
                value: 'later',
                color: const Color(0xFFEAF1FF),
                accent: _kNavBlue,
                icon: Icons.calendar_month,
                title: 'Book for Later',
                subtitle: 'Schedule an ambulance for a preferred date & time.',
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BookingBenefit(icon: Icons.verified_user, text: '24/7 Availability'),
                  _BookingBenefit(icon: Icons.verified, text: 'Verified Drivers'),
                  _BookingBenefit(icon: Icons.location_on, text: 'Across Hyderabad'),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || choice == null) return;
    if (choice == 'now') {
      final uri = Uri.parse('tel:9133557799');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      initialDate: today,
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted || time == null) return;
    final scheduledFor = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (scheduledFor.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a time at least 5 minutes from now.')));
      return;
    }
    _onBookAmbulance(scheduledFor);
  }

  Widget _bookingChoice(BuildContext sheetContext, {required String value, required Color color, required Color accent, required IconData icon, required String title, required String subtitle}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pop(sheetContext, value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, border: Border.all(color: accent.withOpacity(0.35)), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: accent, child: Icon(icon, color: Colors.white, size: 30)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 13, height: 1.3))])),
            CircleAvatar(radius: 20, backgroundColor: accent, child: const Icon(Icons.chevron_right, color: Colors.white, size: 28)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final client = DioClient(tokenProvider: () async => auth.token);

    final _pages = [
      HomeScreen(onBookAmbulance: (_) => _showBookingOptions()),
      const Scaffold(body: Center(child: Text('Vitals Screen (Under Construction)'))),
      const Scaffold(body: Center(child: Text('Chekup Center (Under Construction)'))),
      const Scaffold(body: Center(child: Text('Medications Screen (Under Construction)'))),
      const Scaffold(body: Center(child: Text('Reports Screen (Under Construction)'))),
    ];

    return Container(
      color: const Color(0xFFF0F4F8), // Outer web background
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Scaffold(
            body: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ),
      ),
    );
  }
}

class _BookingBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BookingBenefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Icon(icon, color: _kNavGreen, size: 24), const SizedBox(height: 5), Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]);
  }
}
