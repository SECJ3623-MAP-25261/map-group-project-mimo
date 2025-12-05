// 2. core/routes/app_routes.dart


import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/accounts/registration/registration_app.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/profile.dart';
import 'package:profile_managemenr/sprint2/Booking%20Rentee/booking.dart';
import 'package:profile_managemenr/sprint2/chatMessaging/item_chat_list_view.dart';
import 'package:profile_managemenr/sprint2/IssueReport/ReportCenter/report_center.dart';
import 'package:profile_managemenr/sprint2/searchRentee/search.dart';
import 'package:profile_managemenr/home/screens/campus_closet_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String booking = '/booking';
  static const String report = '/report';
  static const String messages = '/messages';
  static const String search = '/search';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const CampusClosetScreen(),
        login: (context) => const LoginPage(),
        register: (context) => const RegistrationApp(),
        profile: (context) => const ProfileScreen(),
        booking: (context) => const BookingScreen(),
        report: (context) => const ReportCenterScreen(),
        messages: (context) => const ItemChatListView(),
        search: (context) => const SearchPage(),
      };
}