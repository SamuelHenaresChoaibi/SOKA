import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late Future<Client?> _clientFuture;
  late Future<Company?> _companyFuture;
  bool _isUploadingPhoto = false;
  final TextEditingController _supportSubjectController =
      TextEditingController();
  final TextEditingController _supportMessageController =
      TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();

  @override
  void dispose() {
    _supportSubjectController.dispose();
    _supportMessageController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

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
            final data = snapshot.data;
            final Client? client = (data != null &&
                    data.isNotEmpty &&
                    data[0] is Client)
                ? data[0] as Client
                : null;
            final Company? company = (data != null &&
                    data.length > 1 &&
                    data[1] is Company)
                ? data[1] as Company
                : null;

            final displayName = _safeString(
              company?.companyName ??
                  client?.userName ??
                  _user?.displayName,
              fallback: 'Usuario',
            );
            final email = _safeString(
              _user?.email ?? client?.email,
              fallback: 'Sin correo',
            );
            final userType = company != null ? 'Empresa' : 'Usuario';
            final photoUrl = _safeString(
              company?.photoUrl ?? client?.photoUrl ?? _user?.photoURL,
            );
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
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isNotEmpty
                          ? null
                          : Text(
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
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2B45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _isUploadingPhoto
                              ? const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: Colors.white,
                                ),
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

  Future<void> _pickAndUploadPhoto() async {
    final user = _user;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      final results =
          await Future.wait<dynamic>([_clientFuture, _companyFuture]);
      final Client? client = results[0] as Client?;
      final Company? company = results[1] as Company?;

      if (company != null) {
        await context
            .read<SokaService>()
            .updateCompany(user.uid, {'photoUrl': url});
      } else if (client != null) {
        await context
            .read<SokaService>()
            .updateClient(user.uid, {'photoUrl': url});
      }

      if (mounted) {
        setState(() {
          _clientFuture = _user == null
              ? Future.value(null)
              : context.read<SokaService>().fetchClientById(_user!.uid);
          _companyFuture = _user == null
              ? Future.value(null)
              : context.read<SokaService>().fetchCompanyById(_user!.uid);
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la foto')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
                _showSupportSheet(context);
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

  String _safeString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text == 'null' ? fallback : text;
  }

  Future<void> _showSupportSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final user = FirebaseAuth.instance.currentUser;
    _supportEmailController.text = user?.email?.trim() ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supportEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email de contacto',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Ingresa tu email de contacto';
                    }
                    if (!trimmed.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supportSubjectController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Asunto',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Escribe un asunto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supportMessageController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Escribe tu mensaje';
                    }
                    if (value.trim().length < 10) {
                      return 'Escribe un poco mas de detalle';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final subject =
                              _supportSubjectController.text.trim();
                          final message =
                              _supportMessageController.text.trim();
                          final contactEmail =
                              _supportEmailController.text.trim();

                          final body = [
                            'Email de contacto: $contactEmail',
                            if (user?.uid != null) 'User ID: ${user!.uid}',
                            if (user?.email != null)
                              'Email registrado: ${user!.email}',
                            '',
                            message,
                          ].join('\n');

                          final uri = Uri(
                            scheme: 'mailto',
                            path: 'samuelhenaresch@gmail.com',
                            queryParameters: <String, String>{
                              'subject': subject,
                              'body': body,
                            },
                          );

                          final launched = await launchUrl(uri);
                          if (!launched) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo abrir el correo en este dispositivo',
                                ),
                              ),
                            );
                            return;
                          }

                          _supportSubjectController.clear();
                          _supportMessageController.clear();
                          _supportEmailController.clear();
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
