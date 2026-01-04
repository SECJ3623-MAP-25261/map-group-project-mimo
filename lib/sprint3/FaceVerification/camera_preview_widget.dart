import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class CameraPreviewWidget extends StatelessWidget {
  final String verificationType;
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final bool isProcessing;
  final VoidCallback onCapture;

  const CameraPreviewWidget({
    super.key,
    required this.verificationType,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.isProcessing,
    required this.onCapture,
  });

  String get _title {
    return verificationType == 'booking'
        ? 'Register Your Face'
        : 'Verify Identity';
  }

  String get _instructionText {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_title, style: const TextStyle(fontSize: 18)),
      ),
      body: Stack(
        children: [
          _buildCameraPreview(),
          if (isCameraInitialized) _buildFaceOverlay(),
          _buildInstructions(),
          _buildCaptureButton(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (isCameraInitialized && cameraController != null) {
      return Positioned.fill(
        child: AspectRatio(
          aspectRatio: cameraController!.value.aspectRatio,
          child: CameraPreview(cameraController!),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentColor),
    );
  }

  Widget _buildFaceOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 350,
        decoration: BoxDecoration(
          border: Border.all(
            color: isProcessing ? Colors.green : Colors.white,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(200),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
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
          _instructionText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: isProcessing ? null : onCapture,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isProcessing ? Colors.grey : AppColors.accentColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isProcessing
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
    );
  }
}