import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/sprint4/item_summary/item_summary_service.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String _bookingsCollection = 'bookings';
  final String _reviewsCollection = 'reviews';

  // ========== OVERLAP PREVENTION METHODS ==========

  /// Fetch all existing bookings for a specific item
  Future<List<Map<String, dynamic>>> getItemBookings(String itemId) async {
    try {
      print('🔍 Fetching bookings for itemId: $itemId');
      final snapshot = await _firestore
          .collection(_bookingsCollection)
          .where('itemId', isEqualTo: itemId)
          .where('status', whereIn: ['pending', 'confirmed', 'ongoing'])
          .get();

      print('✅ Found ${snapshot.docs.length} existing bookings');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
          'status': data['status'],
        };
      }).toList();
    } catch (e, stackTrace) {
      print('❌ Error fetching item bookings: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if a date range overlaps with existing bookings
  bool isDateRangeAvailable(
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> existingBookings,
  ) {
    for (var booking in existingBookings) {
      final bookedStart = booking['startDate'] as DateTime;
      final bookedEnd = booking['endDate'] as DateTime;

      if (startDate.isBefore(bookedEnd.add(const Duration(days: 1))) &&
          endDate.isAfter(bookedStart.subtract(const Duration(days: 1)))) {
        return false;
      }
    }
    return true;
  }

  /// Get set of all unavailable dates for the item
  Set<DateTime> getUnavailableDates(List<Map<String, dynamic>> bookings) {
    final unavailableDates = <DateTime>{};
    
    for (var booking in bookings) {
      final startDate = booking['startDate'] as DateTime;
      final endDate = booking['endDate'] as DateTime;
      
      DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        unavailableDates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    
    return unavailableDates;
  }

  // ========== CREATE BOOKING WITH NOTIFICATIONS ==========

  /// Create a new booking with overlap check and notification
  /// Returns booking ID on success, error message string on failure
  Future<String?> createBooking({
    required String userId,
    required String userEmail,
    required String userName,
    required String renterId,
    required String itemId,
    required String itemName,
    required String itemImage,
    required double itemPrice,
    required DateTime startDate,
    required DateTime endDate,
    required int rentalDays,
    required double totalAmount,
    required String paymentMethod,
    required String meetUpAddress,
    required double meetUpLatitude,
    required double meetUpLongitude,
  }) async {
    try {
      print('🔍 Checking for existing bookings for item: $itemId');
      
      // Check for overlapping bookings
      List<Map<String, dynamic>> existingBookings = [];
      try {
        existingBookings = await getItemBookings(itemId);
        print('🔍 Found ${existingBookings.length} existing bookings');
      } catch (e) {
        print('⚠️ Could not check for existing bookings, proceeding anyway: $e');
      }
      
      if (existingBookings.isNotEmpty && 
          !isDateRangeAvailable(startDate, endDate, existingBookings)) {
        print('⚠️ Date range overlaps with existing booking');
        return 'ABORTED: OVERLAP';
      }

      print('✅ Date range is available, creating booking...');
      
      final bookingData = {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'renterId': renterId,
        'itemId': itemId,
        'itemName': itemName,
        'itemImage': itemImage,
        'itemPrice': itemPrice,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'actualReturnDate': null,
        'rentalDays': rentalDays,
        'totalAmount': totalAmount,
        'finalFee': totalAmount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'hasReview': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'meetUpAddress': meetUpAddress,
        'meetUpLatitude': meetUpLatitude,
        'meetUpLongitude': meetUpLongitude,
      };
      
      print('📝 Booking data: $bookingData');
      
      final docRef = await _firestore.collection(_bookingsCollection).add(bookingData);
      final bookingId = docRef.id;

      // Record in item summary
      await ItemSummaryService().recordBookingCreated(
        itemId: itemId,
        status: (bookingData['status'] ?? 'pending').toString(),
      );

      // 🔔 SEND NOTIFICATION TO RENTER
      try {
        await _notificationService.notifyRenterOfBookingRequest(
          renterId: renterId,
          renteeId: userId,
          renteeName: userName,
          itemName: itemName,
          bookingId: bookingId,
        );
        print('✅ Notification sent to renter');
      } catch (e) {
        print('⚠️ Failed to send notification (non-critical): $e');
        // Don't fail the booking if notification fails
      }

      print('✅ Booking created successfully with ID: $bookingId');
      return bookingId;
      
    } catch (e, stackTrace) {
      print('❌ Error creating booking: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      
      String errorMsg = e.toString();
      if (errorMsg.contains('PERMISSION_DENIED')) {
        errorMsg = 'Permission denied. Check Firebase security rules.';
      } else if (errorMsg.contains('UNAVAILABLE') || errorMsg.contains('network')) {
        errorMsg = 'Network error. Please check your connection.';
      } else if (errorMsg.contains('INVALID_ARGUMENT')) {
        errorMsg = 'Invalid data. Please check all fields are filled correctly.';
      }
      return 'ERROR: $errorMsg';
    }
  }

  // ========== UPDATE BOOKING STATUS WITH NOTIFICATIONS ==========

  /// Update booking status with automatic notifications
  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      // Get booking details first for notifications
      final bookingDoc = await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .get();
      
      if (!bookingDoc.exists) {
        print('❌ Booking not found: $bookingId');
        return false;
      }

      final booking = bookingDoc.data()!;
      final renteeId = booking['userId'] as String;
      final itemName = booking['itemName'] as String;
      final meetUpAddress = booking['meetUpAddress'] as String? ?? 'Location TBD';
      final startDate = (booking['startDate'] as Timestamp).toDate();
      final endDate = (booking['endDate'] as Timestamp).toDate();

      // Update status in Firestore
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Booking status updated to: $newStatus');

      // 🔔 SEND APPROPRIATE NOTIFICATIONS BASED ON STATUS
      try {
        switch (newStatus) {
          case 'confirmed':
            await _notificationService.notifyRenteeOfBookingApproval(
              renteeId: renteeId,
              itemName: itemName,
              bookingId: bookingId,
              meetUpAddress: meetUpAddress,
              startDate: startDate,
            );
            print('✅ Approval notification sent to rentee');
            break;

          case 'cancelled':
            await _notificationService.notifyRenteeOfBookingRejection(
              renteeId: renteeId,
              itemName: itemName,
              bookingId: bookingId,
            );
            print('✅ Rejection notification sent to rentee');
            break;

          case 'ongoing':
            await _notificationService.notifyRenteeOfPickupConfirmation(
              renteeId: renteeId,
              itemName: itemName,
              bookingId: bookingId,
              endDate: endDate,
            );
            
            // Schedule return reminder
            await _scheduleReturnReminder(
              renteeId: renteeId,
              itemName: itemName,
              bookingId: bookingId,
              endDate: endDate,
            );
            print('✅ Pickup confirmation sent to rentee');
            break;

          case 'completed':
            await _notificationService.notifyRenteeOfReturnConfirmation(
              renteeId: renteeId,
              itemName: itemName,
              bookingId: bookingId,
            );
            print('✅ Return confirmation sent to rentee');
            break;
        }
      } catch (e) {
        print('⚠️ Failed to send notification (non-critical): $e');
        // Don't fail the status update if notification fails
      }

      return true;
    } catch (e) {
      print('❌ Error updating booking status: $e');
      return false;
    }
  }

  /// Schedule return reminder
  Future<void> _scheduleReturnReminder({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required DateTime endDate,
  }) async {
    try {
      final reminderDate = endDate.subtract(const Duration(days: 1));
      
      await _firestore.collection('scheduled_notifications').add({
        'userId': renteeId,
        'type': 'return_reminder',
        'bookingId': bookingId,
        'itemName': itemName,
        'endDate': Timestamp.fromDate(endDate),
        'scheduledFor': Timestamp.fromDate(reminderDate),
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Return reminder scheduled for: $reminderDate');
    } catch (e) {
      print('⚠️ Error scheduling reminder: $e');
    }
  }

  // ========== EXISTING METHODS ==========

  /// Get user's bookings (as RENTEE / borrower)
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  /// Get bookings where user is the RENTER (lender)
  Future<List<Map<String, dynamic>>> getRenterBookings(String renterId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('renterId', isEqualTo: renterId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching renter bookings: $e');
      return [];
    }
  }

  /// Get bookings by status (for rentee)
  Future<List<Map<String, dynamic>>> getBookingsByStatus(
      String userId, String status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching bookings by status: $e');
      return [];
    }
  }

  /// Update actual return date and final fee
  Future<bool> updateReturnInfo(
      String bookingId, DateTime returnDate, double finalFee) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'actualReturnDate': Timestamp.fromDate(returnDate),
        'finalFee': finalFee,
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating return info: $e');
      return false;
    }
  }

  /// Submit a review
  Future<bool> submitReview({
    required String bookingId,
    required String userId,
    required String userEmail,
    required String userName,
    required String itemId,
    required String itemName,
    required int rating,
    required String ratingLabel,
    required String comment,
  }) async {
    try {
      await _firestore.collection(_reviewsCollection).add({
        'bookingId': bookingId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'itemId': itemId,
        'itemName': itemName,
        'rating': rating,
        'ratingLabel': ratingLabel,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'hasReview': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  /// Get reviews for an item
  Future<List<Map<String, dynamic>>> getItemReviews(String itemId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('itemId', isEqualTo: itemId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching item reviews: $e');
      return [];
    }
  }

  /// Get average rating for an item
  Future<double> getItemAverageRating(String itemId) async {
    try {
      final reviews = await getItemReviews(itemId);
      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + (review['rating'] as int),
      );

      return totalRating / reviews.length;
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }

  /// Stream of user bookings for real-time updates (rentee)
  Stream<List<Map<String, dynamic>>> getUserBookingsStream(String userId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream for renter bookings
  Stream<List<Map<String, dynamic>>> getRenterBookingsStream(String renterId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }
}