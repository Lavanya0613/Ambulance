import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/main/main_shell.dart';
import '../features/tracking/tracking_screen.dart';

class AppRouter {
  static const String splash  = '/';
  static const String home    = '/home';
  static const String tracking = '/tracking';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell(), settings: settings);
      case tracking:
        return MaterialPageRoute(builder: (_) => const TrackingScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Page not found'))),
          settings: settings,
        );
    }
  }
}
