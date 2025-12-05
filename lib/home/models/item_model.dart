// 4. features/home/models/item_model.dart


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
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pricePerDay': pricePerDay,
      'price': pricePerDay,
      'category': category,
      'images': images,
      'image': images.isNotEmpty ? images[0] : null,
      'description': description,
      'size': size,
      'renterId': renterId,
      'renterName': renterName,
    };
  }
}