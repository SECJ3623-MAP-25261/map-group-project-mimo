

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/sprint2/ReviewRentee/review_rentee.dart';

class HistoryRenteeScreen extends StatefulWidget {
  const HistoryRenteeScreen({super.key});

  @override
  State<HistoryRenteeScreen> createState() => _HistoryRenteeScreenState();
}

class _HistoryRenteeScreenState extends State<HistoryRenteeScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.userId;
      if (userId != null) {
        final bookings = await _bookingService.getUserBookings(userId);
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final DateTime date = timestamp.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'ongoing':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: const Text(
          'Your Rental History',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your rental history will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.lightBorderColor),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Item',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Booking ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Return (Actual)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Final Fee',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Action',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Booking Rows
                          ..._bookings.map((booking) {
                            final status = booking['status'] ?? 'pending';
                            final hasReview = booking['hasReview'] ?? false;
                            final bookingId = booking['id'];
                            final shortId = bookingId.substring(0, 8).toUpperCase();

                            return _RentalHistoryRow(
                              item: booking['itemName'] ?? 'Unknown Item',
                              bookingId: 'BKG-$shortId',
                              startDate: _formatDate(booking['startDate']),
                              returnDate: _formatDate(booking['actualReturnDate']),
                              finalFee:
                                  'RM ${(booking['finalFee'] ?? 0.0).toStringAsFixed(2)}',
                              status: status.toUpperCase(),
                              statusColor: _getStatusColor(status),
                              actionText: hasReview
                                  ? 'REVIEWED'
                                  : status == 'completed'
                                      ? 'LEAVE REVIEW'
                                      : 'VIEW',
                              actionEnabled: status == 'completed' && !hasReview,
                              onTap: status == 'completed' && !hasReview
                                  ? () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewRenteeScreen(
                                            itemName: booking['itemName'],
                                            itemId: booking['itemId'],
                                            bookingId: bookingId,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        _loadBookings();
                                      }
                                    }
                                  : null,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RentalHistoryRow extends StatelessWidget {
  final String item;
  final String bookingId;
  final String startDate;
  final String returnDate;
  final String finalFee;
  final String status;
  final Color statusColor;
  final String actionText;
  final bool actionEnabled;
  final VoidCallback? onTap;

  const _RentalHistoryRow({
    required this.item,
    required this.bookingId,
    required this.startDate,
    required this.returnDate,
    required this.finalFee,
    required this.status,
    required this.statusColor,
    required this.actionText,
    required this.actionEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                item,
                style: const TextStyle(
                  color: AppColors.lightTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                bookingId,
                style: const TextStyle(
                  color: AppColors.lightTextColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                startDate,
                style: const TextStyle(
                  color: AppColors.lightTextColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                returnDate,
                style: const TextStyle(
                  color: AppColors.lightTextColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                finalFee,
                style: const TextStyle(
                  color: AppColors.lightTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: actionEnabled ? onTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionEnabled
                      ? AppColors.accentColor
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}