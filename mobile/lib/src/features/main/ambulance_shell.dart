import 'package:flutter/material.dart';
import '../booking/booking_screen.dart';
import '../requests/my_requests_screen.dart';

const Color _kNavGreen = Color(0xFF009C51);
const Color _kNavBlue = Color(0xFF1E293B); // Slate color for unselected

class AmbulanceShell extends StatefulWidget {
  const AmbulanceShell({super.key});

  @override
  State<AmbulanceShell> createState() => _AmbulanceShellState();
}

class _AmbulanceShellState extends State<AmbulanceShell> {
  int _currentIndex = 0;

  final _pages = [
    const BookingScreen(),
    const MyRequestsScreen(),
    const Scaffold(body: Center(child: Text('Support Screen'))),
    const Scaffold(body: Center(child: Text('Profile Screen'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB), // Web background
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Scaffold(
            body: IndexedStack(index: _currentIndex, children: _pages),
            bottomNavigationBar: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, 'Home'),
                  _buildNavItem(1, Icons.assignment_outlined, 'My Orders'),
                  _buildNavItem(2, Icons.headset_mic_outlined, 'Support'),
                  _buildNavItem(3, Icons.person_outline, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 12),
            Icon(icon, size: 24, color: isSelected ? _kNavGreen : _kNavBlue),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: isSelected ? _kNavGreen : _kNavBlue)),
            const Spacer(),
            Container(
              height: 3,
              width: 36,
              decoration: BoxDecoration(
                color: isSelected ? _kNavGreen : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
