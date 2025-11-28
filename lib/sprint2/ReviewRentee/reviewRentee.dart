import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ReviewRenteeScreen extends StatefulWidget {
  final String itemName;
  final String bookingId;

  const ReviewRenteeScreen({
    super.key,
    required this.itemName,
    required this.bookingId,
  });

  @override
  State<ReviewRenteeScreen> createState() => _ReviewRenteeScreenState();
}

class _ReviewRenteeScreenState extends State<ReviewRenteeScreen> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  final Map<int, String> _ratingOptions = {
    1: '⭐ (Poor)',
    2: '⭐⭐ (Fair)',
    3: '⭐⭐⭐ (Average)',
    4: '⭐⭐⭐⭐ (Good)',
    5: '⭐⭐⭐⭐⭐ (Excellent)',
  };

  @override
  Widget build(BuildContext context) {
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
            // Header Text
            Text(
              'You are reviewing rental ${widget.bookingId}. Submit your feedback to help future renters!',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.lightTextColor,
              ),
            ),

            const SizedBox(height: 32),

            // Your Rating Section
            const Text(
              'Your Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextColor,
              ),
            ),

            const SizedBox(height: 16),

            // Rating Dropdown
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
                underline: const SizedBox(), // Remove default underline
                hint: const Text(
                  'Select Rating',
                  style: TextStyle(
                    color: AppColors.lightHintColor,
                  ),
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
                  setState(() {
                    _selectedRating = newValue ?? 0;
                  });
                },
              ),
            ),

            // Display selected rating description
            if (_selectedRating > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRatingColor(_selectedRating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRatingColor(_selectedRating),
                  ),
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

            // Detailed Comment Section
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

            // Comment Text Field
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
                  hintStyle: TextStyle(
                    color: AppColors.lightHintColor,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.lightTextColor,
                ),
              ),
            ),

            const Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                    onPressed: _selectedRating > 0
                        ? () {
                            // Handle review submission
                            _submitReview();
                          }
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
                    child: const Text(
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

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red; // Poor
      case 2:
        return Colors.orange; // Fair
      case 3:
        return Colors.yellow[700]!; // Average
      case 4:
        return Colors.lightGreen; // Good
      case 5:
        return Colors.green; // Excellent
      default:
        return AppColors.accentColor;
    }
  }

  void _submitReview() {
    // Handle review submission logic here
    final reviewData = {
      'itemName': widget.itemName,
      'bookingId': widget.bookingId,
      'rating': _selectedRating,
      'ratingLabel': _ratingOptions[_selectedRating],
      'comment': _commentController.text,
    };

    print('Review submitted: $reviewData'); // For debugging

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review submitted for ${widget.itemName}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}