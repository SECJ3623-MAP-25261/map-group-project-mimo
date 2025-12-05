// lib/services/item_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ItemModel>> getItemsStream({String? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection('items');

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            try {
              return ItemModel.fromFirestore(doc.id, data);
            } catch (e) {
              print('Failed to parse item ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ItemModel>()
          .toList();
    });
  }

  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      return ItemModel.fromFirestore(doc.id, data);
    } catch (e) {
      print('Error fetching item $itemId: $e');
      return null;
    }
  }

  Future<void> addItem(ItemModel item) async {
    try {
      await _firestore.collection('items').add(item.toMap());
    } catch (e) {
      throw Exception('Failed to add item. Please try again.');
    }
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('items').doc(itemId).update(updates);
    } catch (e) {
      throw Exception('Failed to update item. Please try again.');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item. Please try again.');
    }
  }

  Stream<List<ItemModel>> searchItems(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    return _firestore
        .collection('items')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            try {
              final item = ItemModel.fromFirestore(doc.id, data);
              final matches = item.name.toLowerCase().contains(normalizedQuery) ||
                  item.category.toLowerCase().contains(normalizedQuery) ||
                  (item.description?.toLowerCase().contains(normalizedQuery) ?? false);
              return matches ? item : null;
            } catch (e) {
              print('Error parsing item during search ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ItemModel>()
          .toList();
    });
  }
}