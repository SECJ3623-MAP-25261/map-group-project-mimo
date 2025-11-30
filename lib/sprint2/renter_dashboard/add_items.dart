import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../../../constants/app_colors.dart';

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
  List<XFile> images = [];

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
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked);
      });
    }
  }

  Future<List<String>> uploadImages(String itemId) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final file = File(images[i].path);

      final ref = FirebaseStorage.instance.ref().child(
        "items/$itemId/image_$i.jpg",
      );

      UploadTask uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() {});

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null || selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select category and size")),
      );
      return;
    }

    try {
      final renterId = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance.collection("items").doc();

      // 🟢 IMAGE OPTIONAL: only upload if images exist
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await uploadImages(docRef.id);
      }

      await docRef.set({
        "name": nameCtrl.text.trim(),
        "category": selectedCategory,
        "size": selectedSize,
        "pricePerDay": double.parse(priceCtrl.text),
        "description": descriptionCtrl.text.trim(),
        "renterId": renterId,
        "images": imageUrls, // empty [] if no images
        "createdAt": DateTime.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      print("UPLOAD ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextColor,
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
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
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
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
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
                "Item Photos (Optional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...images.map(
                  (img) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(img.path),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                onPressed: saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
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
