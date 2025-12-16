import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:profile_managemenr/constants/app_colors.dart';
//import 'package:profile_managemenr/services/face_verification_service.dart';

// Import the separate components
import 'camera_preview_widget.dart';
import 'web_camera_widget.dart';
import 'face_capture_helper.dart';
import 'dialog_helper.dart';

class FaceCaptureScreen extends StatefulWidget {
  final String bookingId;
  final String userId;
  final String verificationType; // 'booking', 'pickup', 'return'
  
  const FaceCaptureScreen({
    super.key,
    required this.bookingId,
    required this.userId,
    required this.verificationType,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  
  late final FaceCaptureHelper _captureHelper;
  late final DialogHelper _dialogHelper;

  @override
  void initState() {
    super.initState();
    _captureHelper = FaceCaptureHelper(
      bookingId: widget.bookingId,
      userId: widget.userId,
      verificationType: widget.verificationType,
    );
    _dialogHelper = DialogHelper(context: context);
    
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        _showError('No camera found on this device');
        return;
      }

      final selectedCamera = _captureHelper.selectCamera(cameras, widget.verificationType);

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      _showError('Failed to initialize camera: ${e.toString()}');
    }
  }

  Future<void> _handleCapture() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final imageFile = kIsWeb
          ? await _captureHelper.captureFromWeb(widget.verificationType)
          : await _captureHelper.captureFromMobile(_cameraController);

      if (imageFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processImage(imageFile);
    } catch (e) {
      _showError('Error capturing image: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage(XFile imageFile) async {
    try {
      _dialogHelper.showLoading('Detecting face...');

      final faces = await _captureHelper.detectFaces(File(imageFile.path));
      
      if (!mounted) return;
      Navigator.pop(context);

      if (faces.isEmpty) {
        _showError('No face detected. Please try again.');
        setState(() => _isProcessing = false);
        return;
      }

      if (faces.length > 1) {
        _showError('Multiple faces detected. Please ensure only one person is in the frame.');
        setState(() => _isProcessing = false);
        return;
      }

      _showPreview(imageFile);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Error processing image: ${e.toString()}');
      }
      setState(() => _isProcessing = false);
    }
  }

  void _showPreview(XFile imageFile) {
    _dialogHelper.showImagePreview(
      imageFile: imageFile,
      onRetake: () {
        Navigator.pop(context);
        setState(() => _isProcessing = false);
      },
      onConfirm: () async {
        Navigator.pop(context);
        await _verifyFace(File(imageFile.path));
      },
    );
  }

  Future<void> _verifyFace(File imageFile) async {
    _dialogHelper.showLoading('Processing...');

    try {
      final result = await _captureHelper.processFaceVerification(imageFile);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _dialogHelper.showSuccess(
          message: result['message'],
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context, {
              'success': true,
              'imageBase64': result['imageBase64'],
            });
          },
        );
      } else {
        _showError(result['message'] ?? 'Verification failed');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Verification error: ${e.toString()}');
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebCameraWidget(
        verificationType: widget.verificationType,
        isProcessing: _isProcessing,
        onCapture: _handleCapture,
      );
    }

    return CameraPreviewWidget(
      verificationType: widget.verificationType,
      cameraController: _cameraController,
      isCameraInitialized: _isCameraInitialized,
      isProcessing: _isProcessing,
      onCapture: _handleCapture,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _captureHelper.dispose();
    super.dispose();
  }
}