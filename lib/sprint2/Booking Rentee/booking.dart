// booking.dart

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart'; 

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  // Updated constructor to accept item data
  const BookingScreen({super.key, this.itemData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPaymentMethod = 'Credit/Debit Card';
  final List<String> _paymentMethods = ['Credit/Debit Card', 'Online Banking', 'E-Wallet', 'Cash (Upon Pickup)'];

  // Constants for theming based on AppColors
  // Using AppColors.accentColor (Teal) for primary accents
  // Using light theme colors as main.dart sets themeMode: ThemeMode.light
  static const Color _rateColor = Color(0xFF1E3A8A); // A darker blue for rate/total

  final double _ratePerDay = 6.00; // RM 6.00/day

  // Get item name with fallback
  String get _itemName {
    return widget.itemData?['name'] ?? 'Selected Attire';
  }

  // Get item price with fallback
  double get _itemPrice {
    return widget.itemData?['price'] ?? 0.00;
  }

  // Calculate the number of days and total cost
  int get _rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_endDate!.isBefore(_startDate!)) return 0;
    
    // Add 1 to include both the pickup and return day
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _estimatedTotal {
    return _rentalDays * _ratePerDay;
  }

  // --- Date Picker Helper ---
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        // Apply theme to the date picker dialog using AppColors.accentColor
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentColor, // Header background (Teal)
              onPrimary: Colors.white, // Header text
              onSurface: AppColors.lightTextColor, // Calendar text
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
          // Reset end date if it precedes the new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // --- Input Field Widget with Calendar Icon ---
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
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextColor),
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
                  date == null ? 'dd/mm/yyyy' : '${date!.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: TextStyle(
                    color: date == null ? AppColors.lightHintColor : AppColors.lightTextColor,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: AppColors.lightHintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Summary Row Widget ---
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
    return Scaffold(
      // Use lightBackground and CardBackground from AppColors
      backgroundColor: AppColors.lightBackground, 
      
      // --- AppBar styled to match the image header with AppColors.accentColor ---
      appBar: AppBar(
        backgroundColor: AppColors.accentColor, // Teal accent color
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('New Booking: $_itemName', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      
      body: Container(
        // Use a Card or similar container for the main content to separate it from the background
        color: AppColors.lightCardBackground,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Attire Name Field (Read-only text field to mimic input look) ---
            const Text(
              'Attire Name',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextColor),
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
                style: const TextStyle(fontSize: 16, color: AppColors.lightTextColor),
              ),
            ),
            
            // --- Item Image Display ---
            if (widget.itemData?['image'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Item Image',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextColor),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightBorderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.itemData!['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.lightInputFillColor,
                        child: const Icon(Icons.image, size: 50, color: AppColors.lightHintColor),
                      );
                    },
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // --- Rental Start Date ---
            _buildDateField(
              label: 'Rental Start Date (Pickup)',
              date: _startDate,
              isStart: true,
            ),

            const SizedBox(height: 24),
            
            // --- Rental End Date ---
            _buildDateField(
              label: 'Rental End Date (Return)',
              date: _endDate,
              isStart: false,
            ),

            const SizedBox(height: 32),

            // --- Rental Summary Section ---
            const Text(
              'Rental Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightTextColor),
            ),
            const Divider(height: 16, thickness: 1, color: AppColors.lightBorderColor),
            
            _buildSummaryRow('Rate', 'RM ${_ratePerDay.toStringAsFixed(2)}/day'),
            _buildSummaryRow('Rental Days', '$_rentalDays days'),
            
            const SizedBox(height: 8),
            
            // Estimated Total
            _buildSummaryRow('Estimated Total:', 'RM ${_estimatedTotal.toStringAsFixed(2)}', isTotal: true),
            
            const SizedBox(height: 32),

            // --- Payment Method Dropdown ---
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextColor),
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
                  // Removing decoration properties to let the parent container style it
                  isDense: true, 
                ),
                value: _selectedPaymentMethod,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  }
                },
                items: _paymentMethods.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: AppColors.lightTextColor)),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),
            
            // --- Action Buttons ---
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.lightBorderColor, width: 2),
                        foregroundColor: AppColors.lightHintColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rentalDays > 0 
                        ? () {
                            // Booking action with item data
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Booking ${_rentalDays} days of $_itemName for RM ${_estimatedTotal.toStringAsFixed(2)}'),
                              ),
                            );
                          }
                        : null, // Disable button if dates are not valid
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor, // Teal color for the action button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 4,
                      ),
                      child: const Text('BOOKING & PAY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}