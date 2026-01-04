import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'dart:convert';
import 'package:profile_managemenr/sprint3/FaceVerification/face_capture_screen.dart';

// CORRECTED IMPORT: Use the standard path for the package
import 'package:url_launcher/url_launcher.dart'; 

// Placeholder BookingService (Update this with the actual implementation if necessary)
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Placeholder methods needed by BookingScreen 
  Future<List<Map<String, dynamic>>> getItemBookings(String itemId) async {
    return [];
  }

  Set<DateTime> getUnavailableDates(List<Map<String, dynamic>> bookings) {
    return {};
  }
}

class BookingRequestsScreen extends StatefulWidget {
  final String renterId;

  const BookingRequestsScreen({Key? key, required this.renterId}) : super(key: key);

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final BookingService _bookingService = BookingService();
  String _filterStatus = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔍 BookingRequestsScreen initialized');
    print('🔍 RenterId: ${widget.renterId}');
    _checkFirestoreConnection();
  }

  // Check Firestore connection and data
  Future<void> _checkFirestoreConnection() async {
    try {
      print('🔍 Checking Firestore connection...');
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .limit(1)
          .get();
      print('✅ Firestore connection successful');
      print('📊 Total bookings in collection: ${snapshot.docs.length}');
      
      // Check bookings for this renter
      final renterBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('renterId', isEqualTo: widget.renterId)
          .get();
      print('📊 Bookings for renterId ${widget.renterId}: ${renterBookings.docs.length}');
      
      if (renterBookings.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No bookings found for this account. Make sure bookings have the correct renterId field.';
        });
      }
    } catch (e) {
      print('❌ Firestore connection error: $e');
      setState(() {
        _errorMessage = 'Failed to connect to Firestore: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    print('🔍 Fetching bookings for renterId: ${widget.renterId}');
    print('🔍 Filter status: $_filterStatus');

    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('renterId', isEqualTo: widget.renterId);

    // Apply status filter if not 'all'
    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
      print('🔍 Filtering by status: $_filterStatus');
    }

    // Note: orderBy removed to avoid needing composite index
    // Bookings will be sorted in the UI instead

    return query.snapshots();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final DateTime date = timestamp is Timestamp
          ? timestamp.toDate()
          : (timestamp is DateTime ? timestamp : DateTime.now());
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
      default:
        return Colors.red;
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    final success = await _bookingService.updateBookingStatus(bookingId, newStatus);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status set to ${newStatus.toUpperCase()}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update booking status'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // LOGIC: Function to launch an external map application using url_launcher
  Future<void> _launchMap(double latitude, double longitude, String address) async {
    // Construct the standard Google Maps URL using coordinates
    final url = 'http://googleusercontent.com/maps.google.com/7';
    final uri = Uri.parse(url);
    
    // Check if the URI can be launched
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map for address: $address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      await _updateBookingStatus(bookingId, 'ongoing');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity verified! Item handed over and booking is ONGOING.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup verification failed: ${result?['message'] ?? 'User cancelled'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
      await _updateBookingStatus(bookingId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return verified! Booking COMPLETED.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Return verification failed: ${result?['message'] ?? 'User cancelled'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // MODIFIED METHOD: To show meet-up point details
  void _showBookingDetails(Map<String, dynamic> booking) {
    final bookingId = booking['id'];
    final status = booking['status'] ?? 'pending';
    final faceVerified = booking['faceVerified'] ?? false;
    
    final isReadyForPickup = status == 'confirmed';
    final isReadyForReturn = status == 'ongoing';
    
    // NEW: Extract location data
    final meetUpAddress = booking['meetUpAddress'] as String?;
    final meetUpLatitude = booking['meetUpLatitude'] as double?;
    final meetUpLongitude = booking['meetUpLongitude'] as double?;
    final isLocationAvailable = meetUpLatitude != null && meetUpLongitude != null && meetUpAddress != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Request Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item: ${booking['itemName'] ?? 'N/A'}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              _buildDetailRow('Rentee', booking['userName'] ?? 'N/A'),
              _buildDetailRow('Email', booking['userEmail'] ?? 'N/A'),
              
              const Divider(height: 20),
              
              _buildDetailRow('Start Date', _formatDate(booking['startDate'])),
              _buildDetailRow('End Date', _formatDate(booking['endDate'])),
              _buildDetailRow('Rental Days', '${booking['rentalDays'] ?? 'N/A'}'),
              _buildDetailRow('Payment', booking['paymentMethod'] ?? 'N/A'),
              
              const Divider(height: 20),
              
              // NEW UI BLOCK: Meet Up Point Details
              const Text(
                'Meet Up Location', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentColor),
              ),
              const SizedBox(height: 8),

              isLocationAvailable
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Address', meetUpAddress!),
                        
                        // Button to launch map
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            onPressed: () {
                                Navigator.pop(context); // Close dialog first
                                _launchMap(meetUpLatitude!, meetUpLongitude!, meetUpAddress);
                            },
                            icon: const Icon(Icons.map, size: 20, color: Colors.blue),
                            label: const Text('View on Map (Tap to open)'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildDetailRow('Address', 'Location data missing'),
              
              const Divider(height: 20),
              // END NEW UI BLOCK
              
              
              const SizedBox(height: 12),
              Text(
                'Total: RM ${booking['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: AppColors.accentColor,
                ),
              ),
              
              const Divider(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
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
                  if (faceVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.face_retouching_natural, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Registered',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateBookingStatus(bookingId, 'confirmed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ] else if (isReadyForPickup) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _verifyFaceForPickup(bookingId);
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Verify & Hand Over'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ] else if (isReadyForReturn) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _verifyFaceForReturn(bookingId);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Verify & Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Debug Information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('RenterId: ${widget.renterId}'),
          Text('Filter: $_filterStatus'),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Expected Firestore Structure:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const Text(
            '• Collection: "bookings"\n'
            '• Field: "renterId" (must match above)\n'
            '• Field: "status" (pending/confirmed/etc)\n'
            '• Field: "timestamp" (Timestamp)',
            style: TextStyle(fontSize: 11),
          ),
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
        title: const Text('Booking Requests'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _checkFirestoreConnection();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Show debug info if there's an error
          if (_errorMessage != null) _buildDebugInfo(),

          // Filter chips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Confirmed', 'confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ongoing', 'ongoing'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: _isLoading
                ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accentColor),
                    )
                : StreamBuilder<QuerySnapshot>(
                      stream: _getBookingsStream(),
                      builder: (context, snapshot) {
                        // Debug logging
                        if (snapshot.connectionState == ConnectionState.active) {
                          print('📊 Stream active - docs count: ${snapshot.data?.docs.length ?? 0}');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.accentColor),
                          );
                        }

                        if (snapshot.hasError) {
                          print('❌ Stream error: ${snapshot.error}');
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading bookings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${_filterStatus == 'all' ? '' : _filterStatus} booking requests',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check that bookings have renterId: ${widget.renterId}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
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

                        // Sort by timestamp manually (since we can't use orderBy without index)
                        bookings.sort((a, b) {
                          final aTime = a['timestamp'];
                          final bTime = b['timestamp'];
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;
                          final aDate = aTime is Timestamp ? aTime.toDate() : DateTime.now();
                          final bDate = bTime is Timestamp ? bTime.toDate() : DateTime.now();
                          return bDate.compareTo(aDate); // descending order
                        });

                        print('✅ Displaying ${bookings.length} bookings');

                        return RefreshIndicator(
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              final status = booking['status'] ?? 'pending';
                              final imageData = booking['itemImage'];
                              final faceVerified = booking['faceVerified'] ?? false;
                              final isOngoing = status == 'ongoing';
                              final isConfirmed = status == 'confirmed';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightCardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isConfirmed || isOngoing 
                                        ? _getStatusColor(status).withOpacity(0.5) 
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
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
                                                      child: const Icon(Icons.broken_image),
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
                                                      child: const Icon(Icons.broken_image),
                                                    );
                                                  },
                                                ))
                                        : Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image),
                                            ),
                                  ),
                                  title: Text(
                                    booking['itemName'] ?? 'Unknown Item',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Rentee: ${booking['userName'] ?? 'N/A'}'),
                                      Text('${_formatDate(booking['startDate'])} - ${_formatDate(booking['endDate'])}'),
                                      Text(
                                        'RM ${booking['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                        style: const TextStyle(
                                          color: AppColors.accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                          if (faceVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.face_retouching_natural, 
                                                color: Colors.green, size: 16),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    isConfirmed ? Icons.face_retouching_natural : Icons.chevron_right,
                                    color: isConfirmed ? Colors.purple : Colors.grey,
                                  ),
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