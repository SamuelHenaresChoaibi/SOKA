import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/features/events/presentation/screens/event_details_screen.dart';
import 'package:soka/shared/widgets/widgets.dart';
import 'package:soka/services/auth_service.dart';
import 'package:soka/services/services.dart';
import 'package:soka/features/settings/presentation/screens/account_settings_screen.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final settings = await context.read<SokaService>().fetchUserSettings(
        user.uid,
      );

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
      body: SokaLuxuryBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 72),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.secondary.withValues(alpha: 0.96),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Manage your account and preferences',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                    child: SokaEntrance(child: _profileCard(context)),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              _settingsSections(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait<dynamic>([_clientFuture, _companyFuture]),
          builder: (context, snapshot) {
            final Client? client = snapshot.data != null
                ? snapshot.data![0] as Client?
                : null;
            final Company? company = snapshot.data != null
                ? snapshot.data![1] as Company?
                : null;

            final rawDisplayName =
                company?.companyName ??
                client?.userName ??
                _user?.displayName ??
                'User';
            final rawEmail = _user?.email ?? client?.email ?? 'No email';
            final rawProfileImageUrl =
                company?.profileImageUrl ?? client?.profileImageUrl ?? '';
            final rawProfileImageOffsetX =
                company?.profileImageOffsetX ??
                client?.profileImageOffsetX ??
                0;
            final rawProfileImageOffsetY =
                company?.profileImageOffsetY ??
                client?.profileImageOffsetY ??
                0;
            final displayName = _shareProfile
                ? rawDisplayName
                : 'Profile hidden';
            final email = (_shareProfile && _showEmail)
                ? rawEmail
                : 'Email hidden';
            final profileImageUrl = _shareProfile
                ? rawProfileImageUrl.trim()
                : '';
            final profileImageOffsetX = rawProfileImageOffsetX.clamp(-1.0, 1.0);
            final profileImageOffsetY = rawProfileImageOffsetY.clamp(-1.0, 1.0);
            final hasProfileImage =
                profileImageUrl.startsWith('http://') ||
                profileImageUrl.startsWith('https://');
            final userType = company != null ? 'Company' : 'User';
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
                      _SettingsProfileAvatar(
                        radius: 30,
                        imageUrl: profileImageUrl,
                        alignment: Alignment(
                          profileImageOffsetX,
                          profileImageOffsetY,
                        ),
                        fallbackText: initials,
                      ),
                      if (hasProfileImage)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
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
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
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
                            ? 'Loading...'
                            : displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading...'
                                : '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? '...'
                                  : userType,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
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
    final sokaService = context.watch<SokaService>();
    final accessibility = context.watch<AccessibilityService>();
    final eventById = <String, Event>{
      for (final e in sokaService.events) e.id: e,
    };
    final privacySummary = !_shareProfile
        ? 'Profile hidden'
        : _showEmail
        ? 'Profile and email visible'
        : 'Profile visible without email';
    final accessibilitySummary = _buildAccessibilitySummary(accessibility);

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
                  subtitle: const Text("Edit your account information"),
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
                  title: const Text("Privacy settings"),
                  subtitle: Text(privacySummary),
                  onTap: () async {
                    await _loadPrivacySettings(force: true);
                    if (!context.mounted) return;
                    _showPrivacySheet(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.accessibility_new_rounded),
                  title: const Text("Accessibility"),
                  subtitle: Text(accessibilitySummary),
                  onTap: () {
                    _showAccessibilitySheet(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notifications"),
                  subtitle: const Text("View alerts for the next week"),
                  onTap: () {
                    Navigator.pushNamed(context, 'notifications');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<Client?>(
            future: _clientFuture,
            builder: (context, snapshot) {
              final client = snapshot.data;
              if (client == null) {
                return const SizedBox.shrink();
              }

              final historyEvents =
                  client.historyEventIds
                      .map((id) => eventById[id])
                      .whereType<Event>()
                      .where((event) => event.date.isBefore(DateTime.now()))
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

              return Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text("History"),
                      subtitle: Text(
                        historyEvents.isEmpty
                            ? "You have no events in your history"
                            : "${historyEvents.length} events in your history",
                      ),
                      onTap: () {
                        _showHistorySheet(
                          context,
                          historyEvents: historyEvents,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Help and support"),
              subtitle: const Text("Contact support"),
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
                try {
                  await AuthService().logout();
                } catch (_) {
                  // no-op
                }
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showHistorySheet(
    BuildContext context, {
    required List<Event> historyEvents,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        if (historyEvents.isEmpty) {
          return const SizedBox(
            height: 240,
            child: Center(child: Text('Your history is empty')),
          );
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
            itemCount: historyEvents.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final event = historyEvents[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.event_available_rounded),
                  title: Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatDateTime(event.date)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(event: event),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }

  String _buildAccessibilitySummary(AccessibilityService service) {
    final themeLabel = _themeModeLabel(service.themeMode);
    final textSize = (service.textScaleFactor * 100).round();
    final flags = <String>[];
    if (service.highContrast) flags.add('high contrast');
    if (service.boldText) flags.add('bold text');
    if (service.reduceMotion) flags.add('reduced motion');
    if (flags.isEmpty) return '$themeLabel - text $textSize%';
    return '$themeLabel - text $textSize% - ${flags.join(', ')}';
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System mode';
    }
  }

  void _showAccessibilitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Consumer<AccessibilityService>(
          builder: (context, accessibility, _) {
            final textSize = (accessibility.textScaleFactor * 100).round();
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accessibility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: accessibility.themeMode,
                      decoration: const InputDecoration(
                        labelText: 'Appearance mode',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System default'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          accessibility.setThemeMode(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Text size ($textSize%)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: accessibility.textScaleFactor,
                      min: 0.9,
                      max: 1.5,
                      divisions: 12,
                      label: '$textSize%',
                      onChanged: accessibility.setTextScaleFactor,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: accessibility.highContrast,
                      onChanged: accessibility.setHighContrast,
                      title: const Text('High contrast'),
                      subtitle: const Text(
                        'Improve legibility with stronger contrast colors',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: accessibility.boldText,
                      onChanged: accessibility.setBoldText,
                      title: const Text('Bold text'),
                      subtitle: const Text(
                        'Use bolder text throughout the app',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: accessibility.reduceMotion,
                      onChanged: accessibility.setReduceMotion,
                      title: const Text('Reduce motion'),
                      subtitle: const Text(
                        'Minimize transitions and visual movement',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await accessibility.resetDefaults();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Done'),
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
      },
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
                await context.read<SokaService>().updateUserSettings(user.uid, {
                  'shareProfile': _shareProfile,
                  'showEmail': _showEmail,
                });

                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy settings saved successfully'),
                  ),
                );
              } catch (_) {
                if (!mounted || !context.mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save privacy settings'),
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
                    'Privacy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share my profile'),
                    subtitle: const Text(
                      'Allows others to see your public profile',
                    ),
                    value: _shareProfile,
                    onChanged: (value) {
                      setModalState(() => _shareProfile = value);
                      setState(() => _shareProfile = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show my email'),
                    subtitle: const Text(
                      'Shows your email in your public profile',
                    ),
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
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Close'),
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
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Text('Save'),
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
                  'Help and support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supportEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Contact email'),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Enter your contact email';
                    }
                    if (!trimmed.contains('@')) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supportSubjectController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a subject';
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
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your message';
                    }
                    if (value.trim().length < 10) {
                      return 'Write a bit more detail';
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
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final subject = _supportSubjectController.text.trim();
                          final message = _supportMessageController.text.trim();
                          final contactEmail = _supportEmailController.text
                              .trim();

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
                                  'Could not open email on this device. Please send your message to samuelhenaresch@gmail.com',
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
                        child: const Text('Send'),
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

class _SettingsProfileAvatar extends StatelessWidget {
  final double radius;
  final String imageUrl;
  final Alignment alignment;
  final String fallbackText;

  const _SettingsProfileAvatar({
    required this.radius,
    required this.imageUrl,
    required this.alignment,
    required this.fallbackText,
  });

  bool get _hasImage {
    final trimmed = imageUrl.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    if (!_hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.accent,
        child: Text(
          fallbackText,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl.trim(),
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              fallbackText,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
