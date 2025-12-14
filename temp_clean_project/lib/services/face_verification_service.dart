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

  /// Convert image file to ULTRA compressed base64 string
  /// Aggressively compresses to stay under Firestore limits
  Future<String?> imageToBase64({
    required File imageFile,
    int quality = 70,
    int maxWidth = 800,
  }) async {
    try {
      print('🔄 Converting image to base64...');
      
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      print('📐 Original size: ${image.width}x${image.height}');

      // AGGRESSIVE RESIZE - start with smaller size
      img.Image resizedImage;
      if (image.width > maxWidth || image.height > maxWidth) {
        resizedImage = img.copyResize(
          image, 
          width: maxWidth,
          height: (image.height * maxWidth / image.width).round(),
        );
      } else {
        resizedImage = image;
      }

      print('📐 Resized to: ${resizedImage.width}x${resizedImage.height}');

      // Try compression with decreasing quality
      int currentQuality = quality;
      int currentMaxWidth = maxWidth;
      var compressedBytes = img.encodeJpg(resizedImage, quality: currentQuality);
      var base64String = base64Encode(compressedBytes);
      var sizeKB = base64String.length / 1024;
      
      print('📊 Initial: ${sizeKB.toStringAsFixed(2)} KB (quality: $currentQuality)');
      
      // Keep reducing until under 500KB (very safe margin)
      while (sizeKB > 500 && (currentQuality > 10 || currentMaxWidth > 150)) {
        if (currentQuality > 20) {
          // First, reduce quality
          currentQuality -= 10;
        } else {
          // Then, reduce size
          currentMaxWidth = (currentMaxWidth * 0.7).round(); // More aggressive
          if (currentMaxWidth < 150) currentMaxWidth = 150;
          
          resizedImage = img.copyResize(
            image,
            width: currentMaxWidth,
            height: (image.height * currentMaxWidth / image.width).round(),
          );
          currentQuality = 25; // Reset quality lower
        }
        
        print('⚙️ Trying: quality=$currentQuality, width=$currentMaxWidth');
        
        compressedBytes = img.encodeJpg(resizedImage, quality: currentQuality);
        base64String = base64Encode(compressedBytes);
        sizeKB = base64String.length / 1024;
        
        print('📊 Result: ${sizeKB.toStringAsFixed(2)} KB');
      }
      
      if (sizeKB > 800) {
        print('❌ ERROR: Image still too large (${sizeKB.toStringAsFixed(2)} KB)');
        print('❌ Cannot compress further without losing face data');
        return null;
      }
      
      print('✅ Final: ${sizeKB.toStringAsFixed(2)} KB (quality: $currentQuality, width: $currentMaxWidth)');
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

  /// Store face verification WITHOUT IMAGE (features only!)
  /// Images are too large for Firestore - we only need features for comparison
  Future<bool> storeFaceVerification({
    required String bookingId,
    required String userId,
    required String faceImageBase64,
    required List<double> faceFeatures,
    required String verificationType,
  }) async {
    try {
      print('💾 Storing face verification data (features only)...');
      print('📊 Features count: ${faceFeatures.length}');
      
      // 👇 SOLUTION: Don't store the image at all!
      // We only need features for face comparison
      final verificationDoc = await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'userId': userId,
        // 'faceImageBase64': faceImageBase64, // ❌ REMOVED - too large!
        'faceFeatures': faceFeatures, // ✅ This is enough!
        'verificationType': verificationType,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': true,
      });
      
      print('✅ Face features stored in collection: ${verificationDoc.id}');
      
      // Update booking with features only
      await _firestore.collection('bookings').doc(bookingId).update({
        'faceVerified': true,
        'faceVerificationId': verificationDoc.id,
        'faceFeatures': faceFeatures,
        'faceVerificationDate': FieldValue.serverTimestamp(),
      });
      
      print('✅ Booking updated with features (no image)');
      return true;
    } catch (e) {
      print('❌ ERROR storing face verification: $e');
      return false;
    }
  }

  /// Get stored face features (no image needed)
  Future<Map<String, dynamic>?> getStoredFaceData(String bookingId) async {
    try {
      print('🔍 Getting stored face features for booking: $bookingId');
      
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final features = data?['faceFeatures'];
        
        print('📊 Found features: ${features != null ? (features as List).length : 0}');
        
        if (features is List) {
          return {
            'features': features.map((e) => (e as num).toDouble()).toList(),
            'imageBase64': null, // No image stored
          };
        }
      } else {
        print('⚠️ Booking document not found');
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
      print('📊 Input: userId=$userId, bookingId=$bookingId');
      
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

      // 3. Convert image to base64 with ULTRA AGGRESSIVE compression
      print('🗜️ Starting ultra aggressive compression...');
      final imageBase64 = await imageToBase64(
        imageFile: imageFile,
        quality: 25, // Much lower!
        maxWidth: 300, // Much smaller!
      );

      if (imageBase64 == null) {
        return {
          'success': false,
          'message': 'Failed to compress image. Please try taking a clearer photo with better lighting.',
        };
      }

      print('✅ Image compressed successfully');

      // 4. Store in Firestore
      print('💾 Attempting to store in Firestore...');
      final success = await storeFaceVerification(
        bookingId: bookingId,
        userId: userId,
        faceImageBase64: imageBase64,
        faceFeatures: features,
        verificationType: 'booking',
      );

      if (success) {
        print('✅ Registration completed successfully');
        return {
          'success': true,
          'message': 'Face registered successfully',
          'imageBase64': imageBase64,
        };
      } else {
        return {
          'success': false,
          'message': 'Image too large for storage. Please try again in better lighting with a simpler background.',
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

      // 5. Don't store scanned images (features are enough)
      // Just log the verification attempt
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'verificationType': 'pickup',
        // 'scannedFaceBase64': scannedImageBase64, // ❌ Don't store
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
          // 'pickupFaceBase64': scannedImageBase64, // ❌ Don't store image
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

      // 5. Store verification result (no images)
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'verificationType': 'return',
        // No images stored - features only
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
          // No image stored
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
  Uint8List decodeBase64Image(String base64String) {
    return base64Decode(base64String);
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
  }
}