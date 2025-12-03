// lib/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new report
  Future<bool> submitReport({
    required String userId,
    required String userEmail,
    required String userName,
    required String category,
    required String userType,
    required String subject,
    required String details,
    String? photoBase64,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'userId': userId, // This is crucial for filtering
        'userEmail': userEmail,
        'userName': userName,
        'category': category,
        'userType': userType,
        'subject': subject,
        'details': details,
        'photoBase64': photoBase64,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }

  // Get reports for a specific user only
 // Fetch reports using email instead of userId
Future<List<Map<String, dynamic>>> getUserReportsByUserId(String userId) async {
  try {
    final querySnapshot = await _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)  // ← query by userId, not email
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  } catch (e) {
    print('Error fetching reports by userId: $e');
    return [];
  }
}




  // Update a report
  Future<bool> updateReport(String reportId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('reports')
          .doc(reportId)
          .update({
            ...updates,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('Error updating report: $e');
      return false;
    }
  }

  // Delete a report
  Future<bool> deleteReport(String reportId) async {
    try {
      await _firestore
          .collection('reports')
          .doc(reportId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }
}