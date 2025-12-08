// lib/accounts/profile/screen/history_rentee.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/sprint2/Rentee/ReviewRentee/review_rentee.dart';

class HistoryRenteeScreen extends StatefulWidget {
  final bool isRenter;

  const HistoryRenteeScreen({
    super.key,
    this.isRenter = false,
  });

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
        final bookings = widget.isRenter
            ? await _bookingService.getRenterBookings(userId)
            : await _bookingService.getUserBookings(userId);
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
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'ongoing': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(context, isSmallScreen),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accentColor,
              ),
            )
          : _bookings.isEmpty
              ? _buildEmptyState(isSmallScreen)
              : _buildBookingsList(screenWidth, isSmallScreen),
      bottomNavigationBar: _buildBottomButton(isSmallScreen),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSmallScreen) {
    return AppBar(
      backgroundColor: AppColors.accentColor,
      elevation: 0,
      title: Text(
        widget.isRenter ? 'Earnings History' : 'Rental History',
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 18 : 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: isSmallScreen ? 20 : 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: _loadBookings,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: isSmallScreen ? 64 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              widget.isRenter
                  ? 'Your earnings history will appear here'
                  : 'Your rental history will appear here',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(double screenWidth, bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.accentColor,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(booking, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isSmallScreen) {
    final status = booking['status'] ?? 'pending';
    final hasReview = booking['hasReview'] ?? false;
    final bookingId = booking['id'];
    final shortId = bookingId.substring(0, 8).toUpperCase();
    final statusColor = _getStatusColor(status);
    final isVerySmallScreen = MediaQuery.of(context).size.width < 340;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightBorderColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Item Name and Status
          Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['itemName'] ?? 'Unknown Item',
                        style: TextStyle(
                          color: AppColors.lightTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmallScreen ? 15 : (isSmallScreen ? 16 : 17),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        'BKG-$shortId',
                        style: TextStyle(
                          color: AppColors.lightHintColor,
                          fontSize: isVerySmallScreen ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 8 : 10,
                    vertical: isVerySmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: isVerySmallScreen ? 10 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Booking Details
          Padding(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 14),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Start Date',
                  value: _formatDate(booking['startDate']),
                  isSmallScreen: isSmallScreen,
                  isVerySmallScreen: isVerySmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                _buildDetailRow(
                  icon: Icons.event_available_rounded,
                  label: 'Return Date',
                  value: _formatDate(booking['actualReturnDate']),
                  isSmallScreen: isSmallScreen,
                  isVerySmallScreen: isVerySmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                _buildDetailRow(
                  icon: Icons.payments_rounded,
                  label: 'Final Fee',
                  value: 'RM ${(booking['finalFee'] ?? 0.0).toStringAsFixed(2)}',
                  isSmallScreen: isSmallScreen,
                  isVerySmallScreen: isVerySmallScreen,
                  valueColor: AppColors.accentColor,
                  isBold: true,
                ),
              ],
            ),
          ),

          // Action Button
          if (status == 'completed')
            Padding(
              padding: EdgeInsets.fromLTRB(
                isVerySmallScreen ? 12 : 14,
                0,
                isVerySmallScreen ? 12 : 14,
                isVerySmallScreen ? 12 : 14,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasReview
                      ? null
                      : () async {
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
                        },
                  icon: Icon(
                    hasReview ? Icons.check_circle_rounded : Icons.rate_review_rounded,
                    size: isVerySmallScreen ? 16 : 18,
                  ),
                  label: Text(
                    hasReview ? 'REVIEWED' : 'LEAVE REVIEW',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 12 : 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasReview ? Colors.grey : AppColors.accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isVerySmallScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: hasReview ? 0 : 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
    required bool isVerySmallScreen,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: isVerySmallScreen ? 16 : 18,
          color: AppColors.accentColor.withOpacity(0.7),
        ),
        SizedBox(width: isSmallScreen ? 8 : 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.lightHintColor,
                  fontSize: isVerySmallScreen ? 12 : 13,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.lightTextColor,
                    fontSize: isVerySmallScreen ? 13 : 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'CLOSE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}