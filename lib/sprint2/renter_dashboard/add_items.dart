// lib/sprint2/ManageItems/add_items.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../constants/app_colors.dart';
import '../../sprint4/offline_support.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  final ImagePicker picker = ImagePicker();
  List<File> images = [];
  bool _isSubmitting = false;
  bool _isOnline = true;

  final List<String> categories = [
    'Shirt',
    'Pants',
    'Dress',
    'Jacket',
    'Traditional Wear',
    'Sportswear',
    'Formal',
    'Accessories',
    'Presentation',
    'Convocation',
    'Dinner',
    'Other',
  ];

  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Free Size'];

  String? selectedCategory;
  String? selectedSize;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo (Camera)"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose From Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImagesFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImagesFromGallery() async {
    final picked = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission denied")),
      );
      return;
    }

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        images.add(File(photo.path));
      });
    }
  }

  Future<void> _onPhotoLongPress(int index) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text("Set as cover photo"),
              subtitle: const Text("Cover photo will be the first image"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  final img = images.removeAt(index);
                  images.insert(0, img);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Replace using camera"),
              onTap: () async {
                Navigator.pop(context);
                await _replaceWithCamera(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete photo"),
              onTap: () {
                Navigator.pop(context);
                _removeImage(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replaceWithCamera(int index) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission denied")),
      );
      return;
    }

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        images[index] = File(photo.path);
      });
    }
  }

  Future<List<String>> convertImagesToBase64() async {
    List<String> base64Images = [];

    for (File imageFile in images) {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        base64Images.add(base64String);
      } catch (e) {
        print('Error converting image to base64: $e');
      }
    }

    return base64Images;
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null || selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select category and size")),
      );
      return;
    }

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final renterId = FirebaseAuth.instance.currentUser!.uid;
      final userEmail = FirebaseAuth.instance.currentUser!.email ?? 'unknown@email.com';

      // Get user name from Firestore (skip if offline)
      String renterName = 'Unknown User';
      if (_isOnline) {
        try {
          final userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(renterId)
              .get();
          renterName = userData.data()?['fullName'] ?? userEmail.split('@')[0];
        } catch (e) {
          renterName = userEmail.split('@')[0];
        }
      } else {
        renterName = userEmail.split('@')[0];
      }

      print('Converting images to base64...');
      List<String> base64Images = await convertImagesToBase64();

      final itemData = {
        "name": nameCtrl.text.trim(),
        "category": selectedCategory,
        "size": selectedSize,
        "pricePerDay": double.parse(priceCtrl.text),
        "description": descriptionCtrl.text.trim(),
        "renterId": renterId,
        "renterEmail": userEmail,
        "renterName": renterName,
        "images": base64Images,
        "createdAt": DateTime.now().toIso8601String(),
        "updatedAt": DateTime.now().toIso8601String(),
      };

      final offlineSupport = Provider.of<OfflineSupport>(context, listen: false);

      if (!_isOnline) {
        // Save offline
        print('Saving item offline...');
        final success = await offlineSupport.addItemOffline(itemData);
        
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Item saved offline. Will sync when online.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save item offline'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Save online
        print('Saving item to Firestore...');
        await FirebaseFirestore.instance.collection("items").add({
          ...itemData,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Item added successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print("UPLOAD ERROR: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offlineSupport = Provider.of<OfflineSupport>(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Add Item"),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.cloud_done : Icons.cloud_off,
                    size: 20,
                    color: _isOnline ? Colors.white : Colors.orange,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOnline ? Colors.white : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner with pending items
          if (!_isOnline || offlineSupport.pendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: !_isOnline ? Colors.orange.shade100 : Colors.blue.shade100,
              child: Row(
                children: [
                  Icon(
                    !_isOnline ? Icons.cloud_off : Icons.sync,
                    color: !_isOnline ? Colors.orange.shade800 : Colors.blue.shade800,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !_isOnline
                          ? 'Offline mode: Items will sync when online'
                          : '${offlineSupport.pendingCount} item(s) pending sync',
                      style: TextStyle(
                        color: !_isOnline ? Colors.orange.shade900 : Colors.blue.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isOnline && offlineSupport.pendingCount > 0)
                    TextButton(
                      onPressed: () async {
                        final result = await offlineSupport.syncPendingItems();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: result['success'] ? Colors.green : Colors.red,
                          ),
                        );
                      },
                      child: Text(
                        'Sync Now',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.lightCardBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: "Item Name",
                              prefixIcon: Icon(Icons.shopping_bag),
                            ),
                            validator: (v) => v!.isEmpty ? "Enter item name" : null,
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Category",
                              prefixIcon: Icon(Icons.category),
                            ),
                            value: selectedCategory,
                            items: categories
                                .map((cat) =>
                                    DropdownMenuItem(value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (value) => setState(() {
                              selectedCategory = value;
                            }),
                            validator: (v) => v == null ? "Select a category" : null,
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Size",
                              prefixIcon: Icon(Icons.straighten),
                            ),
                            value: selectedSize,
                            items: sizes
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (value) => setState(() {
                              selectedSize = value;
                            }),
                            validator: (v) => v == null ? "Select a size" : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Price per day (RM)",
                              prefixIcon: Icon(Icons.payments_rounded),
                            ),
                            validator: (v) => v!.isEmpty ? "Enter price" : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: descriptionCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Description",
                              prefixIcon: Icon(Icons.description),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Item Photos (Required)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final img = entry.value;
                        
                        return Dismissible(
                          key: ValueKey(img.path),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 12),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          secondaryBackground: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 12),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (_) => _removeImage(index),
                          child: GestureDetector(
                            onLongPress: () => _onPhotoLongPress(index),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    img,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                if (index == 0)
                                  Positioned(
                                    left: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "Cover",
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  ),

                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_a_photo, size: 30),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isOnline ? "Add Item" : "Save Offline",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                if (!_isOnline) ...[
                                  SizedBox(width: 8),
                                  Icon(Icons.cloud_off, size: 18),
                                ],
                              ],
                            ),
                    ),
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