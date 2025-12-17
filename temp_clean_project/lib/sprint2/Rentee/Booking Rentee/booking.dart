import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/services/face_verification_service.dart';
import '../../../constants/app_colors.dart';
import 'item_details_card.dart';
import 'date_selection_field.dart';
import 'rental_summary_card.dart';
import 'payment_method_selector.dart';
import 'package:profile_managemenr/sprint3/FaceVerification/face_capture_screen.dart';
<<<<<<< HEAD
import 'package:profile_managemenr/sprint3/geolocation/geolocation.dart';
=======
import 'package:profile_managemenr/sprint2/Rentee/searchRentee/search.dart';
>>>>>>> 1f4ad4c46726dd32b1d26f7e4889b30a4cb33998

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  const BookingScreen({super.key, this.itemData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();

  final FaceVerificationService _faceService = FaceVerificationService(
    storeDisplayImage: false,
    similarityThreshold: 75.0,
  );

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPaymentMethod = 'Credit/Debit Card';
  bool _isSubmitting = false;
  bool _isFaceVerified = false;
  String? _faceImageBase64;
  List<double>? _faceFeatures;

  Set<DateTime> _unavailableDates = {};
  bool _isLoadingBookings = true;
  String _debugMessage = '';
<<<<<<< HEAD
  
  // 2. NEW STATE: Variables to store the selected Meet Up Point
  String _meetUpAddress = 'Select the Meet Up Point';
  double? _meetUpLatitude;
  double? _meetUpLongitude;
  
=======

>>>>>>> 1f4ad4c46726dd32b1d26f7e4889b30a4cb33998
  final List<String> _paymentMethods = [
    'Credit/Debit Card',
    'Online Banking',
    'E-Wallet',
    'Cash (Upon Pickup)',
  ];

  String get _itemName => widget.itemData?['name'] ?? 'Selected Attire';
  String get _itemId => widget.itemData?['id'] ?? '';
  String get _renterId => widget.itemData?['renterId'] ?? '';

  List<dynamic> get _itemImages {
    final images = widget.itemData?['images'];
    if (images is List && images.isNotEmpty) return images;
    final singleImage = widget.itemData?['image'];
    if (singleImage != null) return [singleImage];
    return [];
  }

  double get _ratePerDay =>
      widget.itemData?['price'] ?? widget.itemData?['pricePerDay'] ?? 6.00;

  int get _rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_endDate!.isBefore(_startDate!)) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _estimatedTotal => _rentalDays * _ratePerDay;

  @override
  void initState() {
    super.initState();
    _loadExistingBookings();
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _loadExistingBookings() async {
    if (_itemId.isEmpty) {
      setState(() {
        _isLoadingBookings = false;
        _debugMessage = 'No item ID provided';
      });
      return;
    }

    try {
      final bookings = await _bookingService.getItemBookings(_itemId);
      final unavailable = _bookingService.getUnavailableDates(bookings);

      if (mounted) {
        setState(() {
          _unavailableDates = unavailable;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          _debugMessage = e.toString();
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        return !_unavailableDates.any(
          (unavailable) =>
              unavailable.year == date.year &&
              unavailable.month == date.month &&
              unavailable.day == date.day,
        );
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentColor,
              onPrimary: Colors.white,
            ),
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
          if (_startDate == null) {
            _showSnackBar('Please select start date first', Colors.orange);
            return;
          }
          if (picked.isBefore(_startDate!)) {
            _showSnackBar('End date must be after start date', Colors.red);
            return;
          }
          if (!_isRangeAvailable(_startDate!, picked)) {
            _showSnackBar(
              'Selected range contains unavailable dates',
              Colors.red,
            );
            return;
          }
          _endDate = picked;
        }
      });
    }
  }

  bool _isRangeAvailable(DateTime start, DateTime end) {
    for (
      var date = start;
      date.isBefore(end.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      if (_unavailableDates.any(
        (unavailable) =>
            unavailable.year == date.year &&
            unavailable.month == date.month &&
            unavailable.day == date.day,
      )) {
        return false;
      }
    }
    return true;
  }

<<<<<<< HEAD
  
  Future<void> _selectMeetUpPoint() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const MapLocationPickerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _meetUpAddress = result['address'] as String? ?? 'Error fetching address';
        _meetUpLatitude = result['latitude'] as double?;
        _meetUpLongitude = result['longitude'] as double?;
      });
      _showSnackBar('Meet Up Point Selected: $_meetUpAddress', AppColors.accentColor);
    }
  }


  // New method: Verify face THEN submit booking
  Future<void> _verifyAndSubmitBooking() async {
    // Validate booking details first
=======
  Future<void> _verifyFace() async {
    // Get current user ID
    final userId = _authService.userId;
    if (userId == null) {
      _showSnackBar('Please log in to verify your face', Colors.red);
      return;
    }

    // Create temporary booking ID for face verification
    final tempBookingId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceCaptureScreen(
            bookingId: tempBookingId,
            userId: userId,
            verificationType: 'booking',
          ),
        ),
      );

      if (result != null && result is Map) {
        if (result['success'] == true) {
          // Face verification successful
          try {
            // Retrieve stored face data from the temp booking
            final tempData = await _faceService.getStoredFaceData(
              tempBookingId,
            );

            if (tempData != null && tempData['features'] != null) {
              setState(() {
                _isFaceVerified = true;
                _faceImageBase64 = result['imageBase64'] as String?;
                _faceFeatures = tempData['features'] as List<double>?;
              });

              _showSnackBar('Face verified successfully!', Colors.green);

              // Clean up temporary booking
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(tempBookingId)
                    .delete();
                print('✅ Temp booking cleaned up');
              } catch (e) {
                print('⚠️ Failed to clean up temp booking: $e');
              }
            } else {
              _showSnackBar(
                'Face data not saved properly. Please try again.',
                Colors.red,
              );
            }
          } catch (e) {
            print('❌ Error retrieving face data: $e');
            _showSnackBar(
              'Error storing face data: ${e.toString()}',
              Colors.red,
            );
          }
        } else {
          _showSnackBar(
            'Face verification failed. Please try again.',
            Colors.orange,
          );
        }
      } else {
        print('❌ Face capture cancelled or failed');
      }
    } catch (e) {
      print('❌ Error in face verification: $e');
      _showSnackBar('Face verification error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _submitBooking() async {
    if (!_isFaceVerified) {
      _showSnackBar('Please verify your face before booking', Colors.orange);
      return;
    }

>>>>>>> 1f4ad4c46726dd32b1d26f7e4889b30a4cb33998
    if (_rentalDays <= 0) {
      _showSnackBar('Please select valid rental dates', Colors.red);
      return;
    }
<<<<<<< HEAD
    
    // NEW VALIDATION: Check for Meet Up Point
    if (_meetUpLatitude == null || _meetUpLongitude == null) {
      _showSnackBar('Please select a Meet Up Point on the map', Colors.red);
      return;
    }
    
=======

>>>>>>> 1f4ad4c46726dd32b1d26f7e4889b30a4cb33998
    if (_renterId.isEmpty || _itemId.isEmpty) {
      _showSnackBar('Item or owner info missing. Cannot book.', Colors.red);
      return;
    }

    if (!_isRangeAvailable(_startDate!, _endDate!)) {
      _showSnackBar(
        'Dates no longer available. Please select new dates.',
        Colors.red,
      );
      await _loadExistingBookings();
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

      
      final bookingId = await _bookingService.createBooking(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        renterId: _renterId,
        itemId: _itemId,
        itemName: _itemName,
        itemImage: _itemImages.isNotEmpty ? _itemImages[0].toString() : '',
        itemPrice: _ratePerDay,
        startDate: _startDate!,
        endDate: _endDate!,
        rentalDays: _rentalDays,
        totalAmount: _estimatedTotal,
        paymentMethod: _selectedPaymentMethod,
        meetUpAddress: _meetUpAddress,     
        meetUpLatitude: _meetUpLatitude!,    
        meetUpLongitude: _meetUpLongitude!,  
      );

      if (!mounted) return;

      if (bookingId == 'ABORTED: OVERLAP') {
        _showSnackBar(
          'Booking conflict! Dates just taken. Select new dates.',
          Colors.orange,
        );
        setState(() => _isSubmitting = false);
        await _loadExistingBookings();
        return;
      }

      if (bookingId != null) {
        // Attach face features
        if (_isFaceVerified && _faceFeatures != null) {
          try {
            final verificationDoc = await FirebaseFirestore.instance
                .collection('face_verifications')
                .add({
                  'bookingId': bookingId,
                  'userId': userId,
                  'faceFeatures': _faceFeatures,
                  'verificationType': 'booking',
                  'timestamp': FieldValue.serverTimestamp(),
                  'verified': true,
                });

            await FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .update({
                  'faceVerified': true,
                  'faceVerificationId': verificationDoc.id,
                  'faceFeatures': _faceFeatures,
                  'faceVerificationDate': FieldValue.serverTimestamp(),
                });
          } catch (e) {
            print('❌ Error attaching face features: $e');
          }
        }

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
                    const SizedBox(height: 8),
                    // Display the selected Meet Up Point in the confirmation dialog
                    Row(
                      children: [
                        const Icon(Icons.location_pin, color: AppColors.accentColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Meetup: $_meetUpAddress', style: const TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Face Verified ✓',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
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
                      Navigator.pop(context);
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
        _showSnackBar(
          'Failed to create booking. Please try again.',
          Colors.red,
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      print('❌ Booking submission error: $e\nStack: $stackTrace');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.compare),
            label: const Text(
              'Compare',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(
                    preSelectedItem: widget.itemData,
                    startCompareMode: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoadingBookings
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading bookings...',
                    style: TextStyle(color: AppColors.lightHintColor),
                  ),
                  if (_debugMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _debugMessage,
                      style: TextStyle(
                        color: AppColors.lightHintColor,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            )
          : Container(
              color: AppColors.lightCardBackground,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ItemDetailsCard(
                      itemName: _itemName,
                      itemImages: _itemImages,
                    ),
                    const SizedBox(height: 24),

                    // Face Verification Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isFaceVerified
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFaceVerified ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isFaceVerified
                                    ? Icons.verified_user
                                    : Icons.face_retouching_natural,
                                color: _isFaceVerified
                                    ? Colors.green
                                    : Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isFaceVerified
                                          ? 'Face Verified ✓'
                                          : 'Face Verification Required',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _isFaceVerified
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isFaceVerified
                                          ? 'Your identity has been verified (100% FREE)'
                                          : 'Verify your face to proceed with booking',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!_isFaceVerified) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _verifyFace,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Verify Face (FREE)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    DateSelectionField(
                      label: 'Rental Start Date (Pickup)',
                      date: _startDate,
                      isStart: true,
                      onDateSelected: (isStart) =>
                          _selectDate(context, isStart),
                      unavailableDates: _unavailableDates,
                    ),
                    const SizedBox(height: 24),

                    DateSelectionField(
                      label: 'Rental End Date (Return)',
                      date: _endDate,
                      isStart: false,
                      onDateSelected: (isStart) =>
                          _selectDate(context, isStart),
                      unavailableDates: _unavailableDates,
                    ),
                    const SizedBox(height: 32),

                    // 5. NEW UI: Meet Up Point Selection Field
                    const Text(
                      'Select the Meet Up Point',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectMeetUpPoint, // Launch the map screen
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _meetUpLatitude == null ? Colors.red.withOpacity(0.5) : AppColors.lightBorderColor,
                            width: 2
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _meetUpLatitude == null ? Icons.location_on_outlined : Icons.location_on,
                              color: _meetUpLatitude == null ? Colors.red : AppColors.accentColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _meetUpAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _meetUpLatitude == null ? Colors.red : AppColors.lightTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.lightHintColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // End of NEW UI block

                    RentalSummaryCard(
                      ratePerDay: _ratePerDay,
                      rentalDays: _rentalDays,
                      estimatedTotal: _estimatedTotal,
                    ),
                    const SizedBox(height: 32),

                    PaymentMethodSelector(
                      selectedMethod: _selectedPaymentMethod,
                      paymentMethods: _paymentMethods,
                      onMethodChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedPaymentMethod = newValue);
                        }
                      },
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
<<<<<<< HEAD
                              onPressed: (_rentalDays > 0 &&
                                    _renterId.isNotEmpty &&
                                    _itemId.isNotEmpty &&
                                    _meetUpLatitude != null && // Ensure location is selected
                                    !_isSubmitting)
                                  ? _verifyAndSubmitBooking
=======
                              onPressed:
                                  (_rentalDays > 0 &&
                                      _renterId.isNotEmpty &&
                                      _itemId.isNotEmpty &&
                                      _isFaceVerified &&
                                      !_isSubmitting)
                                  ? _submitBooking
>>>>>>> 1f4ad4c46726dd32b1d26f7e4889b30a4cb33998
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'BOOKING & PAY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
