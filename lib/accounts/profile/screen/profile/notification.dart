import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool emailNotif = true;
  bool pushNotif = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text("Manage Notifications"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text("Email Notifications", style: TextStyle(color: Colors.white70)),
            value: emailNotif,
            onChanged: (val) => setState(() => emailNotif = val),
            activeThumbColor: Colors.blueAccent,
          ),
          SwitchListTile(
            title: const Text("Push Notifications", style: TextStyle(color: Colors.white70)),
            value: pushNotif,
            onChanged: (val) => setState(() => pushNotif = val),
            activeThumbColor: Colors.blueAccent,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notification settings updated")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}
