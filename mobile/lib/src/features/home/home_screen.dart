import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kGreen = Color(0xFF5BA438);
const Color _kBlue = Color(0xFF0F2851);
const Color _kText = Color(0xFF475569);

class HomeScreen extends StatefulWidget {
  final ValueChanged<DateTime?> onBookAmbulance;
  const HomeScreen({super.key, required this.onBookAmbulance});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmbulanceBanner(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5BA438), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            borderRadius: BorderRadius.circular(27),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(Icons.person, color: Color(0xFF263238), size: 34),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, User', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text('HYD, Gachibowli', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Prominent Vendor Portal Button in Header
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/vendor/login'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2851),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white38, width: 1),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.business_center, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Vendor',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.notifications_none, color: Colors.white, size: 25),
        ],
      ),
    );
  }

  Widget _buildAmbulanceBanner() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9EBD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/ambulance_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Right side CallHealth Ambulance Van on the road curve
          Positioned(
            right: -15,
            bottom: -5,
            child: Image.asset(
              'assets/images/callhealth_ambulance.png',
              width: 215,
              height: 130,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/ambulance_transparent.png',
                  width: 215,
                  height: 130,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
          // Left side Content & Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Need Ambulance?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "We're Just a Call Away!",
                  style: TextStyle(
                    color: Color(0xFF123FC4),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '24/7 Emergency Ambulance Services\nFast. Reliable. Always Here.',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Phone Call Pill Button: [phone icon] 9133557799
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final uri = Uri.parse('tel:9133557799');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF4C9F2E), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, color: Color(0xFF4C9F2E), size: 16),
                        SizedBox(width: 8),
                        Text(
                          '9133557799',
                          style: TextStyle(
                            color: Color(0xFF4C9F2E),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Primary Green Pill Button: Book Ambulance [>]
                ElevatedButton(
                  onPressed: () => widget.onBookAmbulance(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C9F2E),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Book Ambulance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Color(0xFF4C9F2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, -3))],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() => _selectedTab = index);
          if (index == 2) widget.onBookAmbulance(null);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _kGreen,
        unselectedItemColor: _kBlue,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Vitals'),
          BottomNavigationBarItem(icon: Icon(Icons.circle, size: 30), label: 'Chekup'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Medications'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Reports'),
        ],
      ),
    );
  }
}
