import 'package:flutter/material.dart';
import 'package:profile_managemenr/sprint2/renter_dashboard/booking_request.dart';
import 'package:profile_managemenr/sprint2/Rentee/HistoryRentee/history_rentee.dart';

void handleNotificationNavigation({
  required BuildContext context,
  required Map<String, dynamic> data,
  required String userId,
}) {
  final type = data['type'];
  final bookingId = data['bookingId'];

  if (type == 'booking_request') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingRequestsScreen(
          renterId: userId,
          focusBookingId: bookingId,
        ),
      ),
    );
  }

  else if (
    type == 'booking_approved' ||
    type == 'booking_rejected' ||
    type == 'booking_cancelled'
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryRenteeScreen(isRenter: false),
      ),
    );
  }
}
