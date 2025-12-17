
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  // Default center (can be set to a campus center or general area)
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869), // Example: Kuala Lumpur (Fallback)
    zoom: 14.0,
  );

  String _currentAddress = "Loading address...";
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Try to find the user's current location to center the map
    _determineInitialPosition();
  }

  // Helper function to check permissions and get location
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _determineInitialPosition() async {
    CameraPosition newCameraPosition = _kInitialPosition;
    try {
      final position = await _determinePosition();
      newCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.0,
      );
    } catch (e) {
      print('Location error: $e. Using default position.');
    }

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    await _updateAddress(newCameraPosition.target);
    
    setState(() {
      _isLoading = false;
    });
  }

  // Reverse Geocoding: Converts LatLng to a human-readable address
  Future<void> _updateAddress(LatLng position) async {
    setState(() {
      _isLoading = true;
      _selectedLocation = position;
    });
    try {
      // Use geocoding package to convert coordinates to an address
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      String address = placemarks.isNotEmpty
          ? "${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.subAdministrativeArea ?? ''}"
          : "Unknown Location";

      setState(() {
        // Clean up the address string
        _currentAddress = address.trim().isEmpty ? "Unnamed Location" : address;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Failed to fetch address";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Called when the map camera stops moving (user lifts their finger)
  void _onCameraIdle() async {
    final controller = await _controller.future;
    // Get the center of the visible map region (where the pin is pointing)
    final center = await controller.getVisibleRegion().then((bounds) => 
        LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        )
    );
    _updateAddress(center);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Meet Up Point")),
      body: Stack(
        children: <Widget>[
          // 1. Google Map Widget
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kInitialPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onCameraIdle: _onCameraIdle, // Update address when map stops moving
          ),

          // 2. Center Pin Icon (Image Overlaid on the map)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Offset for pin's height
              child: Icon(
                Icons.location_on, 
                color: Colors.red, 
                size: 48.0,
              ),
            ),
          ),
          
          // 3. Address and Confirmation Card (Bottom Overlay)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Pickup Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  // Display Current Pinned Address
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLoading ? "Fetching location..." : _currentAddress,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _isLoading
                          ? const SizedBox(
                              height: 16, 
                              width: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // Confirmation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // Pop with null
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _selectedLocation == null || _isLoading
                            ? null
                            : () {
                                // Return the selected data to the previous screen (BookingScreen)
                                Navigator.of(context).pop({
                                  'latitude': _selectedLocation!.latitude,
                                  'longitude': _selectedLocation!.longitude,
                                  'address': _currentAddress,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('CONFIRM LOCATION'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}