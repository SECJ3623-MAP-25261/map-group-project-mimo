import 'package:flutter/material.dart';
import 'accounts/profile/screen/profile/profile.dart';
import 'accounts/profile/screen/profile/edit_profile.dart';
import 'accounts/registration/registration.dart';

void main() {
  runApp(CampusClosetApp());
}

class CampusClosetApp extends StatelessWidget {
  const CampusClosetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Closet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),

      // 🧭 Initial screen shown when the app starts
      initialRoute: '/registration',

      // 🗺️ Named routes
      routes: {
        '/profile': (context) => ProfileScreen(),
        '/editProfile': (context) => EditProfileScreen(),
      },
    );
  }
}
