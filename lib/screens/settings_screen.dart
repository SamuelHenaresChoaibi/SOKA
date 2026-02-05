import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/auth_gate.dart';
import 'package:soka/services/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final User? _user;
  late final Future<Client?> _clientFuture;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _clientFuture = _user == null
        ? Future.value(null)
        : context.read<SokaService>().fetchClientById(_user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Page')),
      body: Column(
        children: [
          Card(
            child: FutureBuilder<Client?>(
              future: _clientFuture,
              builder: (context, snapshot) {
                final client = snapshot.data;
                final name =
                    client?.userName ?? _user?.displayName ?? 'Usuario';
                final email = _user?.email ?? client?.email ?? 'Sin correo';

                return ListTile(
                  leading: const Icon(Icons.account_circle, size: 40),
                  title: Text(
                    snapshot.connectionState == ConnectionState.waiting
                        ? 'Cargando...'
                        : name,
                  ),
                  subtitle: Text(
                    snapshot.connectionState == ConnectionState.waiting
                        ? 'Cargando...'
                        : email,
                  ),
                  onTap: () {
                    // Navigate to account settings page
                  },
                );
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
