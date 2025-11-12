import 'package:flutter/material.dart';
import 'package:campus_closet/accounts/profile/screen/profile/profile.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Closet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
      ),
      home: const CampusClosetScreen(),
    );
  }
}

class CampusClosetScreen extends StatefulWidget {
  const CampusClosetScreen({super.key});

  @override
  State<CampusClosetScreen> createState() => _CampusClosetScreenState();
}

class _CampusClosetScreenState extends State<CampusClosetScreen> {
  String _activeFilter = 'all';
  final List<String> _filters = ['all', 'tops', 'bottoms', 'dresses', 'outerwear', 'shoes'];

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('List an Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: 'Item Name')),
            TextField(decoration: InputDecoration(labelText: 'Category')),
            TextField(decoration: InputDecoration(labelText: 'Price')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Closet'),
        actions: [
  IconButton(
    icon: const Icon(Icons.person),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  ProfileScreen()),
      );
    },
  ),
],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: EdgeInsets.only(left: 20, bottom: 8),
            child: Row(
              children: const [
                Icon(Icons.location_on, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text('Near You', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final label = _filters[index] == 'all' ? 'All' : _filters[index].substring(0, 1).toUpperCase() + _filters[index].substring(1);
                final isActive = _activeFilter == _filters[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                      foregroundColor: isActive ? Colors.white : const Color(0xFFCBD5E1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: isActive ? 6 : 0,
                    ),
                    onPressed: () => setState(() => _activeFilter = _filters[index]),
                    child: Text(label),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 4, color: Color(0xFF1E293B)),

          // Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  const Text('👕', style: TextStyle(fontSize: 64, color: Colors.grey)),
                  SizedBox(height: 16),
                  Text(
                    'No items found. Try a different filter!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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