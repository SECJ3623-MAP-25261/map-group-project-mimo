import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/face_verification_service.dart'; // ✅ Unified service

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
  // Mobile camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  // Common
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  
  // ✅ Using unified service with FREE mode
  final FaceVerificationService _faceService = FaceVerificationService(
    storeDisplayImage: false, // FREE mode - no images stored
    similarityThreshold: 75.0, // 75% match required (more secure)
  );

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Only initialize camera on mobile
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No camera found on this device');
        return;
      }

      // Use front camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
      _showError('Failed to initialize camera: ${e.toString()}');
    }
  }

  // Web: Use image picker with camera
  Future<void> _captureFromWebCamera() async {
    if (_isProcessing) return;
    try {
      setState(() => _isProcessing = true);

      // Use ImagePicker for web - it will use the browser's camera API
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processImageAndDetectFace(pickedFile);

    } catch (e) {
      print('❌ Error capturing from web camera: $e');
      _showError('Error accessing camera: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  // Mobile: Capture from camera controller
  Future<void> _captureFromMobileCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      await _processImageAndDetectFace(imageFile);

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Error capturing image: ${e.toString()}');
      }
      setState(() => _isProcessing = false);
    }
  }

  // Unified method to process the captured XFile
  Future<void> _processImageAndDetectFace(XFile imageFile) async {
    try {
      _showLoadingDialog('Detecting face...');

      final capturedFile = File(imageFile.path); 
      
      final faces = await _faceService.detectFaces(capturedFile);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

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

      if (kIsWeb) {
        _showWebPreviewDialog(imageFile);
      } else {
        _showPreviewDialog(capturedFile);
      }

    } catch (e) {
      if (mounted) {
        if (Navigator.of(context).canPop()) Navigator.pop(context); 
        _showError('Error processing image: ${e.toString()}');
      }
      setState(() => _isProcessing = false);
    }
  }

  // Preview dialog for mobile (File)
  void _showPreviewDialog(File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Face'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Is this image clear and shows your face properly?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            _buildFreeInfoContainer(),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processFaceVerification(imageFile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Preview dialog for web (XFile)
  void _showWebPreviewDialog(XFile imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Face'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Uint8List>(
                future: imageFile.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      height: 300,
                      fit: BoxFit.cover,
                    );
                  }
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Is this image clear and shows your face properly?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            _buildFreeInfoContainer(),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final file = File(imageFile.path); 
              await _processFaceVerification(file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  // ✅ Updated info widget for FREE mode
  Widget _buildFreeInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.savings, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '100% FREE - Only face features used (no image stored)',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processFaceVerification(File imageFile) async {
    _showLoadingDialog('Processing...');

    try {
      Map<String, dynamic> result;

      print('🔐 Starting verification type: ${widget.verificationType}');
      print('🔐 BookingId: ${widget.bookingId}');
      print('🔐 UserId: ${widget.userId}');

      if (widget.verificationType == 'booking') {
        result = await _faceService.registerFace(
          imageFile: imageFile,
          userId: widget.userId,
          bookingId: widget.bookingId,
        );

      } else if (widget.verificationType == 'pickup') {
        result = await _faceService.verifyFaceForPickup(
          bookingId: widget.bookingId,
          scannedImageFile: imageFile,
          renterId: widget.userId,
        );

      } else if (widget.verificationType == 'return') {
        result = await _faceService.verifyFaceForReturn(
          bookingId: widget.bookingId,
          scannedImageFile: imageFile,
          renterId: widget.userId,
        );
      } else {
        throw Exception('Invalid verification type: ${widget.verificationType}');
      }
      
      print('🔐 Verification result: $result');
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success'] == true) {
        print('✅ Verification successful!');
        _showSuccessDialog(
          result['message'],
          result['imageBase64'], // Will be null in FREE mode
        );
      } else {
        print('❌ Verification failed: ${result['message']}');
        _showError(result['message'] ?? 'Verification failed');
        setState(() => _isProcessing = false);
      }

    } catch (e, stackTrace) {
      print('❌ EXCEPTION in _processFaceVerification: $e');
      print('📍 Stack trace: $stackTrace');
      
      if (mounted) {
        if (Navigator.of(context).canPop()) Navigator.pop(context); 
        _showError('Verification error: ${e.toString()}');
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.accentColor,
              ),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message, String? imageBase64) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Success')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: const [
                  Icon(Icons.savings, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100% FREE - Only features stored for verification!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'success': true,
                'imageBase64': imageBase64, // Will be null in FREE mode
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getInstructionText() {
    if (kIsWeb) {
      return 'Click the button below to access your camera\nand capture your face\n(100% FREE - No storage costs)';
    }
    
    switch (widget.verificationType) {
      case 'booking':
        return 'Position your face in the frame\nThis will be used for future verification\n(Features only - FREE)';
      case 'pickup':
        return 'Scan rentee\'s face to verify identity\nBefore handing over the item';
      case 'return':
        return 'Scan rentee\'s face to verify identity\nBefore accepting the return';
      default:
        return 'Position face in the frame';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web version - simpler UI with button
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: AppColors.accentColor,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.verificationType == 'booking'
                    ? 'Register Your Face'
                    : 'Verify Identity',
                style: const TextStyle(fontSize: 18),
              ),
              const Text(
                '100% FREE - Features Only',
                style: TextStyle(fontSize: 10, color: Colors.greenAccent),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 120,
                  color: AppColors.accentColor.withOpacity(0.5),
                ),
                const SizedBox(height: 32),
                Text(
                  _getInstructionText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 300,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureFromWebCamera,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 32),
                    label: Text(
                      _isProcessing ? 'Processing...' : 'Open Camera',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.savings, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No image storage costs! Only facial features are saved for verification.',
                          style: TextStyle(color: Colors.green, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile version - camera preview
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.verificationType == 'booking'
                  ? 'Register Your Face'
                  : 'Verify Identity',
              style: const TextStyle(fontSize: 18),
            ),
            const Text(
              '100% FREE - Features Only',
              style: TextStyle(fontSize: 10, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentColor,
              ),
            ),

          // Face outline overlay
          if (_isCameraInitialized)
            Center(
              child: Container(
                width: 280,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isProcessing ? Colors.green : Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
            ),

          // Instructions
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getInstructionText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isProcessing ? null : _captureFromMobileCamera,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isProcessing
                        ? Colors.grey
                        : AppColors.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 40,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }
}