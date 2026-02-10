import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/auth_service.dart';
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
  bool _privacyLoaded = false;
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

    Future.microtask(_loadPrivacySettings);
  }

  Future<void> _loadPrivacySettings({bool force = false}) async {
    final user = _user;
    if (user == null) return;
    if (_privacyLoaded && !force) return;

    try {
      final settings =
          await context.read<SokaService>().fetchUserSettings(user.uid);

      if (!mounted) return;
      setState(() {
        final shareProfile = settings?['shareProfile'];
        final showEmail = settings?['showEmail'];
        _shareProfile = shareProfile is bool ? shareProfile : _shareProfile;
        _showEmail = showEmail is bool ? showEmail : _showEmail;
        _privacyLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _privacyLoaded = true);
    }
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
                        'Ajustes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Administra tu cuenta y preferencias',
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
                InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                  child: Stack(
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
                            Icons.edit,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  title: const Text("Cuenta"),
                  subtitle: const Text("Edita la información de tu cuenta"),
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
                  title: const Text("Privacidad"),
                  subtitle: const Text("Controla qué información se muestra"),
                  onTap: () async {
                    await _loadPrivacySettings(force: true);
                    if (!context.mounted) return;
                    _showPrivacySheet(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notificaciones"),
                  subtitle: const Text("Ver alertas de la próxima semana"),
                  onTap: () {
                    Navigator.pushNamed(context, 'notifications');
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
              title: const Text("Ayuda y soporte"),
              subtitle: const Text("Contacta con soporte"),
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
              title: const Text("Cerrar sesión"),
              subtitle: const Text("Salir de tu cuenta"),
              onTap: () async {
                try {
                  await AuthService().logout();
                } catch (_) {
                  // no-op
                }
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
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
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveSettings() async {
              final user = _user;
              if (user == null) return;
              if (isSaving) return;

              setModalState(() => isSaving = true);

              try {
                await context.read<SokaService>().updateUserSettings(
                  user.uid,
                  {
                    'shareProfile': _shareProfile,
                    'showEmail': _showEmail,
                  },
                );

                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacidad guardada correctamente'),
                  ),
                );
              } catch (_) {
                if (!mounted || !context.mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudieron guardar los cambios'),
                  ),
                );
              } finally {
                if (context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacidad',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compartir mi perfil'),
                    subtitle: const Text('Permite que otros vean tu perfil público'),
                    value: _shareProfile,
                    onChanged: (value) {
                      setModalState(() => _shareProfile = value);
                      setState(() => _shareProfile = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar mi email'),
                    subtitle: const Text('Muestra tu email en tu perfil público'),
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
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : saveSettings,
                          child: isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar'),
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
                  'Ayuda y soporte',
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
                          if (!mounted || !context.mounted) return;
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
