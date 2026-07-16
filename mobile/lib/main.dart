import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/auth/auth_provider.dart';
import 'src/core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/routes/app_router.dart';
import 'src/features/tracking/tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final auth = AuthProvider();
  await auth.init();
  // If not logged in yet (fresh install), auto-login as guest
  // so users land directly on the booking screen.
  if (!auth.isLoggedIn) {
    await auth.login(name: 'Patient', phone: '');
  }
  runApp(
    ChangeNotifierProvider.value(
      value: auth,
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
      theme: AppTheme.light,
      initialRoute: '/tracking',
      onGenerateRoute: (settings) {
        if (settings.name == '/tracking') {
          return MaterialPageRoute(
            builder: (_) => const TrackingScreen(),
            settings: RouteSettings(name: '/tracking', arguments: '27c49d4a-3456-4218-8951-d3782f109054'),
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
    );
  }
}
