import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:profile_managemenr/sprint2/ReviewRentee/reviewRentee.dart';
class HistoryRenteeScreen extends StatelessWidget {
  const HistoryRenteeScreen({super.key});

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
      ),
      body: Padding(
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
                  Expanded(
                    flex: 2,
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
                  Expanded(
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
                  Expanded(
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
                  Expanded(
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
                  Expanded(
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
                  Expanded(
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
                  Expanded(
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

            // Single Item Row
            _RentalHistoryRow(
              item: 'UTM Grad Robe',
              bookingId: 'BKG-120',
              startDate: '2025-01-15',
              returnDate: '2025-01-18',
              finalFee: 'RM 18.00',
              status: 'Completed',
              statusColor: Colors.green,
              actionText: 'LEAVE REVIEW',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewRenteeScreen(
                      itemName: 'UTM Grad Robe',
                      bookingId: 'BKG-120',
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // Close Button
            SizedBox(
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
          ],
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
  final VoidCallback onTap;

  const _RentalHistoryRow({
    required this.item,
    required this.bookingId,
    required this.startDate,
    required this.returnDate,
    required this.finalFee,
    required this.status,
    required this.statusColor,
    required this.actionText,
    required this.onTap,
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
          Expanded(
            flex: 2,
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
          Expanded(
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
          Expanded(
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
          Expanded(
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
          Expanded(
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
          Expanded(
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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