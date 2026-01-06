// lib/main.dart (WITH NOTIFICATIONS)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📬 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    debugPrint("✅ Firebase initialized successfully");
    
    // Initialize Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    debugPrint("✅ Firebase Messaging background handler set");
    
  } catch (e) {
    debugPrint("⚠️ Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      debugPrint("✅ Notifications initialized");
    } catch (e) {
      debugPrint("⚠️ Notification initialization failed: $e");
    }
  }

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

// Updated AuthWrapper to save FCM token after login
class AuthWrapperWithNotifications extends StatelessWidget {
  const AuthWrapperWithNotifications({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final notificationService = NotificationService();

    // Save FCM token when user logs in
    if (authService.userId != null) {
      notificationService.saveFcmToken(authService.userId!);
    }

    return const AuthWrapper();
  }
}