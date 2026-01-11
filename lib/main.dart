// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:profile_managemenr/sprint4/offline_support.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/services/notification_service.dart';
import 'package:profile_managemenr/home/core/routes/app_routes.dart';
import 'package:profile_managemenr/home/core/widgets/auth_wrapper.dart';
import 'package:profile_managemenr/constants/app_theme.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📬 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 ============================================');
  print('🚀 APP STARTING');
  print('🚀 ============================================');

  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env loaded');
  } catch (e) {
    print('⚠️ .env not found');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background handler set');
    
    final notificationService = NotificationService();
    await notificationService.initialize();
    
  } catch (e, stackTrace) {
    print('❌ Initialization error: $e');
    print('Stack trace: $stackTrace');
  }

  print('🚀 ============================================');

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
        navigatorKey: navigatorKey,
        title: 'Campus Closet',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
      ),
    );
  }
}