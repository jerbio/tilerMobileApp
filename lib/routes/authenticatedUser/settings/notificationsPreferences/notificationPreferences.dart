import 'package:flutter/material.dart';

class NotificationPreferences extends StatefulWidget {
  static final String routeName = '/notificationsPreferences';
  const NotificationPreferences({super.key});

  @override
  State<NotificationPreferences> createState() => _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<NotificationPreferences> {
  bool tileReminders = true;
  bool appUpdates = true;
  bool marketingUpdates = false;
  bool emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notification Preferences"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.notifications, "Push Notifications"),
            _buildToggle("Tile Reminders", tileReminders, (value) {
              setState(() => tileReminders = value);
            }),
            _buildToggle("App Updates", appUpdates, (value) {
              setState(() => appUpdates = value);
            }),
            _buildToggle("Marketing Updates", marketingUpdates, (value) {
              setState(() => marketingUpdates = value);
            }),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.email, "Emails"),
            _buildToggle("Email notifications", emailNotifications, (value) {
              setState(() => emailNotifications = value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildToggle(String text, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(text, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }
}
