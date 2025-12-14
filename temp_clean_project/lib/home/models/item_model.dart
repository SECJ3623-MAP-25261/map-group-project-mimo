// features/home/models/item_model.dart

class ItemModel {
  final String id;
  final String name;
  final double pricePerDay;
  final String category;
  final List<dynamic> images;
  final String description;
  final String size;
  final String? renterId;
  final String? renterName;
  final bool? availability; // ✅ ADD THIS
  final DateTime? createdAt;  // ✅ ADD THIS

  ItemModel({
    required this.id,
    required this.name,
    required this.pricePerDay,
    required this.category,
    required this.images,
    this.description = '',
    this.size = '',
    this.renterId,
    this.renterName,
    this.availability,      // ✅ ADD THIS
    this.createdAt,         // ✅ ADD THIS
  });

  // ✅ NEW: Getter for ownerId (ItemDetailScreen uses this)
  String? get ownerId => renterId;

  factory ItemModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return ItemModel(
      id: docId,
      name: data['name'] ?? 'Unnamed Item',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      category: data['category'] ?? 'Other',
      images: data['images'] ?? [],
      description: data['description'] ?? '',
      size: data['size'] ?? '',
      renterId: data['renterId'],
      renterName: data['renterName'],
      availability: data['availability'] ?? true,  // ✅ ADD THIS
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as dynamic).toDate() 
          : null,  // ✅ ADD THIS
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pricePerDay': pricePerDay,
      'category': category,
      'images': images,
      'description': description,
      'size': size,
      'renterId': renterId,
      'renterName': renterName,
      'availability': availability ?? true,  // ✅ ADD THIS
      'createdAt': createdAt,                // ✅ ADD THIS
    };
  }

  // ✅ NEW: Safe conversion to Map for ItemDetailScreen
  Map<String, dynamic> toDetailMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'pricePerDay': pricePerDay,
      'description': description,
      'size': size,
      'images': images,
      'ownerId': renterId ?? '',  // ItemDetailScreen uses 'ownerId'
      'renterId': renterId,       // Keep both for compatibility
      'renterName': renterName,
      'availability': availability ?? true,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name, category: $category, renterId: $renterId)';
  }
}