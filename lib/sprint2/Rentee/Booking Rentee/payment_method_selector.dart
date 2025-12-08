// lib/sprint2/Booking/widgets/payment_method_selector.dart

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final List<String> paymentMethods;
  final Function(String?) onMethodChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.paymentMethods,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            value: selectedMethod,
            onChanged: onMethodChanged,
            items: paymentMethods
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
      ],
    );
  }
}