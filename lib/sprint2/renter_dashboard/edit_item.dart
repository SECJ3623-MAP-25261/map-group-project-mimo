import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';

import '../../../../constants/app_colors.dart';

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
  List<XFile> newImages = []; // new images user selects
  List<String> existingImages = []; // existing URLs remain

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

    existingImages = List<String>.from(widget.itemData["images"] ?? []);
  }

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => newImages.addAll(picked));
    }
  }

  Future<List<String>> uploadNewImages() async {
    List<String> urls = [];

    for (int i = 0; i < newImages.length; i++) {
      final file = File(newImages[i].path);

      final ref = FirebaseStorage.instance.ref().child(
        "items/${widget.itemId}/new_$i.jpg",
      );

      UploadTask task = ref.putFile(file);
      await task.whenComplete(() {});

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Upload new images if any
      List<String> newUploadedUrls = [];
      if (newImages.isNotEmpty) {
        newUploadedUrls = await uploadNewImages();
      }

      // Merge existing + new images
      final finalImages = [...existingImages, ...newUploadedUrls];

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
          });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update Failed: $e")));
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
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
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
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
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

            Align(
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
                ...existingImages.map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                ...newImages.map(
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
                onPressed: saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
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
