import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/auth/auth_provider.dart';
import 'src/core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/routes/app_router.dart';
import 'src/features/vendor/vendor_provider.dart';
import 'src/features/vendor/driver_provider.dart';
import 'src/features/vendor/fleet_provider.dart';
import 'src/features/driver/driver_auth_provider.dart';
import 'src/core/network/dio_client.dart';
import 'src/features/booking/booking_provider.dart';
import 'src/features/requests/requests_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv initialization skipped or failed: $e');
  }

  final auth = AuthProvider();
  try {
    await auth.init();
    if (!auth.isLoggedIn) {
      await auth.login(name: 'Patient', phone: '');
    }
  } catch (e) {
    debugPrint('Auth initialization error: $e');
  }

  final driverAuth = DriverAuthProvider();
  try {
    await driverAuth.init();
  } catch (e) {
    debugPrint('DriverAuth initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: driverAuth),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => FleetProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(DioClient(tokenProvider: () async => auth.token)),
          update: (_, auth, prev) => prev ?? BookingProvider(DioClient(tokenProvider: () async => auth.token)),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RequestsProvider>(
          create: (_) => RequestsProvider(DioClient(tokenProvider: () async => auth.token)),
          update: (_, auth, prev) => prev ?? RequestsProvider(DioClient(tokenProvider: () async => auth.token)),
        ),
      ],
      child: const CallHealthApp(),
    ),
  );
}


class CallHealthApp extends StatelessWidget {
  const CallHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallHealth Ambulance',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.0,
            ),
          ),
          child: Container(
            color: const Color(0xFF0F172A),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
