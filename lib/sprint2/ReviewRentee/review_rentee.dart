

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';

class ReviewRenteeScreen extends StatefulWidget {
  final String itemName;
  final String itemId;
  final String bookingId;

  const ReviewRenteeScreen({
    super.key,
    required this.itemName,
    required this.itemId,
    required this.bookingId,
  });

  @override
  State<ReviewRenteeScreen> createState() => _ReviewRenteeScreenState();
}

class _ReviewRenteeScreenState extends State<ReviewRenteeScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  
  int _selectedRating = 0;
  bool _isSubmitting = false;

  final Map<int, String> _ratingOptions = {
    1: '⭐ (Poor)',
    2: '⭐⭐ (Fair)',
    3: '⭐⭐⭐ (Average)',
    4: '⭐⭐⭐⭐ (Good)',
    5: '⭐⭐⭐⭐⭐ (Excellent)',
  };

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      _showSnackBar('Please select a rating', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.userId;
      final userEmail = _authService.userEmail ?? 'unknown@email.com';

      if (userId == null) {
        if (!mounted) return;
        _showSnackBar('Please log in to submit a review', Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      // Get user name
      String userName = 'Unknown User';
      try {
        final userData = await _authService.getUserData(userId);
        userName = userData?['fullName'] ?? userEmail.split('@')[0];
      } catch (e) {
        userName = userEmail.split('@')[0];
      }

      print('Submitting review...');
      print('Booking ID: ${widget.bookingId}');
      print('Rating: $_selectedRating');

      // Submit review to Firestore
      final success = await _bookingService.submitReview(
        bookingId: widget.bookingId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        itemId: widget.itemId,
        itemName: widget.itemName,
        rating: _selectedRating,
        ratingLabel: _ratingOptions[_selectedRating]!,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          'Review submitted successfully!',
          Colors.green,
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        });
      } else {
        _showSnackBar(
          'Failed to submit review. Please try again.',
          Colors.red,
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      print('Error submitting review: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return AppColors.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortBookingId = widget.bookingId.substring(0, 8).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: Text(
          'Review: ${widget.itemName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are reviewing rental BKG-$shortBookingId. Submit your feedback to help future renters!',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.lightTextColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.lightCardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBorderColor),
              ),
              child: DropdownButton<int>(
                value: _selectedRating == 0 ? null : _selectedRating,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text(
                  'Select Rating',
                  style: TextStyle(color: AppColors.lightHintColor),
                ),
                items: _ratingOptions.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: AppColors.lightTextColor,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() => _selectedRating = newValue ?? 0);
                },
              ),
            ),
            if (_selectedRating > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRatingColor(_selectedRating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRatingColor(_selectedRating)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _getRatingColor(_selectedRating),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _ratingOptions[_selectedRating]!,
                      style: TextStyle(
                        color: _getRatingColor(_selectedRating),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.lightBorderColor),
            const SizedBox(height: 24),
            const Text(
              'Detailed Comment (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Describe your experience with the item (fit, cleanliness, etc.) ...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.lightHintColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightCardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBorderColor),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Type your comments here...',
                  hintStyle: TextStyle(color: AppColors.lightHintColor),
                ),
                style: const TextStyle(color: AppColors.lightTextColor),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: AppColors.lightBorderColor,
                        width: 2,
                      ),
                      foregroundColor: AppColors.lightHintColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedRating > 0 && !_isSubmitting
                        ? _submitReview
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'SUBMIT REVIEW',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}