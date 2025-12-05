import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map> getReviewStats(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'count': 0, 'average': 0.0};
      }

      int total = snapshot.docs.length;
      double sum = 0;

      for (var doc in snapshot.docs) {
        sum += (doc['rating'] as num).toDouble();
      }

      return {
        'count': total,
        'average': sum / total,
      };
    } catch (e) {
      return {'count': 0, 'average': 0.0, 'error': e.toString()};
    }
  }

  Stream getReviewsStream(String itemId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future addReview({
    required String itemId,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'itemId': itemId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }
}