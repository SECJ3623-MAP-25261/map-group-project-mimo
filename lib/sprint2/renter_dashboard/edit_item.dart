// lib/sprint2/ManageItems/edit_items.dart

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';

class EditItemPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const EditItemPage({super.key, required this.itemId, required this.itemData});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController priceCtrl;

  final ImagePicker picker = ImagePicker();
  List<File> newImages = []; // New images to add
  List<String> existingBase64Images = []; // Existing base64 images
  bool _isSubmitting = false;

  final List<String> categories = [
    'Shirt',
    'Pants',
    'Dress',
    'Jacket',
    'Traditional Wear',
    'Sportswear',
    'Formal',
    'Accessories',
    'Other',
  ];

  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Free Size'];

  String? selectedCategory;
  String? selectedSize;

  @override
  void initState() {
    super.initState();

    // Fill initial data
    nameCtrl = TextEditingController(text: widget.itemData["name"]);
    descriptionCtrl = TextEditingController(
      text: widget.itemData["description"],
    );
    priceCtrl = TextEditingController(
      text: widget.itemData["pricePerDay"].toString(),
    );

    selectedCategory = widget.itemData["category"];
    selectedSize = widget.itemData["size"];

    // Load existing base64 images
    existingBase64Images = List<String>.from(widget.itemData["images"] ?? []);
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
      newImages.addAll(picked.map((x) => File(x.path)));
    });
  }
}

Future<void> _pickImageFromCamera() async {
  // Request camera permission (important on Android)
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
    preferredCameraDevice: CameraDevice.rear, // good for product photos
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 70,
  );

  if (photo != null) {
    setState(() {
      newImages.add(File(photo.path));
    });
  }
}

Future<void> _onExistingPhotoLongPress(int index) async {
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
                final img = existingBase64Images.removeAt(index);
                existingBase64Images.insert(0, img);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Delete photo"),
            onTap: () {
              Navigator.pop(context);
              _removeExistingImage(index);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _onNewPhotoLongPress(int index) async {
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
                final img = newImages.removeAt(index);
                newImages.insert(0, img);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Replace using camera"),
            onTap: () async {
              Navigator.pop(context);
              await _replaceNewWithCamera(index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Delete photo"),
            onTap: () {
              Navigator.pop(context);
              _removeNewImage(index);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _replaceNewWithCamera(int index) async {
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
      newImages[index] = File(photo.path);
    });
  }
}


  Future<List<String>> convertNewImagesToBase64() async {
    List<String> base64Images = [];

    for (File imageFile in newImages) {
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

  void _removeExistingImage(int index) {
    setState(() {
      existingBase64Images.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (existingBase64Images.isEmpty && newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert new images to base64
      List<String> newBase64Images = [];
      if (newImages.isNotEmpty) {
        newBase64Images = await convertNewImagesToBase64();
      }

      // Merge existing + new images
      final finalImages = [...existingBase64Images, ...newBase64Images];

      print('Updating item in Firestore...');
      await FirebaseFirestore.instance
          .collection("items")
          .doc(widget.itemId)
          .update({
        "name": nameCtrl.text.trim(),
        "category": selectedCategory,
        "size": selectedSize,
        "pricePerDay": double.parse(priceCtrl.text),
        "description": descriptionCtrl.text.trim(),
        "images": finalImages,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("UPDATE ERROR: $e");
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update Failed: $e")),
      );
      setState(() => _isSubmitting = false);
    }
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
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Edit Item"),
      ),
      body: SingleChildScrollView(
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
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v),
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
                      onChanged: (v) => setState(() => selectedSize = v),
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
                "Item Photos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Existing base64 images
                ...existingBase64Images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final base64 = entry.value;
                  
                  return Dismissible(
                    key: ValueKey("existing_$index"),
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
                    onDismissed: (_) => _removeExistingImage(index),
                    child: GestureDetector(
                      onLongPress: () => _onExistingPhotoLongPress(index),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(base64),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
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
                              onPressed: () => _removeExistingImage(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                }),
                
                // New images (from gallery)
                ...newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final img = entry.value;
                  
                  return Dismissible(
                    key: ValueKey("new_${img.path}"),
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
                    onDismissed: (_) => _removeNewImage(index),
                    child: GestureDetector(
                      onLongPress: () => _onNewPhotoLongPress(index),
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

                          Positioned(
                            top: -5,
                            right: -5,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _removeNewImage(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                }),
                
                // Add photo button
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
                onPressed: _isSubmitting ? null : saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
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
                    : const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}