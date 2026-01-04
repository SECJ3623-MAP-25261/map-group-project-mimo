// lib/services/offline_support.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineSupport extends ChangeNotifier {
  static const String _pendingItemsKey = 'pending_items';
  static const String _syncStatusKey = 'sync_status';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  List<Map<String, dynamic>> _pendingItems = [];
  bool _isSyncing = false;
  bool _isOnline = true;
  
  List<Map<String, dynamic>> get pendingItems => _pendingItems;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingCount => _pendingItems.length;

  OfflineSupport() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPendingItems();
    await _checkConnectivity();
    _listenToConnectivity();
  }

  // Load pending items from local storage
  Future<void> _loadPendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(_pendingItemsKey);
      
      if (itemsJson != null && itemsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(itemsJson);
        _pendingItems = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading pending items: $e');
    }
  }

  // Save pending items to local storage
  Future<void> _savePendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String itemsJson = jsonEncode(_pendingItems);
      await prefs.setString(_pendingItemsKey, itemsJson);
    } catch (e) {
      debugPrint('Error saving pending items: $e');
    }
  }

  // Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      
      if (_isOnline && _pendingItems.isNotEmpty) {
        await syncPendingItems();
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  // Listen for connectivity changes
  void _listenToConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) async {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      
      if (wasOffline && _isOnline && _pendingItems.isNotEmpty) {
        debugPrint('Connection restored. Syncing pending items...');
        await syncPendingItems();
      }
    });
  }

  // Add item to offline queue - now accepts Map<String, dynamic>
  Future<bool> addItemOffline(Map<String, dynamic> itemData) async {
    try {
      final itemMap = Map<String, dynamic>.from(itemData);
      itemMap['offlineTimestamp'] = DateTime.now().toIso8601String();
      itemMap['syncStatus'] = 'pending';
      
      _pendingItems.add(itemMap);
      await _savePendingItems();
      notifyListeners();
      
      debugPrint('Item added to offline queue: ${itemMap['name']}');
      return true;
    } catch (e) {
      debugPrint('Error adding item offline: $e');
      return false;
    }
  }

  // Sync all pending items to Firestore
  Future<Map<String, dynamic>> syncPendingItems() async {
    if (_isSyncing || _pendingItems.isEmpty || !_isOnline) {
      return {
        'success': false,
        'message': _isSyncing 
            ? 'Sync already in progress' 
            : _pendingItems.isEmpty 
                ? 'No items to sync' 
                : 'No internet connection',
        'synced': 0,
        'failed': 0,
      };
    }

    _isSyncing = true;
    notifyListeners();

    int syncedCount = 0;
    int failedCount = 0;
    List<Map<String, dynamic>> failedItems = [];

    try {
      for (var itemMap in List.from(_pendingItems)) {
        try {
          // Remove sync metadata before uploading
          final cleanMap = Map<String, dynamic>.from(itemMap);
          cleanMap.remove('offlineTimestamp');
          cleanMap.remove('syncStatus');
          
          // Convert string timestamps back to Firestore timestamps
          cleanMap['createdAt'] = FieldValue.serverTimestamp();
          cleanMap['updatedAt'] = FieldValue.serverTimestamp();
          
          // Add to Firestore
          await _firestore.collection('items').add(cleanMap);
          
          // Remove from pending list
          _pendingItems.remove(itemMap);
          syncedCount++;
          
          debugPrint('Successfully synced item: ${itemMap['name']}');
        } catch (e) {
          debugPrint('Failed to sync item: ${itemMap['name']} - $e');
          failedCount++;
          failedItems.add(itemMap);
        }
      }

      // Update pending items list (keep only failed items)
      _pendingItems = failedItems;
      await _savePendingItems();
      
    } catch (e) {
      debugPrint('Error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return {
      'success': syncedCount > 0,
      'message': syncedCount > 0 
          ? 'Synced $syncedCount item(s)' 
          : 'Failed to sync items',
      'synced': syncedCount,
      'failed': failedCount,
    };
  }

  // Remove a specific pending item
  Future<bool> removePendingItem(int index) async {
    try {
      if (index >= 0 && index < _pendingItems.length) {
        _pendingItems.removeAt(index);
        await _savePendingItems();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing pending item: $e');
      return false;
    }
  }

  // Clear all pending items
  Future<void> clearPendingItems() async {
    try {
      _pendingItems.clear();
      await _savePendingItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing pending items: $e');
    }
  }

  // Get sync status summary
  String getSyncStatusSummary() {
    if (_isSyncing) {
      return 'Syncing...';
    } else if (!_isOnline) {
      return 'Offline - ${_pendingItems.length} item(s) pending';
    } else if (_pendingItems.isEmpty) {
      return 'All synced';
    } else {
      return '${_pendingItems.length} item(s) pending sync';
    }
  }

  // Manual retry sync
  Future<Map<String, dynamic>> retrySyncItem(int index) async {
    if (index < 0 || index >= _pendingItems.length || !_isOnline) {
      return {
        'success': false,
        'message': 'Unable to sync item',
      };
    }

    try {
      final itemMap = _pendingItems[index];
      final cleanMap = Map<String, dynamic>.from(itemMap);
      cleanMap.remove('offlineTimestamp');
      cleanMap.remove('syncStatus');
      
      // Convert timestamps
      cleanMap['createdAt'] = FieldValue.serverTimestamp();
      cleanMap['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('items').add(cleanMap);
      
      _pendingItems.removeAt(index);
      await _savePendingItems();
      notifyListeners();
      
      return {
        'success': true,
        'message': 'Item synced successfully',
      };
    } catch (e) {
      debugPrint('Error retrying sync: $e');
      return {
        'success': false,
        'message': 'Failed to sync: $e',
      };
    }
  }

  // Check if device is online
  Future<bool> checkOnlineStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking online status: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}