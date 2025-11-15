import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart'; // ✅ Your color system

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ✅ No hardcoded colors — all from AppColors
  bool _isEmailEnabled = true;
  bool _isPushEnabled = true;

  bool _orderUpdates = true;
  bool _newMessages = true;
  bool _promotions = false;
  bool _systemAlerts = true;

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Notification settings saved successfully!"),
        backgroundColor: AppColors.accentColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground, // ✅ Light gray background
      appBar: AppBar(
        title: const Text(
          "Manage Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextColor, // dark text
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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

          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text(
              "Save Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.accentColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground, // ✅ white card
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: AppColors.lightTextColor, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: AppColors.lightHintColor, fontSize: 12))
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentColor,
        inactiveThumbColor: AppColors.lightBorderColor.withOpacity(0.6),
        inactiveTrackColor: AppColors.lightBorderColor.withOpacity(0.3),
        tileColor: Colors.transparent,
      ),
    );
  }

  Widget _buildCategorySwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isEnabled,
  }) {
    final textColor = isEnabled ? AppColors.lightTextColor : AppColors.lightHintColor;
    final iconColor = isEnabled ? AppColors.accentColor : AppColors.lightHintColor.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        value: value,
        onChanged: isEnabled ? onChanged : null,
        activeColor: AppColors.accentColor,
        inactiveThumbColor: AppColors.lightBorderColor.withOpacity(0.6),
        inactiveTrackColor: AppColors.lightBorderColor.withOpacity(0.3),
        tileColor: Colors.transparent,
      ),
    );
  }
}