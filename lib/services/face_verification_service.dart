// lib/services/face_verification_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late FaceDetector _faceDetector;
  
  final bool storeDisplayImage;
  final double similarityThreshold;

  // ✅ In-memory temp storage for booking flow
  final Map<String, Map<String, dynamic>> _tempFaceData = {};

  FaceVerificationService({
    this.storeDisplayImage = false,
    this.similarityThreshold = 75.0,
  }) {
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
    
    print('🔧 FaceVerificationService initialized');
  }

  // ✅ TEMP STORAGE METHODS
  void storeTempFaceData(String key, List<double> features, {String? imageBase64}) {
    _tempFaceData[key] = {'features': features, 'imageBase64': imageBase64};
    print('💾 Temp face data stored for: $key');
  }

  Map<String, dynamic>? getTempFaceData(String key) {
    final data = _tempFaceData[key];
    print('🔍 Retrieved temp data for $key: ${data != null}');
    return data;
  }

  void clearTempFaceData(String key) {
    _tempFaceData.remove(key);
    print('🧹 Cleared temp data for: $key');
  }

  // ─── Core ML Methods ────────────────────────────────────────

  Future<List<Face>> detectFaces(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('❌ Face detection error: $e');
      return [];
    }
  }

  Future<List<double>?> extractFaceFeatures(File imageFile, Face face) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final bb = face.boundingBox;
      final pad = 20;
      final x = (bb.left - pad).clamp(0, image.width);
      final y = (bb.top - pad).clamp(0, image.height);
      final w = (bb.width + pad * 2).clamp(0, image.width - x);
      final h = (bb.height + pad * 2).clamp(0, image.height - y);
      
      final cropped = img.copyCrop(image, x: x.toInt(), y: y.toInt(), width: w.toInt(), height: h.toInt());
      final resized = img.copyResize(cropped, width: 128, height: 128);
      final features = <double>[];
      
      features.add(bb.width / image.width);
      features.add(bb.height / image.height);
      
      if (face.landmarks.isNotEmpty) {
        for (var lm in face.landmarks.values) {
          if (lm != null) {
            features.add(lm.position.x / image.width);
            features.add(lm.position.y / image.height);
          }
        }
      }
      
      if (face.smilingProbability != null) features.add(face.smilingProbability!);
      if (face.leftEyeOpenProbability != null) features.add(face.leftEyeOpenProbability!);
      if (face.rightEyeOpenProbability != null) features.add(face.rightEyeOpenProbability!);
      
      final rgb = resized.getBytes();
      if (rgb.isNotEmpty) {
        int r = 0, g = 0, b = 0;
        for (int i = 0; i < rgb.length; i += 4) {
          r += rgb[i]; g += rgb[i + 1]; b += rgb[i + 2];
        }
        final n = (rgb.length / 4).floor();
        if (n > 0) {
          features.add(r / n / 255.0);
          features.add(g / n / 255.0);
          features.add(b / n / 255.0);
        }
      }

      return features;
    } catch (e) {
      print('❌ Feature extraction error: $e');
      return null;
    }
  }

  Future<String?> imageToBase64({required File imageFile, int quality = 25, int maxWidth = 300}) async {
    if (!storeDisplayImage) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image resized = image;
      if (image.width > maxWidth) {
        resized = img.copyResize(image, width: maxWidth);
      }

      // Compress until under 400KB
      int q = quality;
      var jpg = img.encodeJpg(resized, quality: q);
      var b64 = base64Encode(jpg);
      while (b64.length > 400 * 1024 && q > 15) {
        q -= 5;
        jpg = img.encodeJpg(resized, quality: q);
        b64 = base64Encode(jpg);
      }

      return b64.length > 700 * 1024 ? null : b64;
    } catch (e) {
      print('❌ Base64 conversion error: $e');
      return null;
    }
  }

  double compareFaceFeatures(List<double> f1, List<double> f2) {
    if (f1.length != f2.length) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < f1.length; i++) {
      final diff = f1[i] - f2[i];
      sum += diff * diff;
    }
    final dist = sum / f1.length;
    return 100.0 / (1.0 + dist * 100);
  }

  // ─── Firestore Storage (for REAL bookings only) ─────────────

  Future<bool> storeFaceVerification({
    required String bookingId,
    required String userId,
    String? faceImageBase64,
    required List<double> faceFeatures,
    required String verificationType,
  }) async {
    try {
      final verDoc = await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'userId': userId,
        'verificationType': verificationType,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': true,
      });

      final data = <String, dynamic>{
        'faceVerified': true,
        'faceVerificationId': verDoc.id,
        'faceFeatures': faceFeatures,
        'faceVerificationDate': FieldValue.serverTimestamp(),
      };
      if (faceImageBase64 != null) {
        data['registeredImageBase64'] = faceImageBase64;
      }

      await _firestore.collection('bookings').doc(bookingId).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('❌ storeFaceVerification error: $e');
      return false;
    }
  }

  // ✅ Get from REAL booking (used in pickup/return)
  Future<Map<String, dynamic>?> getStoredFaceData(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) return null;
      
      final data = doc.data();
      final features = data?['faceFeatures'];
      if (features is List) {
        final list = features.map((e) => (e as num).toDouble()).toList();
        return {
          'features': list,
          'imageBase64': data?['registeredImageBase64'],
        };
      }
      return null;
    } catch (e) {
      print('❌ getStoredFaceData error: $e');
      return null;
    }
  }

  // ─── Verification Flows ─────────────────────────────────────

  Future<Map<String, dynamic>> verifyFaceForPickup({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    return _runVerification(
      bookingId: bookingId,
      scannedImageFile: scannedImageFile,
      renterId: renterId,
      verificationType: 'pickup',
    );
  }

  Future<Map<String, dynamic>> verifyFaceForReturn({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    return _runVerification(
      bookingId: bookingId,
      scannedImageFile: scannedImageFile,
      renterId: renterId,
      verificationType: 'return',
    );
  }

  Future<Map<String, dynamic>> _runVerification({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
    required String verificationType,
  }) async {
    try {
      print('🔐 Starting $verificationType verification for: $bookingId');
      
      final storedData = await getStoredFaceData(bookingId);
      if (storedData == null) {
        return {
          'success': false,
          'message': 'No face registered for this booking. Face registration is required during booking.',
        };
      }

      final features = storedData['features'] as List<double>?;
      if (features == null || features.isEmpty) {
        return {
          'success': false,
          'message': 'Face registration is incomplete. Please contact support.',
        };
      }

      final faces = await detectFaces(scannedImageFile);
      if (faces.isEmpty) {
        return {'success': false, 'message': 'No face detected in camera image.'};
      }
      if (faces.length > 1) {
        return {'success': false, 'message': 'Multiple faces detected. Show only one face.'};
      }

      final scannedFeatures = await extractFaceFeatures(scannedImageFile, faces.first);
      if (scannedFeatures == null || scannedFeatures.isEmpty) {
        return {'success': false, 'message': 'Failed to analyze scanned face.'};
      }

      final similarity = compareFaceFeatures(features, scannedFeatures);
      final isVerified = similarity >= similarityThreshold;

      // Log attempt
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'verificationType': verificationType,
        'similarity': similarity,
        'verified': isVerified,
        'verifiedBy': renterId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isVerified) {
        await _firestore.collection('bookings').doc(bookingId).update({
          '${verificationType}Verified': true,
          '${verificationType}VerificationDate': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': isVerified,
        'message': isVerified
            ? 'Identity verified successfully!'
            : 'Face does not match (${similarity.toStringAsFixed(1)}% similarity). Required: ${similarityThreshold.toStringAsFixed(0)}%',
        'similarity': similarity,
      };

    } catch (e, st) {
      print('❌ Verification error: $e\n$st');
      return {'success': false, 'message': 'Verification system error: ${e.toString()}'};
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}