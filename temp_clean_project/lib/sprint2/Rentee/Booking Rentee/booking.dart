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
import 'package:profile_managemenr/sprint2/Rentee/searchRentee/search.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white),
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
          /// ✅ MORE OBVIOUS COMPARE BUTTON
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ItemDetailsCard(itemName: _itemName, itemImages: _itemImages),
                  const SizedBox(height: 24),
                  DateSelectionField(
                    label: 'Rental Start Date',
                    date: _startDate,
                    isStart: true,
                    onDateSelected: (_) {},
                    unavailableDates: _unavailableDates,
                  ),
                  const SizedBox(height: 24),
                  DateSelectionField(
                    label: 'Rental End Date',
                    date: _endDate,
                    isStart: false,
                    onDateSelected: (_) {},
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
                    onMethodChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedPaymentMethod = v);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
