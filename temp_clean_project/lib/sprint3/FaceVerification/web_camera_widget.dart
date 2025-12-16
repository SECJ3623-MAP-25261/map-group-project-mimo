import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class WebCameraWidget extends StatelessWidget {
  final String verificationType;
  final bool isProcessing;
  final VoidCallback onCapture;

  const WebCameraWidget({
    super.key,
    required this.verificationType,
    required this.isProcessing,
    required this.onCapture,
  });

  String get _title {
    return verificationType == 'booking'
        ? 'Register Your Face'
        : 'Verify Identity';
  }

  String get _instructionText {
    return 'Click the button below to access your camera\nand capture your face';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        title: Text(_title, style: const TextStyle(fontSize: 18)),
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
                _instructionText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : onCapture,
                  icon: isProcessing
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
                    isProcessing ? 'Processing...' : 'Open Camera',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}