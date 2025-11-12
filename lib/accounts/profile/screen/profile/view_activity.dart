import 'package:flutter/material.dart';

class ViewActivityPage extends StatelessWidget {
  const ViewActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      "You listed 'Blue Hoodie' for rent",
      "You updated your profile picture",
      "You changed your password",
      "You received a new message",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text("Activity Log"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: activities.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.history, color: Colors.white70),
          title: Text(activities[index],
              style: const TextStyle(color: Colors.white70)),
        ),
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.white24, thickness: 0.5),
      ),
    );
  }
}
