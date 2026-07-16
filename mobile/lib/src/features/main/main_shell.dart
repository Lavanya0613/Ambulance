import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../booking/booking_provider.dart';
import '../booking/booking_screen.dart';
import '../requests/requests_provider.dart';
import '../requests/my_requests_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    BookingScreen(),
    MyRequestsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final client = DioClient(tokenProvider: () async => auth.token);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider(client)),
        ChangeNotifierProvider(create: (_) => RequestsProvider(client)),
      ],
      child: Container(
        color: const Color(0xFFF0F4F8), // Outer web background
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
            ),
            child: Scaffold(
              appBar: AppBar(
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('CallHealth', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.darkBlue)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: 'Book',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'My Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ))));
  }
}
