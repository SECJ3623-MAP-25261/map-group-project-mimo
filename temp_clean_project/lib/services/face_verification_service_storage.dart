import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Face Verification Service - NO IMAGES STORED!
/// Uses ONLY face features (geometry + landmarks) for comparison
/// 100% FREE - No storage costs, no Firestore size issues!
class FaceVerificationServiceStorage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late FaceDetector _faceDetector;
  
  FaceVerificationServiceStorage() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  /// Detect faces in an image
  Future<List<Face>> detectFaces(File imageFile) async {
    try {
      print('👤 Detecting faces in image...');
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      print('✅ Detected ${faces.length} face(s)');
      return faces;
    } catch (e) {
      print('❌ Error detecting faces: $e');
      return [];
    }
  }

  /// Extract face features for comparison
  Future<List<double>?> extractFaceFeatures(File imageFile, Face face) async {
    try {
      print('🔍 Extracting face features...');
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final boundingBox = face.boundingBox;
      final padding = 20;
      final x = (boundingBox.left - padding).clamp(0, image.width);
      final y = (boundingBox.top - padding).clamp(0, image.height);
      final width = (boundingBox.width + padding * 2).clamp(0, image.width - x);
      final height = (boundingBox.height + padding * 2).clamp(0, image.height - y);
      
      final croppedFace = img.copyCrop(
        image,
        x: x.toInt(),
        y: y.toInt(),
        width: width.toInt(),
        height: height.toInt(),
      );

      final resizedFace = img.copyResize(croppedFace, width: 128, height: 128);
      final features = <double>[];
      
      // Normalized bounding box
      features.add(boundingBox.width / image.width);
      features.add(boundingBox.height / image.height);
      
      // Landmarks
      if (face.landmarks.isNotEmpty) {
        for (var landmark in face.landmarks.values) {
          if (landmark != null) {
            features.add(landmark.position.x / image.width);
            features.add(landmark.position.y / image.height);
          }
        }
      }
      
      // Classifications
      if (face.smilingProbability != null) features.add(face.smilingProbability!);
      if (face.leftEyeOpenProbability != null) features.add(face.leftEyeOpenProbability!);
      if (face.rightEyeOpenProbability != null) features.add(face.rightEyeOpenProbability!);
      
      // Simple pixel stats (optional but adds robustness)
      final rgb = resizedFace.getBytes();
      if (rgb.isNotEmpty) {
        // Average R, G, B per channel (just 3 values)
        int rSum = 0, gSum = 0, bSum = 0;
        for (int i = 0; i < rgb.length; i += 4) {
          rSum += rgb[i];
          gSum += rgb[i + 1];
          bSum += rgb[i + 2];
        }
        final count = (rgb.length / 4).floor();
        if (count > 0) {
          features.add(rSum / count / 255.0);
          features.add(gSum / count / 255.0);
          features.add(bSum / count / 255.0);
        }
      }

      print('✅ Extracted ${features.length} features');
      return features;
    } catch (e) {
      print('❌ Error extracting features: $e');
      return null;
    }
  }

  /// Compare two face feature vectors
  double compareFaceFeatures(List<double> features1, List<double> features2) {
    if (features1.length != features2.length) {
      print('⚠️ Feature vectors have different lengths');
      return 0.0;
    }
    double distance = 0.0;
    for (int i = 0; i < features1.length; i++) {
      final diff = features1[i] - features2[i];
      distance += diff * diff;
    }
    distance = distance / features1.length;
    final similarity = (1.0 / (1.0 + distance)) * 100;
    print('📊 Similarity: ${similarity.toStringAsFixed(2)}%');
    return similarity;
  }

  /// Store face verification — NO IMAGE, only features!
  Future<bool> storeFaceVerification({
    required String bookingId,
    required String userId,
    required String faceImageBase64, // Ignored (kept for API compatibility)
    required List<double> faceFeatures,
    required String verificationType,
  }) async {
    try {
      print('💾 Storing face verification (features only, no image)...');
      print('📊 Features count: ${faceFeatures.length}');
      
      final verificationDoc = await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'userId': userId,
        'faceFeatures': faceFeatures,
        'verificationType': verificationType,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': true,
      });
      
      await _firestore.collection('bookings').doc(bookingId).update({
        'faceVerified': true,
        'faceVerificationId': verificationDoc.id,
        'faceFeatures': faceFeatures,
        'faceVerificationDate': FieldValue.serverTimestamp(),
      });
      
      print('✅ Face features stored successfully (no image)');
      return true;
    } catch (e) {
      print('❌ ERROR storing face verification: $e');
      return false;
    }
  }

  /// Get stored face features
  Future<Map<String, dynamic>?> getStoredFaceData(String bookingId) async {
    try {
      print('🔍 Getting stored face features for booking: $bookingId');
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data();
        final features = data?['faceFeatures'];
        if (features is List) {
          return {
            'features': features.map((e) => (e as num).toDouble()).toList(),
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting stored face data: $e');
      return null;
    }
  }

  /// Register face — NO IMAGE, only features
  Future<Map<String, dynamic>> registerFace({
    required File imageFile,
    required String userId,
    required String bookingId,
  }) async {
    try {
      print('📸 Starting face registration (features only)...');
      
      final faces = await detectFaces(imageFile);
      if (faces.isEmpty) {
        return {
          'success': false,
          'message': 'No face detected. Please ensure your face is clearly visible.',
        };
      }
      if (faces.length > 1) {
        return {
          'success': false,
          'message': 'Multiple faces detected. Please ensure only one person is in the frame.',
        };
      }

      final features = await extractFaceFeatures(imageFile, faces.first);
      if (features == null || features.isEmpty) {
        return {
          'success': false,
          'message': 'Failed to analyze face. Use good lighting, face front camera, and remove sunglasses/hats.',
        };
      }

      final success = await storeFaceVerification(
        bookingId: bookingId,
        userId: userId,
        faceImageBase64: '', // unused
        faceFeatures: features,
        verificationType: 'booking',
      );

      if (success) {
        return {
          'success': true,
          'message': 'Face registered successfully',
          'imageBase64': null, // explicitly null
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to save face data. Please try again.',
        };
      }
    } catch (e) {
      print('❌ Error in face registration: $e');
      return {
        'success': false,
        'message': 'Registration error: ${e.toString()}',
      };
    }
  }

  /// Verify for pickup
  Future<Map<String, dynamic>> verifyFaceForPickup({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    final storedData = await getStoredFaceData(bookingId);
    if (storedData == null) {
      return {'success': false, 'message': 'No registered face found for this booking'};
    }

    final faces = await detectFaces(scannedImageFile);
    if (faces.isEmpty) {
      return {'success': false, 'message': 'No face detected in scanned image'};
    }

    final scannedFeatures = await extractFaceFeatures(scannedImageFile, faces.first);
    if (scannedFeatures == null) {
      return {'success': false, 'message': 'Failed to extract features from scanned image'};
    }

    final similarity = compareFaceFeatures(storedData['features'], scannedFeatures);
    final isVerified = similarity >= 70.0;

    await _firestore.collection('face_verifications').add({
      'bookingId': bookingId,
      'verificationType': 'pickup',
      'similarity': similarity,
      'verified': isVerified,
      'verifiedBy': renterId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (isVerified) {
      await _firestore.collection('bookings').doc(bookingId).update({
        'pickupVerified': true,
        'pickupVerificationDate': FieldValue.serverTimestamp(),
      });
      return {
        'success': true,
        'message': 'Identity verified successfully',
        'similarity': similarity,
      };
    } else {
      return {
        'success': false,
        'message': 'Face does not match (${similarity.toStringAsFixed(1)}% similarity). Required: 70%',
        'similarity': similarity,
      };
    }
  }

  /// Verify for return
  Future<Map<String, dynamic>> verifyFaceForReturn({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    final storedData = await getStoredFaceData(bookingId);
    if (storedData == null) {
      return {'success': false, 'message': 'No registered face found for this booking'};
    }

    final faces = await detectFaces(scannedImageFile);
    if (faces.isEmpty) {
      return {'success': false, 'message': 'No face detected in scanned image'};
    }

    final scannedFeatures = await extractFaceFeatures(scannedImageFile, faces.first);
    if (scannedFeatures == null) {
      return {'success': false, 'message': 'Failed to extract features from scanned image'};
    }

    final similarity = compareFaceFeatures(storedData['features'], scannedFeatures);
    final isVerified = similarity >= 70.0;

    await _firestore.collection('face_verifications').add({
      'bookingId': bookingId,
      'verificationType': 'return',
      'similarity': similarity,
      'verified': isVerified,
      'verifiedBy': renterId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (isVerified) {
      await _firestore.collection('bookings').doc(bookingId).update({
        'returnVerified': true,
        'returnVerificationDate': FieldValue.serverTimestamp(),
      });
      return {
        'success': true,
        'message': 'Return verified successfully',
        'similarity': similarity,
      };
    } else {
      return {
        'success': false,
        'message': 'Face does not match (${similarity.toStringAsFixed(1)}% similarity). Required: 70%',
        'similarity': similarity,
      };
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}