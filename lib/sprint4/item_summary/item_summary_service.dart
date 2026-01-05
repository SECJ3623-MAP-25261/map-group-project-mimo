// lib/sprint4/item_summary/item_summary_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ItemSummaryService {
  ItemSummaryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _summaryRef(String itemId) {
    return _firestore.collection('item_summaries').doc(itemId);
  }

  Future<void> initializeSummaryIfNeeded({
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    final ref = _summaryRef(itemId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;

      tx.set(ref, {
        'itemId': itemId,
        'renterId': itemData['renterId'],
        'itemName': itemData['name'],
        'category': itemData['category'],
        'size': itemData['size'],
        'pricePerDay': (itemData['pricePerDay'] is num)
            ? (itemData['pricePerDay'] as num).toDouble()
            : 0.0,

        'views': 0,
        'edits': 0,

        'bookingsTotal': 0,
        'bookingsPending': 0,
        'bookingsConfirmed': 0,
        'bookingsOngoing': 0,
        'bookingsCompleted': 0,
        'bookingsCancelled': 0,

        'totalRentalDays': 0,
        'totalEarnings': 0,

        'lastViewedAt': null,
        'lastBookedAt': null,
        'lastCompletedAt': null,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> recordView({
    required String itemId,
    Map<String, dynamic>? itemDataForInit,
  }) async {
    if (itemDataForInit != null) {
      await initializeSummaryIfNeeded(itemId: itemId, itemData: itemDataForInit);
    }

    final ref = _summaryRef(itemId);
    await ref.set({
      'views': FieldValue.increment(1),
      'lastViewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordEdit({
    required String itemId,
    Map<String, dynamic>? itemDataForInit,
  }) async {
    if (itemDataForInit != null) {
      await initializeSummaryIfNeeded(itemId: itemId, itemData: itemDataForInit);
    }

    final ref = _summaryRef(itemId);
    await ref.set({
      'edits': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordBookingCreated({
    required String itemId,
    required String status, // usually "pending"
    Map<String, dynamic>? itemDataForInit,
  }) async {
    if (itemDataForInit != null) {
      await initializeSummaryIfNeeded(itemId: itemId, itemData: itemDataForInit);
    }

    final ref = _summaryRef(itemId);
    final statusField = _statusToField(status);

    await ref.set({
      'bookingsTotal': FieldValue.increment(1),
      if (statusField != null) statusField: FieldValue.increment(1),
      'lastBookedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordBookingStatusChange({
    required String itemId,
    required String oldStatus,
    required String newStatus,
    required num finalFee,
    required int rentalDays,
    Map<String, dynamic>? itemDataForInit,
  }) async {
    if (itemDataForInit != null) {
      await initializeSummaryIfNeeded(itemId: itemId, itemData: itemDataForInit);
    }

    final ref = _summaryRef(itemId);

    final oldField = _statusToField(oldStatus);
    final newField = _statusToField(newStatus);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);

      // If summary doesn't exist, create minimal fallback (still ok)
      if (!snap.exists) {
        tx.set(ref, {
          'itemId': itemId,
          'views': 0,
          'edits': 0,
          'bookingsTotal': 0,
          'bookingsPending': 0,
          'bookingsConfirmed': 0,
          'bookingsOngoing': 0,
          'bookingsCompleted': 0,
          'bookingsCancelled': 0,
          'totalRentalDays': 0,
          'totalEarnings': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (oldField != null && oldField != newField) {
        updates[oldField] = FieldValue.increment(-1);
      }
      if (newField != null && oldField != newField) {
        updates[newField] = FieldValue.increment(1);
      }

      // Add earnings only when entering "completed"
      if (newStatus == 'completed' && oldStatus != 'completed') {
        updates['totalEarnings'] = FieldValue.increment(finalFee.toDouble());
        updates['totalRentalDays'] = FieldValue.increment(rentalDays);
        updates['lastCompletedAt'] = FieldValue.serverTimestamp();
      }

      // Optional: if somehow reverted from completed -> something else
      if (oldStatus == 'completed' && newStatus != 'completed') {
        updates['totalEarnings'] = FieldValue.increment(-finalFee.toDouble());
        updates['totalRentalDays'] = FieldValue.increment(-rentalDays);
      }

      tx.set(ref, updates, SetOptions(merge: true));
    });
  }

  String? _statusToField(String status) {
    switch (status) {
      case 'pending':
        return 'bookingsPending';
      case 'confirmed':
        return 'bookingsConfirmed';
      case 'ongoing':
        return 'bookingsOngoing';
      case 'completed':
        return 'bookingsCompleted';
      case 'cancelled':
        return 'bookingsCancelled';
      default:
        return null;
    }
  }
}
