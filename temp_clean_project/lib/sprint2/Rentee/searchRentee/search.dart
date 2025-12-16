import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Booking Rentee/booking.dart';
import '../../../sprint3/compare_item/compare_screen.dart';

class SearchPage extends StatefulWidget {
  final Map<String, dynamic>? preSelectedItem;
  final bool startCompareMode;

  const SearchPage({
    super.key,
    this.preSelectedItem,
    this.startCompareMode = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = "";

  bool compareMode = false;
  List<Map<String, dynamic>> compareItems = [];

  @override
  void initState() {
    super.initState();

    // ✅ AUTO ENTER COMPARE MODE WITH 1 ITEM
    if (widget.startCompareMode && widget.preSelectedItem != null) {
      compareMode = true;
      compareItems.add(widget.preSelectedItem!);
    }
  }

  // 🔁 TOGGLE SELECT / REMOVE
  void _handleCompareSelect(Map<String, dynamic> data) {
    final index = compareItems.indexWhere((e) => e['id'] == data['id']);

    // ✅ If already selected → remove it
    if (index != -1) {
      setState(() => compareItems.removeAt(index));
      return;
    }

    // ✅ Add if less than 2
    if (compareItems.length < 2) {
      setState(() => compareItems.add(data));
    } else {
      _showReplaceDialog(data);
    }
  }

  void _showReplaceDialog(Map<String, dynamic> newItem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Replace item"),
        content: const Text("Which item do you want to remove?"),
        actions: List.generate(compareItems.length, (index) {
          return TextButton(
            onPressed: () {
              setState(() {
                compareItems[index] = newItem;
              });
              Navigator.pop(context);
            },
            child: Text(compareItems[index]['name']),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          compareMode ? "Select 2 Items" : "Search Items",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (compareMode)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.close),
              label: const Text("Cancel"),
              onPressed: () {
                setState(() {
                  compareMode = false;
                  compareItems.clear();
                });
              },
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.compare),
              label: const Text("Compare"),
              onPressed: () => setState(() => compareMode = true),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search for items...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => query = value);
              },
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("items")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filtered = snapshot.data!.docs.where((doc) {
                    final name = doc["name"].toString().toLowerCase();
                    return name.contains(query.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final data = item.data() as Map<String, dynamic>;
                      data['id'] = item.id;

                      final selected = compareItems.any(
                        (e) => e['id'] == data['id'],
                      );

                      return Card(
                        child: ListTile(
                          title: Text(data['name']),
                          subtitle: Text(data['category'] ?? ""),
                          leading: compareMode
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) => _handleCompareSelect(data),
                                )
                              : null,
                          trailing: !compareMode
                              ? const Icon(Icons.arrow_forward_ios, size: 16)
                              : null,
                          onTap: () {
                            if (compareMode) {
                              _handleCompareSelect(data);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(itemData: data),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            if (compareMode && compareItems.length == 2)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.compare),
                    label: const Text("Compare"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompareScreen(items: compareItems),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
