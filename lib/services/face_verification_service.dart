import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Face Verification Service - NO FIREBASE STORAGE NEEDED!
/// Uses Base64 to store images directly in Firestore
/// 100% FREE - No storage costs!
class FaceVerificationServiceBase64 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late FaceDetector _faceDetector;
  
  FaceVerificationServiceBase64() {
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

  /// Convert image file to compressed base64 string
  /// Compresses image to reduce Firestore storage
  Future<String?> imageToBase64({
    required File imageFile,
    int quality = 70, // Compression quality (0-100)
    int maxWidth = 800, // Max width to reduce size
  }) async {
    try {
      print('🔄 Converting image to base64...');
      
      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      // Resize image to reduce size (important for Firestore limits!)
      img.Image resizedImage;
      if (image.width > maxWidth) {
        resizedImage = img.copyResize(image, width: maxWidth);
      } else {
        resizedImage = image;
      }

      // Compress to JPEG
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      // Convert to base64
      final base64String = base64Encode(compressedBytes);
      
      final sizeKB = base64String.length / 1024;
      print('✅ Image converted to base64 (${sizeKB.toStringAsFixed(2)} KB)');
      
      // Firestore document size limit is 1MB
      if (sizeKB > 900) {
        print('⚠️ Warning: Image size is large (${sizeKB.toStringAsFixed(2)} KB). Consider reducing quality.');
      }
      
      return base64String;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      return null;
    }
  }

  /// Convert base64 string back to image file
  Future<File?> base64ToImage(String base64String, String fileName) async {
    try {
      final bytes = base64Decode(base64String);
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('❌ Error converting base64 to image: $e');
      return null;
    }
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
      
      // Crop face region
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

      // Resize to standard size
      final resizedFace = img.copyResize(croppedFace, width: 128, height: 128);
      
      // Extract features
      final features = <double>[];
      
      // Bounding box dimensions (normalized)
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
      
      // Classification scores
      if (face.smilingProbability != null) {
        features.add(face.smilingProbability!);
      }
      if (face.leftEyeOpenProbability != null) {
        features.add(face.leftEyeOpenProbability!);
      }
      if (face.rightEyeOpenProbability != null) {
        features.add(face.rightEyeOpenProbability!);
      }
      
      // Simplified pixel data
      final pixelData = resizedFace.getBytes();
      for (int i = 0; i < pixelData.length && i < 1000; i += 100) {
        features.add(pixelData[i] / 255.0);
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

    // Calculate Euclidean distance
    double distance = 0.0;
    for (int i = 0; i < features1.length; i++) {
      final diff = features1[i] - features2[i];
      distance += diff * diff;
    }
    distance = distance / features1.length;
    
    // Convert to similarity percentage
    final similarity = (1.0 / (1.0 + distance)) * 100;
    
    print('📊 Similarity: ${similarity.toStringAsFixed(2)}%');
    return similarity;
  }

  /// Store face verification with base64 image (NO STORAGE NEEDED!)
  Future<bool> storeFaceVerification({
    required String bookingId,
    required String userId,
    required String faceImageBase64,
    required List<double> faceFeatures,
    required String verificationType,
  }) async {
    try {
      print('💾 Storing face verification data in Firestore...');
      
      // Store in face_verifications collection
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'userId': userId,
        'faceImageBase64': faceImageBase64, // 👈 Base64 instead of URL!
        'faceFeatures': faceFeatures,
        'verificationType': verificationType,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': true,
      });
      
      // Update booking document
      await _firestore.collection('bookings').doc(bookingId).update({
        'faceVerified': true,
        'faceImageBase64': faceImageBase64, // 👈 Base64 instead of URL!
        'faceFeatures': faceFeatures,
        'faceVerificationDate': FieldValue.serverTimestamp(),
      });
      
      print('✅ Face verification stored successfully (no storage costs!)');
      return true;
    } catch (e) {
      print('❌ Error storing face verification: $e');
      
      // Check if error is due to document size
      if (e.toString().contains('maximum size')) {
        print('⚠️ Image too large! Try reducing quality or maxWidth');
      }
      
      return false;
    }
  }

  /// Get stored face features and base64 image
  Future<Map<String, dynamic>?> getStoredFaceData(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final features = data?['faceFeatures'];
        final imageBase64 = data?['faceImageBase64'];
        
        if (features is List && imageBase64 is String) {
          return {
            'features': features.map((e) => (e as num).toDouble()).toList(),
            'imageBase64': imageBase64,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting stored face data: $e');
      return null;
    }
  }

  /// Register face for booking
  Future<Map<String, dynamic>> registerFace({
    required File imageFile,
    required String userId,
    required String bookingId,
  }) async {
    try {
      print('📸 Starting face registration...');
      
      // 1. Detect faces
      final faces = await detectFaces(imageFile);
      
      if (faces.isEmpty) {
        return {
          'success': false,
          'message': 'No face detected in the image',
        };
      }
      
      if (faces.length > 1) {
        return {
          'success': false,
          'message': 'Multiple faces detected. Please ensure only one person is in the frame',
        };
      }

      final face = faces.first;
      
      // 2. Extract features
      final features = await extractFaceFeatures(imageFile, face);
      
      if (features == null || features.isEmpty) {
        return {
          'success': false,
          'message': 'Failed to extract face features',
        };
      }

      // 3. Convert image to base64
      final imageBase64 = await imageToBase64(
        imageFile: imageFile,
        quality: 70, // Adjust for size vs quality
        maxWidth: 800,
      );

      if (imageBase64 == null) {
        return {
          'success': false,
          'message': 'Failed to process face image',
        };
      }

      // 4. Store in Firestore (NO STORAGE COSTS!)
      final success = await storeFaceVerification(
        bookingId: bookingId,
        userId: userId,
        faceImageBase64: imageBase64,
        faceFeatures: features,
        verificationType: 'booking',
      );

      if (success) {
        return {
          'success': true,
          'message': 'Face registered successfully',
          'imageBase64': imageBase64,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to store face verification',
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

  /// Verify face for pickup
  Future<Map<String, dynamic>> verifyFaceForPickup({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    try {
      print('📸 Starting pickup face verification...');
      
      // 1. Get stored face data
      final storedData = await getStoredFaceData(bookingId);
      
      if (storedData == null) {
        return {
          'success': false,
          'message': 'No registered face found for this booking',
        };
      }

      final storedFeatures = storedData['features'] as List<double>;

      // 2. Detect face in scanned image
      final faces = await detectFaces(scannedImageFile);
      
      if (faces.isEmpty) {
        return {
          'success': false,
          'message': 'No face detected in the scanned image',
        };
      }

      // 3. Extract features from scanned image
      final scannedFeatures = await extractFaceFeatures(scannedImageFile, faces.first);
      
      if (scannedFeatures == null || scannedFeatures.isEmpty) {
        return {
          'success': false,
          'message': 'Failed to extract features from scanned image',
        };
      }

      // 4. Compare faces
      final similarity = compareFaceFeatures(storedFeatures, scannedFeatures);

      // 5. Convert scanned image to base64
      final scannedImageBase64 = await imageToBase64(
        imageFile: scannedImageFile,
        quality: 60, // Lower quality for verification images
        maxWidth: 600,
      );

      // 6. Store verification result
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'verificationType': 'pickup',
        'scannedFaceBase64': scannedImageBase64,
        'similarity': similarity,
        'verified': similarity >= 70.0,
        'verifiedBy': renterId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 7. Check threshold
      const double threshold = 70.0;
      final bool isVerified = similarity >= threshold;

      if (isVerified) {
        await _firestore.collection('bookings').doc(bookingId).update({
          'pickupVerified': true,
          'pickupVerificationDate': FieldValue.serverTimestamp(),
          'pickupFaceBase64': scannedImageBase64,
        });

        return {
          'success': true,
          'message': 'Identity verified successfully',
          'similarity': similarity,
        };
      } else {
        return {
          'success': false,
          'message': 'Face does not match (${similarity.toStringAsFixed(1)}% similarity). Required: ${threshold}%',
          'similarity': similarity,
        };
      }
    } catch (e) {
      print('❌ Error in pickup verification: $e');
      return {
        'success': false,
        'message': 'Verification error: ${e.toString()}',
      };
    }
  }

  /// Verify face for return
  Future<Map<String, dynamic>> verifyFaceForReturn({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    try {
      print('📸 Starting return face verification...');
      
      // 1. Get stored face data
      final storedData = await getStoredFaceData(bookingId);
      
      if (storedData == null) {
        return {
          'success': false,
          'message': 'No registered face found for this booking',
        };
      }

      final storedFeatures = storedData['features'] as List<double>;

      // 2. Detect face in scanned image
      final faces = await detectFaces(scannedImageFile);
      
      if (faces.isEmpty) {
        return {
          'success': false,
          'message': 'No face detected in the scanned image',
        };
      }

      // 3. Extract features
      final scannedFeatures = await extractFaceFeatures(scannedImageFile, faces.first);
      
      if (scannedFeatures == null || scannedFeatures.isEmpty) {
        return {
          'success': false,
          'message': 'Failed to extract features from scanned image',
        };
      }

      // 4. Compare faces
      final similarity = compareFaceFeatures(storedFeatures, scannedFeatures);

      // 5. Convert to base64
      final scannedImageBase64 = await imageToBase64(
        imageFile: scannedImageFile,
        quality: 60,
        maxWidth: 600,
      );

      // 6. Store verification result
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'verificationType': 'return',
        'scannedFaceBase64': scannedImageBase64,
        'similarity': similarity,
        'verified': similarity >= 70.0,
        'verifiedBy': renterId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 7. Check threshold
      const double threshold = 70.0;
      final bool isVerified = similarity >= threshold;

      if (isVerified) {
        await _firestore.collection('bookings').doc(bookingId).update({
          'returnVerified': true,
          'returnVerificationDate': FieldValue.serverTimestamp(),
          'returnFaceBase64': scannedImageBase64,
        });

        return {
          'success': true,
          'message': 'Return verified successfully',
          'similarity': similarity,
        };
      } else {
        return {
          'success': false,
          'message': 'Face does not match (${similarity.toStringAsFixed(1)}% similarity). Required: ${threshold}%',
          'similarity': similarity,
        };
      }
    } catch (e) {
      print('❌ Error in return verification: $e');
      return {
        'success': false,
        'message': 'Verification error: ${e.toString()}',
      };
    }
  }

  /// Get verification history
  Future<List<Map<String, dynamic>>> getVerificationHistory(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('face_verifications')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting verification history: $e');
      return [];
    }
  }

  /// Helper: Display base64 image in Flutter widget
  /// Usage: Image.memory(base64Decode(base64String))
  Uint8List decodeBase64Image(String base64String) {
    return base64Decode(base64String);
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
  }
}