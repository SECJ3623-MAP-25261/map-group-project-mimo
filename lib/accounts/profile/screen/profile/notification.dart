import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Define a vibrant accent color for the dark theme, consistent with other screens
  static const Color _accentColor = Color(0xFF3B82F6); // Professional Blue
  static const Color _cardColor = Color(0xFF374151); // Input/Card background
  static const Color _textColor = Colors.white;
  static const Color _subtitleColor = Colors.white70;

  // Global control switches
  bool _isEmailEnabled = true;
  bool _isPushEnabled = true;

  // Specific Push Notification Categories
  bool _orderUpdates = true;
  bool _newMessages = true;
  bool _promotions = false;
  bool _systemAlerts = true;

  void _saveSettings() {
    // In a real application, you would save these booleans to a persistent storage (e.g., database or SharedPreferences).

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Notification settings saved successfully!"),
        backgroundColor: _accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        title: const Text(
          "Manage Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // === Global Controls Section ===
          _buildSectionHeader("Delivery Methods"),
          _buildSwitchListTile(
            title: "Email Notifications",
            value: _isEmailEnabled,
            onChanged: (val) => setState(() => _isEmailEnabled = val),
            subtitle: "Receive alerts and updates via your email address.",
          ),
          _buildSwitchListTile(
            title: "Push Notifications",
            value: _isPushEnabled,
            onChanged: (val) {
              setState(() {
                _isPushEnabled = val;
                // If globally disabled, disable all sub-settings instantly
                if (!val) {
                  _orderUpdates = false;
                  _newMessages = false;
                  _promotions = false;
                }
              });
            },
            subtitle: "Receive instant alerts on your mobile device.",
          ),

          const SizedBox(height: 30),

          // === Specific Categories Section ===
          _buildSectionHeader("Push Notification Categories"),
          
          // Note: These switches are only enabled if _isPushEnabled is true
          _buildCategorySwitch(
            title: "Order Updates (Required)",
            value: _orderUpdates,
            onChanged: (val) => setState(() => _orderUpdates = val),
            icon: Icons.shopping_bag_outlined,
            isEnabled: _isPushEnabled,
          ),
          _buildCategorySwitch(
            title: "New Messages",
            value: _newMessages,
            onChanged: (val) => setState(() => _newMessages = val),
            icon: Icons.chat_bubble_outline,
            isEnabled: _isPushEnabled,
          ),
          _buildCategorySwitch(
            title: "Promotional & Marketing",
            value: _promotions,
            onChanged: (val) => setState(() => _promotions = val),
            icon: Icons.campaign_outlined,
            isEnabled: _isPushEnabled,
          ),
          _buildCategorySwitch(
            title: "System Alerts (Crucial)",
            value: _systemAlerts,
            onChanged: (val) => setState(() => _systemAlerts = val),
            icon: Icons.error_outline,
            isEnabled: _isPushEnabled,
          ),

          const SizedBox(height: 40),

          // === Save Button ===
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text(
              "Save Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: _textColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display a title for a section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          color: _accentColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Base switch tile for global controls
  Widget _buildSwitchListTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: _subtitleColor, fontSize: 12)) : null,
        value: value,
        onChanged: onChanged,
        activeColor: _accentColor,
        inactiveThumbColor: Colors.white30,
        tileColor: Colors.transparent, // Use container color
      ),
    );
  }

  // Switch tile with icon for specific categories
  Widget _buildCategorySwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isEnabled,
  }) {
    // Determine the color based on whether the whole category is enabled
    final itemColor = isEnabled ? _textColor : _subtitleColor;
    final iconColor = isEnabled ? _accentColor : Colors.white30;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(color: itemColor, fontWeight: FontWeight.w500),
        ),
        value: value,
        onChanged: isEnabled ? onChanged : null, // Disable if global push is off
        activeColor: _accentColor,
        inactiveThumbColor: Colors.white30,
        inactiveTrackColor: Colors.white12,
        tileColor: Colors.transparent,
      ),
    );
  }
}