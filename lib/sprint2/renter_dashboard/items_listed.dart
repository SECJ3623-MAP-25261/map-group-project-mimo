import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../constants/app_colors.dart';

class YourItemsPage extends StatefulWidget {
  final String renterId;

  const YourItemsPage({super.key, required this.renterId});

  @override
  State<YourItemsPage> createState() => _YourItemsPageState();
}

class _YourItemsPageState extends State<YourItemsPage> {
  Stream<QuerySnapshot> getItems() {
    return FirebaseFirestore.instance
        .collection('items')
        .where('renterId', isEqualTo: widget.renterId)
        .snapshots();
  }

  Future<void> deleteItem(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // Delete images in storage
    if (data["images"] != null && (data["images"] as List).isNotEmpty) {
      for (String url in List<String>.from(data["images"])) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          print("IMAGE DELETE ERROR: $e");
        }
      }
    }

    // Delete Firestore doc
    await FirebaseFirestore.instance.collection('items').doc(doc.id).delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item deleted")));
  }

  void confirmDelete(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Delete item?"),
          content: const Text(
            "Are you sure you want to permanently delete this item?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await deleteItem(doc);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextColor,
        title: const Text("Your Items"),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Total Items Listed: ${docs.length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (docs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No items listed yet.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final imageUrl =
                          (data["images"] != null &&
                              (data["images"] as List).isNotEmpty)
                          ? (data["images"] as List).first
                          : null;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightCardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                          ),
                          title: Text(
                            data["name"] ?? "Unnamed Item",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "RM ${data["pricePerDay"]}/day",
                            style: TextStyle(
                              color: AppColors.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /// ✅ FIXED EDIT BUTTON (ONLY CHANGE)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditItemPage(
                                        docId: docs[index].id,
                                        itemData: data,
                                      ),
                                    ),
                                  );
                                  setState(() {}); // 🔥 Refresh after editing
                                },
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => confirmDelete(docs[index]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// EDIT ITEM PAGE
class EditItemPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> itemData;

  const EditItemPage({super.key, required this.docId, required this.itemData});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController priceCtrl;

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
    final data = widget.itemData;

    nameCtrl = TextEditingController(text: data["name"]);
    descriptionCtrl = TextEditingController(text: data["description"]);
    priceCtrl = TextEditingController(text: data["pricePerDay"].toString());

    selectedCategory = data["category"];
    selectedSize = data["size"];
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.docId)
        .update({
          "name": nameCtrl.text.trim(),
          "description": descriptionCtrl.text.trim(),
          "pricePerDay": int.tryParse(priceCtrl.text.trim()) ?? 0,
          "category": selectedCategory,
          "size": selectedSize,
        });

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item updated")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Edit Item"),
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? "Enter item name" : null,
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
                      onChanged: (v) => setState(() => selectedSize = v),
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
                      validator: (v) =>
                          v!.trim().isEmpty ? "Enter price" : null,
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

              const SizedBox(height: 25),

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
                    elevation: 0,
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
      ),
    );
  }
}
