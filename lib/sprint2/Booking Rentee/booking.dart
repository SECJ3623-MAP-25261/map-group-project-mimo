// lib/sprint2/Booking/booking.dart

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'dart:convert';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  const BookingScreen({super.key, this.itemData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPaymentMethod = 'Credit/Debit Card';
  bool _isSubmitting = false;
  
  final List<String> _paymentMethods = [
    'Credit/Debit Card',
    'Online Banking',
    'E-Wallet',
    'Cash (Upon Pickup)'
  ];

  static const Color _rateColor = Color(0xFF1E3A8A);

  // >>> ADDED FOR SWIPEABLE IMAGES <<<
  late PageController _imagePageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // ✅ GETTERS INCLUDING renterId
  String get _itemName => widget.itemData?['name'] ?? 'Selected Attire';
  String get _itemId => widget.itemData?['id'] ?? 'unknown';
  String get _renterId => widget.itemData?['renterId'] ?? ''; // ✅ CRITICAL FIX
  List<dynamic> get _itemImages {
    final images = widget.itemData?['images'];
    if (images is List && images.isNotEmpty) {
      return images;
    }
    final singleImage = widget.itemData?['image'];
    if (singleImage != null) {
      return [singleImage];
    }
    return [];
  }
  double get _ratePerDay => widget.itemData?['price'] ?? 6.00;

  int get _rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_endDate!.isBefore(_startDate!)) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _estimatedTotal => _rentalDays * _ratePerDay;

  void _showFullScreenImage(String imageData) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: imageData.startsWith('http')
                    ? Image.network(imageData, fit: BoxFit.contain)
                    : Image.memory(base64Decode(imageData), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentColor,
              onPrimary: Colors.white,
              onSurface: AppColors.lightTextColor,
            ),
            dialogBackgroundColor: AppColors.lightCardBackground,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_rentalDays <= 0) {
      _showSnackBar('Please select valid rental dates', Colors.red);
      return;
    }

    // ✅ CRITICAL: Check renterId is available
    if (_renterId.isEmpty) {
      _showSnackBar('Item owner information missing. Cannot book.', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.userId;
      final userEmail = _authService.userEmail ?? 'unknown@email.com';

      if (userId == null) {
        if (!mounted) return;
        _showSnackBar('Please log in to make a booking', Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      String userName = 'Unknown User';
      try {
        final userData = await _authService.getUserData(userId);
        userName = userData?['fullName'] ?? userEmail.split('@')[0];
      } catch (e) {
        userName = userEmail.split('@')[0];
      }

      print('Creating booking...');
      print('Item: $_itemName');
      print('Renter ID: $_renterId'); // ✅ Debug log
      print('Days: $_rentalDays');
      print('Total: RM ${_estimatedTotal.toStringAsFixed(2)}');

      final bookingId = await _bookingService.createBooking(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        renterId: _renterId, // ✅ NOW CORRECTLY PASSED
        itemId: _itemId,
        itemName: _itemName,
        itemImage: _itemImages.isNotEmpty ? _itemImages[0].toString() : '',
        itemPrice: _ratePerDay,
        startDate: _startDate!,
        endDate: _endDate!,
        rentalDays: _rentalDays,
        totalAmount: _estimatedTotal,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (bookingId != null) {
        _showSnackBar(
          'Booking successful! ID: ${bookingId.substring(0, 8)}',
          Colors.green,
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Booking Confirmed!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Item: $_itemName'),
                    const SizedBox(height: 8),
                    Text('Rental Days: $_rentalDays days'),
                    const SizedBox(height: 8),
                    Text('Total: RM ${_estimatedTotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Payment: $_selectedPaymentMethod'),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
      } else {
        _showSnackBar('Failed to create booking. Please try again.', Colors.red);
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      print('Error submitting booking: $e');
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isStart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.lightInputFillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null
                      ? 'dd/mm/yyyy'
                      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: TextStyle(
                    color: date == null
                        ? AppColors.lightHintColor
                        : AppColors.lightTextColor,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 20, color: AppColors.lightHintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color:
                  isTotal ? AppColors.lightTextColor : AppColors.lightHintColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? _rateColor : AppColors.lightTextColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('=== BOOKING SCREEN DEBUG ===');
    print('Item Data: ${widget.itemData}');
    print('Item Name: $_itemName');
    print('Renter ID: $_renterId'); // ✅ Debug
    print('Rate Per Day: $_ratePerDay');
    print('Images Count: ${_itemImages.length}');
    print('===========================');

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'New Booking: $_itemName',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: AppColors.lightCardBackground,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attire Name',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightInputFillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightBorderColor),
                ),
                child: Text(
                  _itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.lightTextColor,
                  ),
                ),
              ),

              // >>> SWIPEABLE IMAGE CAROUSEL <<<
              const SizedBox(height: 16),
              const Text(
                'Item Images',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextColor,
                ),
              ),
              const SizedBox(height: 8),

              if (_itemImages.isEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorderColor),
                      color: AppColors.lightInputFillColor,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 50, color: AppColors.lightHintColor),
                          SizedBox(height: 8),
                          Text('No images available',
                              style: TextStyle(
                                  color: AppColors.lightHintColor,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: PageView.builder(
                          controller: _imagePageController,
                          itemCount: _itemImages.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final imageData = _itemImages[index].toString();
                            return GestureDetector(
                              onTap: () => _showFullScreenImage(imageData),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.lightBorderColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageData.startsWith('http')
                                      ? Image.network(
                                          imageData,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            color: AppColors.lightInputFillColor,
                                            child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 50, color: AppColors.lightHintColor),
                                            ),
                                          ),
                                        )
                                      : Image.memory(
                                          base64Decode(imageData),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            color: AppColors.lightInputFillColor,
                                            child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 50, color: AppColors.lightHintColor),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Dots indicator
                    if (_itemImages.length > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _itemImages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? AppColors.accentColor
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Swipe to view more • Tap to enlarge',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.lightHintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              // <<< END SWIPEABLE IMAGE CAROUSEL <<<

              const SizedBox(height: 24),
              _buildDateField(
                label: 'Rental Start Date (Pickup)',
                date: _startDate,
                isStart: true,
              ),
              const SizedBox(height: 24),
              _buildDateField(
                label: 'Rental End Date (Return)',
                date: _endDate,
                isStart: false,
              ),
              const SizedBox(height: 32),
              const Text(
                'Rental Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextColor,
                ),
              ),
              const Divider(
                  height: 16, thickness: 1, color: AppColors.lightBorderColor),
              _buildSummaryRow('Rate', 'RM ${_ratePerDay.toStringAsFixed(2)}/day'),
              _buildSummaryRow('Rental Days', '$_rentalDays days'),
              const SizedBox(height: 8),
              _buildSummaryRow('Estimated Total:',
                  'RM ${_estimatedTotal.toStringAsFixed(2)}',
                  isTotal: true),
              const SizedBox(height: 32),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightInputFillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightBorderColor),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                  value: _selectedPaymentMethod,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedPaymentMethod = newValue);
                    }
                  },
                  items: _paymentMethods
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(
                              color: AppColors.lightTextColor)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                              color: AppColors.lightBorderColor, width: 2),
                          foregroundColor: AppColors.lightHintColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('CANCEL',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      
                      child: ElevatedButton(
                        onPressed: (_rentalDays > 0 && _renterId.isNotEmpty && !_isSubmitting)
                            ? _submitBooking
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 4,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('BOOKING & PAY',
                                style: TextStyle(fontWeight: FontWeight.bold)),
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
}