// lib/services/booking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookingsCollection = 'bookings';
  final String _reviewsCollection = 'reviews';

  /// Create a new booking
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
  }) async {
    try {
      final docRef = await _firestore.collection(_bookingsCollection).add({
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
        'actualReturnDate': null, // Set when item is returned
        'rentalDays': rentalDays,
        'totalAmount': totalAmount,
        'finalFee': totalAmount, // Can be updated if there are late fees
        'paymentMethod': paymentMethod,
        'status': 'pending', // pending, confirmed, ongoing, completed, cancelled
        'hasReview': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id; // Return booking ID
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

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

  /// ✅ NEW: Get bookings where user is the RENTER (lender)
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

  /// Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
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
      // Create review document
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

      // Update booking to mark as reviewed
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

  /// ✅ NEW: Stream for renter bookings (optional but useful)
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