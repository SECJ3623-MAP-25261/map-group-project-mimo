import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:profile_managemenr/services/face_verification_service.dart';

class FaceCaptureHelper {
  final String bookingId;
  final String userId;
  final String verificationType;
  
  final ImagePicker _picker = ImagePicker();
  final FaceVerificationService _faceService = FaceVerificationService(
    storeDisplayImage: true,
    similarityThreshold: 75.0,
  );

  FaceCaptureHelper({
    required this.bookingId,
    required this.userId,
    required this.verificationType,
  });

  CameraDescription selectCamera(
    List<CameraDescription> cameras,
    String verificationType,
  ) {
    if (verificationType == 'booking') {
      return cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    } else {
      return cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    }
  }

  Future<XFile?> captureFromWeb(String verificationType) async {
    final cameraDevice = verificationType == 'booking'
        ? CameraDevice.front
        : CameraDevice.rear;

    return await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: cameraDevice,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  Future<XFile?> captureFromMobile(CameraController? controller) async {
    if (controller == null || !controller.value.isInitialized) {
      throw Exception('Camera not ready');
    }
    return await controller.takePicture();
  }

  Future<List<dynamic>> detectFaces(File imageFile) async {
    return await _faceService.detectFaces(imageFile);
  }

  Future<Map<String, dynamic>> processFaceVerification(File imageFile) async {
    print('🔐 Starting verification type: $verificationType');
    print('🔐 BookingId: $bookingId');
    print('🔐 UserId: $userId');

    Map<String, dynamic> result;

    if (verificationType == 'booking') {
      result = await _faceService.registerFace(
        imageFile: imageFile,
        userId: userId,
        bookingId: bookingId,
      );
    } else if (verificationType == 'pickup') {
      result = await _faceService.verifyFaceForPickup(
        bookingId: bookingId,
        scannedImageFile: imageFile,
        renterId: userId,
      );
    } else if (verificationType == 'return') {
      result = await _faceService.verifyFaceForReturn(
        bookingId: bookingId,
        scannedImageFile: imageFile,
        renterId: userId,
      );
    } else {
      throw Exception('Invalid verification type: $verificationType');
    }

    print('🔐 Verification result: $result');
    return result;
  }

  String getInstructionText(bool isWeb) {
    if (isWeb) {
      return 'Click the button below to access your camera\nand capture your face';
    }

    switch (verificationType) {
      case 'booking':
        return 'Position your face in the frame\nThis will be used for future verification';
      case 'pickup':
        return 'Scan rentee\'s face to verify identity\nBefore handing over the item';
      case 'return':
        return 'Scan rentee\'s face to verify identity\nBefore accepting the return';
      default:
        return 'Position face in the frame';
    }
  }

  void dispose() {
    _faceService.dispose();
  }
}