import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/auth_gate.dart';
import 'package:soka/services/services.dart';
import 'package:soka/screens/account_settings_screen.dart';
import 'package:soka/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final User? _user;
  late final Future<Client?> _clientFuture;
  late final Future<Company?> _companyFuture;
  bool _shareProfile = true;
  bool _showEmail = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _clientFuture = _user == null
        ? Future.value(null)
        : context.read<SokaService>().fetchClientById(_user.uid);
    _companyFuture = _user == null
        ? Future.value(null)
        : context.read<SokaService>().fetchCompanyById(_user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 72),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Manage your account and preferences',
                        style: TextStyle(
                          color: Color(0xFFDDE4F2),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -36,
                  child: _profileCard(context),
                ),
              ],
            ),
            const SizedBox(height: 56),
            _settingsSections(context),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait<dynamic>([_clientFuture, _companyFuture]),
          builder: (context, snapshot) {
            final Client? client =
                snapshot.data != null ? snapshot.data![0] as Client? : null;
            final Company? company =
                snapshot.data != null ? snapshot.data![1] as Company? : null;

            final displayName = company?.companyName ??
                client?.userName ??
                _user?.displayName ??
                'Usuario';
            final email = _user?.email ?? client?.email ?? 'Sin correo';
            final userType = company != null ? 'Empresa' : 'Usuario';
            final initials = (displayName.isNotEmpty)
                ? displayName.trim().substring(0, 1).toUpperCase()
                : 'U';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2B45),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Cargando...'
                            : displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B2437),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Cargando...'
                            : email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5F6C87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.connectionState == ConnectionState.waiting
                                ? 'Cargando...'
                                : '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F6C87),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF3FA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? '...'
                                  : userType,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E2B45),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _settingsSections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Account"),
                  subtitle: const Text("Manage your account settings"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Privacy"),
                  subtitle: const Text("Manage your privacy settings"),
                  onTap: () {
                    _showPrivacySheet(context);
                  },
                ),
                const Divider(height: 1),
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
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Help & Support"),
              subtitle: const Text("Get help and support"),
              onTap: () {
                //TODO: Implement help and support navigation
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share my profile'),
                    subtitle: const Text('Allow others to see your public profile'),
                    value: _shareProfile,
                    onChanged: (value) {
                      setModalState(() => _shareProfile = value);
                      setState(() => _shareProfile = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show my email'),
                    subtitle: const Text('Display email on my public profile'),
                    value: _showEmail,
                    onChanged: (value) {
                      setModalState(() => _showEmail = value);
                      setState(() => _showEmail = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy settings updated'),
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
