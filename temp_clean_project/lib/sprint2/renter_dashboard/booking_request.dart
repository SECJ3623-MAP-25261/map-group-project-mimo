import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/services/booking_service.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'dart:convert';
import 'package:profile_managemenr/sprint3/FaceVerification/face_capture_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  final String renterId;

  const BookingRequestsScreen({super.key, required this.renterId});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final BookingService _bookingService = BookingService();
  String _filterStatus = 'all';

  Stream<QuerySnapshot> _getBookingsStream() {
    var query = FirebaseFirestore.instance
        .collection('bookings')
        .where('renterId', isEqualTo: widget.renterId);

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return query.snapshots();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
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

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    final success = await _bookingService.updateBookingStatus(bookingId, newStatus);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking ${newStatus == 'confirmed' ? 'approved' : 'updated'}!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update booking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 👇 NEW: Navigate to face verification for pickup
  Future<void> _verifyFaceForPickup(String bookingId) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FaceCaptureScreen(
          bookingId: bookingId,
          userId: widget.renterId,
          verificationType: 'pickup',
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      // Automatically update booking status to ongoing
      await _updateBookingStatus(bookingId, 'ongoing');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identity verified! Item handed over.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 👇 NEW: Navigate to face verification for return
  Future<void> _verifyFaceForReturn(String bookingId) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FaceCaptureScreen(
          bookingId: bookingId,
          userId: widget.renterId,
          verificationType: 'return',
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      // Automatically update booking status to completed
      await _updateBookingStatus(bookingId, 'completed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return verified! Booking completed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    final bookingId = booking['id'];
    final status = booking['status'] ?? 'pending';
    final faceVerified = booking['faceVerified'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item: ${booking['itemName']}', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Rentee: ${booking['userName']}'),
              Text('Email: ${booking['userEmail']}'),
              SizedBox(height: 8),
              
              // 👇 NEW: Face verification status
              if (faceVerified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Face Verified',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 8),
              Text('Start: ${_formatDate(booking['startDate'])}'),
              Text('End: ${_formatDate(booking['endDate'])}'),
              Text('Days: ${booking['rentalDays']}'),
              SizedBox(height: 8),
              Text('Total: RM ${booking['totalAmount'].toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Payment: ${booking['paymentMethod']}'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Text(
                  'Status: ${status.toUpperCase()}',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          if (status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateBookingStatus(bookingId, 'cancelled');
              },
              child: Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateBookingStatus(bookingId, 'confirmed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Approve'),
            ),
          ] else if (status == 'confirmed') ...[
            // 👇 NEW: Face verification button for pickup
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _verifyFaceForPickup(bookingId);
              },
              icon: Icon(Icons.face_retouching_natural),
              label: Text('Verify & Hand Over'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
            ),
          ] else if (status == 'ongoing') ...[
            // 👇 NEW: Face verification button for return
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _verifyFaceForReturn(bookingId);
              },
              icon: Icon(Icons.face_retouching_natural),
              label: Text('Verify & Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        title: Text('Booking Requests'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  SizedBox(width: 8),
                  _buildFilterChip('Confirmed', 'confirmed'),
                  SizedBox(width: 8),
                  _buildFilterChip('Ongoing', 'ongoing'),
                  SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No booking requests',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final status = booking['status'] ?? 'pending';
                      final imageData = booking['itemImage'];
                      final faceVerified = booking['faceVerified'] ?? false;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.lightCardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageData != null && imageData.isNotEmpty
                                ? (imageData.startsWith('http')
                                    ? Image.network(
                                        imageData,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.broken_image),
                                          );
                                        },
                                      )
                                    : Image.memory(
                                        base64Decode(imageData),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.broken_image),
                                          );
                                        },
                                      ))
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image),
                                  ),
                          ),
                          title: Text(
                            booking['itemName'] ?? 'Unknown Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text('Rentee: ${booking['userName']}'),
                              Text('${_formatDate(booking['startDate'])} - ${_formatDate(booking['endDate'])}'),
                              Text('RM ${booking['totalAmount'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: AppColors.accentColor,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _getStatusColor(status)),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // 👇 NEW: Face verification badge
                                  if (faceVerified) ...[
                                    SizedBox(width: 4),
                                    Icon(Icons.verified_user, 
                                        color: Colors.green, size: 16),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () => _showBookingDetails(booking),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.accentColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.lightTextColor,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.accentColor : Colors.grey[300]!,
        ),
      ),
    );
  }
}