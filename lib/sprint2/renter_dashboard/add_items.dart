// lib/sprint2/ManageItems/add_items.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';

import '../../constants/app_colors.dart';

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

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((xfile) => File(xfile.path)));
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

      // Get user name from Firestore
      String renterName = 'Unknown User';
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(renterId)
            .get();
        renterName = userData.data()?['fullName'] ?? userEmail.split('@')[0];
      } catch (e) {
        renterName = userEmail.split('@')[0];
      }

      print('Converting images to base64...');
      // Convert images to base64
      List<String> base64Images = await convertImagesToBase64();
      
      print('Saving item to Firestore...');
      // Save to Firestore
      await FirebaseFirestore.instance.collection("items").add({
        "name": nameCtrl.text.trim(),
        "category": selectedCategory,
        "size": selectedSize,
        "pricePerDay": double.parse(priceCtrl.text),
        "description": descriptionCtrl.text.trim(),
        "renterId": renterId,
        "renterEmail": userEmail,
        "renterName": renterName,
        "images": base64Images, // Store as base64 strings
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("UPLOAD ERROR: $e");
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Failed: $e")),
      );
      setState(() => _isSubmitting = false);
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
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Add Item"),
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
                  
                  return Stack(
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
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: pickImages,
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
                    : const Text(
                        "Add Item",
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