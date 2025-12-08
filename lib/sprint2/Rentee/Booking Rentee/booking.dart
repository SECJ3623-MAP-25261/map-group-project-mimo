import 'package:flutter/material.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import '../../constants/app_colors.dart';
import 'item_details_card.dart';
import 'date_selection_field.dart';
import 'rental_summary_card.dart';
import 'payment_method_selector.dart';

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
  
  List<Map<String, dynamic>> _existingBookings = [];
  Set<DateTime> _unavailableDates = {};
  bool _isLoadingBookings = true;
  String _debugMessage = '';
  
  final List<String> _paymentMethods = [
    'Credit/Debit Card',
    'Online Banking',
    'E-Wallet',
    'Cash (Upon Pickup)'
  ];

  // GETTERS
  String get _itemName => widget.itemData?['name'] ?? 'Selected Attire';
  String get _itemId => widget.itemData?['id'] ?? '';
  String get _renterId => widget.itemData?['renterId'] ?? '';
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

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: BookingScreen initialized');
    print('🔍 DEBUG: itemData = ${widget.itemData}');
    print('🔍 DEBUG: itemId = $_itemId');
    print('🔍 DEBUG: renterId = $_renterId');
    
    _loadExistingBookings();
  }

  Future<void> _loadExistingBookings() async {
    print(' DEBUG: Starting to load bookings for itemId: $_itemId');
    
    if (_itemId.isEmpty) {
      print(' DEBUG: itemId is empty, skipping booking load');
      setState(() {
        _isLoadingBookings = false;
        _debugMessage = 'No item ID provided';
      });
      return;
    }

    try {
      print(' DEBUG: Calling getItemBookings...');
      final bookings = await _bookingService.getItemBookings(_itemId);
      print(' DEBUG: Got ${bookings.length} bookings');
      
      print(' DEBUG: Calculating unavailable dates...');
      final unavailable = _bookingService.getUnavailableDates(bookings);
      print(' DEBUG: Found ${unavailable.length} unavailable dates');
      
      if (mounted) {
        setState(() {
          _existingBookings = bookings;
          _unavailableDates = unavailable;
          _isLoadingBookings = false;
        });
        print(' DEBUG: State updated successfully');
      }
    } catch (e, stackTrace) {
      print(' DEBUG: Error loading bookings: $e');
      print(' DEBUG: Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          _debugMessage = 'Error: ${e.toString()}';
        });
      }
      
      _showSnackBar('Error loading bookings: ${e.toString()}', Colors.red);
    }
  }

  bool _isDateUnavailable(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isUnavailable = _unavailableDates.contains(normalizedDate);
    print(' DEBUG: Checking date $normalizedDate: ${isUnavailable ? "UNAVAILABLE" : "available"}');
    return isUnavailable;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    print(' DEBUG: Opening date picker, isStart=$isStart');
    
    try {
      // Find a valid initial date (first available date)
      DateTime initialDate = isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now());
      
      // If the initial date is unavailable, find the next available date
      while (_isDateUnavailable(initialDate) && initialDate.isBefore(DateTime(2027))) {
        initialDate = initialDate.add(const Duration(days: 1));
      }
      
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2027),
        
        selectableDayPredicate: (DateTime date) {
          final isSelectable = !_isDateUnavailable(date);
          return isSelectable;
        },
        
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.accentColor,
                onPrimary: Colors.white,
                onSurface: AppColors.lightTextColor,
              ),
              dialogBackgroundColor: AppColors.lightCardBackground,
              disabledColor: Colors.red.withOpacity(0.3),
            ),
            child: child!,
          );
        },
      );

      print(' DEBUG: Date picked: $picked');

      if (picked != null) {
        if (isStart) {
          setState(() {
            _startDate = picked;
            if (_endDate != null && _endDate!.isBefore(_startDate!)) {
              _endDate = null;
            }
            if (_endDate != null && !_isRangeAvailable(_startDate!, _endDate!)) {
              _showSnackBar(
                'Selected range contains already booked dates. Please choose different dates.',
                Colors.orange,
              );
              _endDate = null;
            }
          });
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            _showSnackBar('End date cannot be before start date', Colors.red);
            return;
          }
          
          if (_startDate != null && !_isRangeAvailable(_startDate!, picked)) {
            _showSnackBar(
              'Selected range contains already booked dates. Please choose different dates.',
              Colors.orange,
            );
            return;
          }
          
          setState(() {
            _endDate = picked;
          });
        }
        print('✅ DEBUG: Date set successfully');
      }
    } catch (e, stackTrace) {
      print(' DEBUG: Error in date selection: $e');
      print(' DEBUG: Stack trace: $stackTrace');
      _showSnackBar('Error selecting date: ${e.toString()}', Colors.red);
    }
  }

  bool _isRangeAvailable(DateTime start, DateTime end) {
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (_unavailableDates.contains(current)) {
        return false;
      }
      current = current.add(const Duration(days: 1));
    }
    return true;
  }

  Future<void> _submitBooking() async {
    print('🔍 DEBUG: Starting booking submission...');
    
    if (_rentalDays <= 0) {
      _showSnackBar('Please select valid rental dates', Colors.red);
      return;
    }

    if (_renterId.isEmpty) {
      _showSnackBar('Item owner information missing. Cannot book.', Colors.red);
      return;
    }

    if (_itemId.isEmpty) {
      _showSnackBar('Item information missing. Cannot book.', Colors.red);
      return;
    }

    if (!_isRangeAvailable(_startDate!, _endDate!)) {
      _showSnackBar(
        'These dates are no longer available. Please select different dates.',
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

      print('🔍 DEBUG: Creating booking with userId=$userId, itemId=$_itemId');

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
      );

      print('🔍 DEBUG: Booking result: $bookingId');

      if (!mounted) return;

      if (bookingId == 'ABORTED: OVERLAP') {
        _showSnackBar(
          'Booking conflict! The item was just booked for those dates. Please select new dates.',
          Colors.orange,
        );
        setState(() => _isSubmitting = false);
        await _loadExistingBookings();
        return;
      }

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
        _showSnackBar('Failed to create booking. Please try again.', Colors.red);
        setState(() => _isSubmitting = false);
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      print('❌ DEBUG: Error submitting booking: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
      setState(() => _isSubmitting = false);
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
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
      ),
      body: _isLoadingBookings
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.accentColor,
                  ),
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
                    // Debug info banner
                    if (_debugMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _debugMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ItemDetailsCard(
                      itemName: _itemName,
                      itemImages: _itemImages,
                    ),

                    const SizedBox(height: 24),

                    DateSelectionField(
                      label: 'Rental Start Date (Pickup)',
                      date: _startDate,
                      isStart: true,
                      onDateSelected: (isStart) => _selectDate(context, isStart),
                      unavailableDates: _unavailableDates,
                    ),
                    const SizedBox(height: 24),
                    DateSelectionField(
                      label: 'Rental End Date (Return)',
                      date: _endDate,
                      isStart: false,
                      onDateSelected: (isStart) => _selectDate(context, isStart),
                      unavailableDates: _unavailableDates,
                    ),

                    const SizedBox(height: 32),

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
                              onPressed: (_rentalDays > 0 &&
                                      _renterId.isNotEmpty &&
                                      _itemId.isNotEmpty &&
                                      !_isSubmitting)
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
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