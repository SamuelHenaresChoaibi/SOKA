import 'package:flutter/material.dart';
import 'package:soka/screens/login_screen.dart';
import 'package:soka/services/auth_gate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Page')),
      body: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle, size: 40),
              title: const Text("Username"),
              subtitle: const Text("correo@gmail.com"),

              onTap: () {
                // Navigate to account settings page
              },
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Account"),
                  subtitle: const Text("Manage your account settings"),

                  onTap: () {
                    // TODO: Implement account settings navigation
                  },
                ),
                Divider(),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Privacy"),
                  subtitle: const Text("Manage your privacy settings"),
                  onTap: () {
                    // TODO: Implement privacy settings navigation
                  },
                ),
                Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notifications"),
                  subtitle: const Text("Manage your notification settings"),
                  onTap: () {
                    // TODO: Implement notification settings navigation
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Help & Support"),
              subtitle: const Text("Get help and support"),
              onTap: () {
                //TODO: Implement help and support navigation
              },
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              subtitle: const Text("Sign out of your account"),
              onTap: () async {
                await AuthGate().signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
        ],
      ),
    );
  }
}
