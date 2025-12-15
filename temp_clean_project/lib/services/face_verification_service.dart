import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Unified Face Verification Service
/// 
/// Features:
/// - Uses face features (geometry + landmarks) for verification
/// - Optional Base64 image storage for UI display (disabled by default for FREE usage)
/// - Configurable similarity threshold
/// - Comprehensive error handling
class FaceVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late FaceDetector _faceDetector;
  
  /// Set to true to store low-res Base64 images (costs storage)
  /// Set to false for 100% FREE usage (features only)
  final bool storeDisplayImage;
  
  /// Similarity threshold for face matching (0-100)
  /// Higher = stricter matching (more secure, but might reject same person)
  /// Lower = looser matching (less secure, might accept different person)
  /// Recommended: 75-85 for good security
  final double similarityThreshold;
  
  FaceVerificationService({
    this.storeDisplayImage = false, // Default: FREE mode (no images)
    this.similarityThreshold = 75.0, // Increased from 70.0 for better security
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
    
    print('🔧 FaceVerificationService initialized:');
    print('   - Display images: ${storeDisplayImage ? "ENABLED ⚠️" : "DISABLED ✅ (FREE)"}');
    print('   - Similarity threshold: $similarityThreshold%');
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
      
      // 1. Normalized bounding box
      features.add(boundingBox.width / image.width);
      features.add(boundingBox.height / image.height);
      
      // 2. Facial landmarks (normalized)
      if (face.landmarks.isNotEmpty) {
        for (var landmark in face.landmarks.values) {
          if (landmark != null) {
            features.add(landmark.position.x / image.width);
            features.add(landmark.position.y / image.height);
          }
        }
      }
      
      // 3. Classification probabilities
      if (face.smilingProbability != null) features.add(face.smilingProbability!);
      if (face.leftEyeOpenProbability != null) features.add(face.leftEyeOpenProbability!);
      if (face.rightEyeOpenProbability != null) features.add(face.rightEyeOpenProbability!);
      
      // 4. Simple pixel statistics (RGB channel averages)
      final rgb = resizedFace.getBytes();
      if (rgb.isNotEmpty) {
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

  /// Convert image to compressed Base64 (only if storeDisplayImage = true)
  Future<String?> imageToBase64({
    required File imageFile,
    int quality = 25,
    int maxWidth = 300,
  }) async {
    if (!storeDisplayImage) {
      print('ℹ️ Image storage disabled - skipping Base64 conversion');
      return null;
    }

    try {
      print('🔄 Converting image to base64...');
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      print('📐 Original size: ${image.width}x${image.height}');

      img.Image resizedImage = image;
      if (image.width > maxWidth || image.height > maxWidth) {
        resizedImage = img.copyResize(
          image, 
          width: maxWidth,
          height: (image.height * maxWidth / image.width).round(),
        );
      }

      print('📐 Resized to: ${resizedImage.width}x${resizedImage.height}');

      int currentQuality = quality;
      int currentMaxWidth = resizedImage.width;
      var compressedBytes = img.encodeJpg(resizedImage, quality: currentQuality);
      var base64String = base64Encode(compressedBytes);
      var sizeKB = base64String.length / 1024;
      
      print('📊 Initial: ${sizeKB.toStringAsFixed(2)} KB (quality: $currentQuality)');
      
      // Reduce until under 400KB (safe Firestore limit)
      while (sizeKB > 400 && (currentQuality > 10 || currentMaxWidth > 100)) {
        if (currentQuality > 20) {
          currentQuality -= 10;
        } else {
          currentMaxWidth = (currentMaxWidth * 0.7).round();
          if (currentMaxWidth < 100) currentMaxWidth = 100;
          
          resizedImage = img.copyResize(
            image,
            width: currentMaxWidth,
            height: (image.height * currentMaxWidth / image.width).round(),
          );
          currentQuality = 15;
        }
        
        compressedBytes = img.encodeJpg(resizedImage, quality: currentQuality);
        base64String = base64Encode(compressedBytes);
        sizeKB = base64String.length / 1024;
      }
      
      if (sizeKB > 700) {
        print('❌ ERROR: Image still too large (${sizeKB.toStringAsFixed(2)} KB)');
        return null;
      }
      
      print('✅ Final: ${sizeKB.toStringAsFixed(2)} KB');
      return base64String;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      return null;
    }
  }

  /// Compare two face feature vectors
  double compareFaceFeatures(List<double> features1, List<double> features2) {
    if (features1.length != features2.length) {
      print('⚠️ Feature vectors have different lengths: ${features1.length} vs ${features2.length}');
      return 0.0;
    }

    // Calculate Euclidean distance
    double sumSquaredDiff = 0.0;
    for (int i = 0; i < features1.length; i++) {
      final diff = features1[i] - features2[i];
      sumSquaredDiff += diff * diff;
    }
    
    // Normalize by dividing by feature count
    final normalizedDistance = sumSquaredDiff / features1.length;
    
    // Convert to similarity percentage (0-100)
    // Using exponential decay for better discrimination
    final similarity = 100.0 * (1.0 / (1.0 + normalizedDistance * 100));
    
    print('📊 ═════════════════════════════════════════════');
    print('📊 Face Comparison Results:');
    print('📊 Feature count: ${features1.length}');
    print('📊 Sum of squared differences: ${sumSquaredDiff.toStringAsFixed(4)}');
    print('📊 Normalized distance: ${normalizedDistance.toStringAsFixed(6)}');
    print('📊 Similarity: ${similarity.toStringAsFixed(2)}%');
    print('📊 Threshold: $similarityThreshold%');
    print('📊 Result: ${similarity >= similarityThreshold ? "✅ MATCH" : "❌ NO MATCH"}');
    print('📊 ═════════════════════════════════════════════');
    
    return similarity;
  }

  /// Store face verification data
  Future<bool> storeFaceVerification({
    required String bookingId,
    required String userId,
    String? faceImageBase64,
    required List<double> faceFeatures,
    required String verificationType,
  }) async {
    try {
      print('💾 ─────────────────────────────────────');
      print('💾 storeFaceVerification called');
      print('💾 BookingId: $bookingId');
      print('💾 UserId: $userId');
      print('💾 Features: ${faceFeatures.length}');
      print('💾 Image: ${faceImageBase64 != null ? "YES (${(faceImageBase64.length / 1024).toStringAsFixed(1)} KB)" : "NO"}');
      print('💾 ─────────────────────────────────────');
      
      // Step 1: Create verification log
      print('📝 Creating verification log...');
      final verificationDoc = await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'userId': userId,
        'verificationType': verificationType,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': true,
      });
      print('✅ Verification log created: ${verificationDoc.id}');
      
      // Step 2: Prepare data for booking document
      print('📦 Preparing booking data...');
      final updateData = <String, dynamic>{
        'faceVerified': true,
        'faceVerificationId': verificationDoc.id,
        'faceFeatures': faceFeatures,
        'faceVerificationDate': FieldValue.serverTimestamp(),
      };
      
      // Only add image if we have one
      if (faceImageBase64 != null) {
        updateData['registeredImageBase64'] = faceImageBase64;
        print('   + Adding Base64 image');
      } else {
        print('   + No Base64 image (FREE mode)');
      }
      
      // Step 3: Save to booking document
      print('💾 Saving to bookings/$bookingId...');
      await _firestore.collection('bookings').doc(bookingId).set(
        updateData,
        SetOptions(merge: true),
      );
      print('✅✅ Booking document saved successfully! ✅✅');
      
      // Step 4: Verify it was saved
      print('🔍 Verifying saved data...');
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data();
        print('✅ Document exists!');
        print('   - faceVerified: ${data?['faceVerified']}');
        print('   - faceFeatures count: ${(data?['faceFeatures'] as List?)?.length ?? 0}');
        print('   - faceVerificationId: ${data?['faceVerificationId']}');
      } else {
        print('⚠️ WARNING: Document does not exist after save!');
        return false;
      }
      
      print('✅ Face verification stored successfully');
      return true;
    } catch (e, stackTrace) {
      print('❌❌❌ ERROR storing face verification ❌❌❌');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      
      if (e.toString().contains('maximum size') || e.toString().contains('too large')) {
        throw Exception('Image too large for Firestore');
      }
      return false;
    }
  }

  /// Get stored face data
  Future<Map<String, dynamic>?> getStoredFaceData(String bookingId) async {
    try {
      print('🔍 ═══════════════════════════════════════');
      print('🔍 Getting stored face data');
      print('🔍 BookingId: $bookingId');
      print('🔍 ═══════════════════════════════════════');
      
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      print('📄 Document exists: ${doc.exists}');
      
      if (doc.exists) {
        final data = doc.data();
        print('📊 Document data keys: ${data?.keys.toList()}');
        
        final features = data?['faceFeatures'];
        final imageBase64 = data?['registeredImageBase64'];
        
        print('🔢 faceFeatures type: ${features?.runtimeType}');
        print('🔢 faceFeatures value: $features');
        
        if (features is List) {
          print('✅ Features is a List with ${features.length} items');
          
          // Convert to List<double>
          try {
            final featuresList = features.map((e) => (e as num).toDouble()).toList();
            print('✅ Successfully converted to List<double>');
            print('   First 5 values: ${featuresList.take(5).toList()}');
            
            return {
              'features': featuresList,
              'imageBase64': imageBase64,
            };
          } catch (e) {
            print('❌ Error converting features: $e');
            return null;
          }
        } else {
          print('❌ faceFeatures is not a List or is null');
          return null;
        }
      } 
      
      print('⚠️ Booking document not found');
      return null;
    } catch (e, stackTrace) {
      print('❌❌❌ ERROR in getStoredFaceData ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
      print('📸 ═══════════════════════════════════════');
      print('📸 Starting face registration...');
      print('📸 BookingId: $bookingId');
      print('📸 UserId: $userId');
      print('📸 ═══════════════════════════════════════');
      
      // 1. Detect faces
      print('👤 Step 1: Detecting faces...');
      final faces = await detectFaces(imageFile);
      
      if (faces.isEmpty) {
        print('❌ No faces detected');
        return {
          'success': false,
          'message': 'No face detected. Please ensure your face is clearly visible.',
        };
      }
      
      if (faces.length > 1) {
        print('❌ Multiple faces detected: ${faces.length}');
        return {
          'success': false,
          'message': 'Multiple faces detected. Please ensure only one person is in the frame.',
        };
      }

      print('✅ Step 1: Single face detected');

      // 2. Extract features
      print('🔍 Step 2: Extracting features...');
      final features = await extractFaceFeatures(imageFile, faces.first);
      
      if (features == null || features.isEmpty) {
        print('❌ Feature extraction failed');
        return {
          'success': false,
          'message': 'Failed to analyze face. Use good lighting, face camera directly, and remove sunglasses/hats.',
        };
      }

      print('✅ Step 2: Features extracted - ${features.length} values');
      print('   First 5 features: ${features.take(5).toList()}');

      // 3. Optional: Convert to Base64 (only if enabled)
      String? imageBase64;
      if (storeDisplayImage) {
        print('🖼️ Step 3: Converting image to Base64...');
        imageBase64 = await imageToBase64(imageFile: imageFile);
        if (imageBase64 == null) {
          print('❌ Image conversion failed');
          return {
            'success': false,
            'message': 'Failed to compress image. Please try with better lighting or simpler background.',
          };
        }
        print('✅ Step 3: Image converted - ${(imageBase64.length / 1024).toStringAsFixed(1)} KB');
      } else {
        print('⏭️ Step 3: Skipped (storeDisplayImage = false)');
      }

      // 4. Store in Firestore
      print('💾 Step 4: Storing in Firestore...');
      final success = await storeFaceVerification(
        bookingId: bookingId,
        userId: userId,
        faceImageBase64: imageBase64,
        faceFeatures: features,
        verificationType: 'booking',
      );

      if (success) {
        print('✅✅✅ Registration completed successfully! ✅✅✅');
        return {
          'success': true,
          'message': 'Face registered successfully',
          'imageBase64': imageBase64,
        };
      } else {
        print('❌ Storage returned false');
        return {
          'success': false,
          'message': 'Failed to save face data. Please try again.',
        };
      }
    } catch (e, stackTrace) {
      print('❌❌❌ EXCEPTION in registerFace ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
    return await _runVerification(
      bookingId: bookingId,
      scannedImageFile: scannedImageFile,
      renterId: renterId,
      verificationType: 'pickup',
    );
  }

  /// Verify face for return
  Future<Map<String, dynamic>> verifyFaceForReturn({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
  }) async {
    return await _runVerification(
      bookingId: bookingId,
      scannedImageFile: scannedImageFile,
      renterId: renterId,
      verificationType: 'return',
    );
  }

  /// Shared verification logic
  Future<Map<String, dynamic>> _runVerification({
    required String bookingId,
    required File scannedImageFile,
    required String renterId,
    required String verificationType,
  }) async {
    try {
      print('🔐 Starting $verificationType verification...');
      
      // 1. Get stored face data
      final storedData = await getStoredFaceData(bookingId);
      
      if (storedData == null || storedData['features'] == null) {
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
          'message': 'No face detected in scanned image',
        };
      }

      if (faces.length > 1) {
        return {
          'success': false,
          'message': 'Multiple faces detected. Please ensure only one person is in the frame.',
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

      // 5. Log the verification attempt
      await _firestore.collection('face_verifications').add({
        'bookingId': bookingId,
        'verificationType': verificationType,
        'similarity': similarity,
        'verified': similarity >= similarityThreshold,
        'verifiedBy': renterId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Check threshold
      final bool isVerified = similarity >= similarityThreshold;

      if (isVerified) {
        // Update booking with verification status
        await _firestore.collection('bookings').doc(bookingId).update({
          '${verificationType}Verified': true,
          '${verificationType}VerificationDate': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Identity verified successfully',
          'similarity': similarity,
        };
      } else {
        return {
          'success': false,
          'message': 'Face does not match (${similarity.toStringAsFixed(1)}% similarity). Required: ${similarityThreshold.toStringAsFixed(0)}%',
          'similarity': similarity,
        };
      }
    } catch (e) {
      print('❌ Error in $verificationType verification: $e');
      return {
        'success': false,
        'message': 'Verification error: ${e.toString()}',
      };
    }
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
  }
}