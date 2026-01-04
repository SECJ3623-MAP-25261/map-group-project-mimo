// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:profile_managemenr/sprint4/offline_support.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/home/core/routes/app_routes.dart';
import 'package:profile_managemenr/home/core/widgets/auth_wrapper.dart';
import 'package:profile_managemenr/constants/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (optional: don't crash if missing)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    debugPrint("✅ Firebase initialized successfully");
    
    // 🔥 APP CHECK COMPLETELY DISABLED
    // Do NOT initialize App Check at all - this prevents the SDK from sending invalid tokens
    debugPrint("⚠️ App Check is DISABLED");
    
  } catch (e) {
    debugPrint("⚠️ Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OfflineSupport()),
      ],
      child: MaterialApp(
        title: 'Campus Closet',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        ),
      ),
    );
  }
}