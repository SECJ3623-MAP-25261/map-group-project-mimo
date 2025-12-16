import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../home/screens/item_detail_screen.dart'; // Use ItemDetailScreen instead of BookingScreen
import '../../constants/app_colors.dart';

class CompareScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const CompareScreen({super.key, required this.items});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);

    // 🔒 Lock landscape only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 🔓 Restore all orientations when leaving compare screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _openItemDetail(Map<String, dynamic> item) async {
    // 🔓 Switch to portrait before navigating
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Navigate to ItemDetailScreen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );

    // 🔒 Lock landscape again when returning
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: const Text(
          'Compare Items',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, _items),
        ),
      ),
      body: Row(
        children: List.generate(_items.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _openItemDetail(_items[index]),
              child: SizedBox(
                height: screenHeight * 0.9,
                child: ItemDetailScreen(item: _items[index]),
              ),
            ),
          );
        }),
      ),
    );
  }
}
