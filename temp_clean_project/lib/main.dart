// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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
    
    // Initialize App Check with retry logic
    try {
      await FirebaseAppCheck.instance.activate(
        // For Android: Use debug provider during development
        androidProvider: AndroidProvider.debug,
        // For iOS: Use debug provider during development
        appleProvider: AppleProvider.debug,
        // For Web (if you support web)
        // webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
      );
      
      debugPrint("✅ App Check initialized successfully");
      
      // Try to get token to verify it's working
      final token = await FirebaseAppCheck.instance.getToken();
      if (token != null) {
        debugPrint("✅ App Check token obtained successfully");
      } else {
        debugPrint("⚠️ App Check token is null");
      }
    } catch (appCheckError) {
      debugPrint("⚠️ App Check initialization failed: $appCheckError");
      // Continue without App Check - app will still work but functions might fail
    }
    
  } catch (e) {
    // Log error but don't rethrow — let app start with limited functionality
    debugPrint("⚠️ Firebase initialization failed: $e");
    // Optional: show alert dialog later if needed
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ ONLY ONE AuthService instance
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Other providers
        ChangeNotifierProvider(create: (_) => OfflineSupport()),
        // Add more providers here as needed
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