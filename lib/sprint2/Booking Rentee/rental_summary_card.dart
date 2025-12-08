// lib/sprint2/Booking/widgets/rental_summary_card.dart

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class RentalSummaryCard extends StatelessWidget {
  final double ratePerDay;
  final int rentalDays;
  final double estimatedTotal;

  static const Color _rateColor = Color(0xFF1E3A8A);

  const RentalSummaryCard({
    super.key,
    required this.ratePerDay,
    required this.rentalDays,
    required this.estimatedTotal,
  });

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
              color: isTotal ? AppColors.lightTextColor : AppColors.lightHintColor,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildSummaryRow('Rate', 'RM ${ratePerDay.toStringAsFixed(2)}/day'),
        _buildSummaryRow('Rental Days', '$rentalDays days'),
        const SizedBox(height: 8),
        _buildSummaryRow('Estimated Total:',
            'RM ${estimatedTotal.toStringAsFixed(2)}',
            isTotal: true),
      ],
    );
  }
}