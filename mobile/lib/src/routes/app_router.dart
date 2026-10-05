import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/main/main_shell.dart';
import '../features/tracking/tracking_screen.dart';
import '../features/tracking/completed_screen.dart';
import '../features/main/ambulance_shell.dart';
import '../features/booking/review_booking_screen.dart';
import '../features/requests/order_details_screen.dart';
import '../features/vendor/vendor_login_screen.dart';
import '../features/vendor/vendor_dashboard_screen.dart';
import '../features/driver/screens/driver_login_screen.dart';
import '../features/driver/screens/driver_dashboard_screen.dart';
import '../features/driver/screens/driver_navigation_screen.dart';
import '../features/driver/screens/driver_profile_screen.dart';
import '../features/driver/screens/driver_trip_history_screen.dart';
import '../features/driver/screens/driver_notification_screen.dart';
import '../features/driver/screens/driver_settings_screen.dart';
import '../features/payment/payment_screen.dart';

class AppRouter {
  static const String splash  = '/';
  static const String home    = '/home';
  static const String tracking = '/tracking';
  static const String completed = '/completed';
  static const String review = '/review';
  static const String booking = '/booking';
  static const String orderDetails = '/order_details';
  static const String vendorLogin = '/vendor/login';
  static const String vendorDashboard = '/vendor/dashboard';
  static const String driverLogin = '/driver/login';
  static const String driverDashboard = '/driver/dashboard';
  static const String driverNavigation = '/driver/navigation';
  static const String driverProfile = '/driver/profile';
  static const String driverHistory = '/driver/history';
  static const String driverNotifications = '/driver/notifications';
  static const String driverSettings = '/driver/settings';
  static const String payment = '/payment';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell(), settings: settings);
      case tracking:
        return MaterialPageRoute(builder: (_) => const TrackingScreen(), settings: settings);
      case completed:
        return MaterialPageRoute(builder: (_) => const CompletedScreen(), settings: settings);
      case booking:
        return MaterialPageRoute(builder: (_) => const AmbulanceShell(), settings: settings);
      case review:
        return MaterialPageRoute(builder: (_) => const ReviewBookingScreen(), settings: settings);
      case orderDetails:
        return MaterialPageRoute(builder: (_) => const OrderDetailsScreen(), settings: settings);
      case vendorLogin:
        return MaterialPageRoute(builder: (_) => const VendorLoginScreen(), settings: settings);
      case vendorDashboard:
        return MaterialPageRoute(builder: (_) => const VendorDashboardScreen(), settings: settings);
      case driverLogin:
        return MaterialPageRoute(builder: (_) => const DriverLoginScreen(), settings: settings);
      case driverDashboard:
        return MaterialPageRoute(builder: (_) => const DriverDashboardScreen(), settings: settings);
      case driverNavigation:
        return MaterialPageRoute(builder: (_) => const DriverNavigationScreen(), settings: settings);
      case driverProfile:
        return MaterialPageRoute(builder: (_) => const DriverProfileScreen(), settings: settings);
      case driverHistory:
        return MaterialPageRoute(builder: (_) => const DriverTripHistoryScreen(), settings: settings);
      case driverNotifications:
        return MaterialPageRoute(builder: (_) => const DriverNotificationScreen(), settings: settings);
      case driverSettings:
        return MaterialPageRoute(builder: (_) => const DriverSettingsScreen(), settings: settings);
      case payment:
        return MaterialPageRoute(builder: (_) => const PaymentScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Page not found'))),
          settings: settings,
        );
    }
  }
}
