import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:soka/features/auth/presentation/screens/login_screen.dart';
import 'package:soka/features/home/presentation/screens/home_screen.dart';
import 'package:soka/services/soka_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return _AuthenticatedEntry(user: user);
      },
    );
  }
}

class _AuthenticatedEntry extends StatefulWidget {
  final User user;

  const _AuthenticatedEntry({required this.user});

  @override
  State<_AuthenticatedEntry> createState() => _AuthenticatedEntryState();
}

class _AuthenticatedEntryState extends State<_AuthenticatedEntry> {
  late Future<_AuthProfileStatus> _profileStatusFuture;

  @override
  void initState() {
    super.initState();
    _profileStatusFuture = _loadProfileStatus();
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _profileStatusFuture = _loadProfileStatus();
    }
  }

  Future<_AuthProfileStatus> _loadProfileStatus() async {
    final sokaService = context.read<SokaService>();
    final response = await Future.wait<dynamic>([
      sokaService.fetchClientById(widget.user.uid),
      sokaService.fetchCompanyById(widget.user.uid),
    ]);

    return _AuthProfileStatus(
      hasClient: response[0] != null,
      hasCompany: response[1] != null,
    );
  }

  void _refreshProfileStatus() {
    setState(() {
      _profileStatusFuture = _loadProfileStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthProfileStatus>(
      future: _profileStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not verify profile data. Check your connection and retry.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshProfileStatus,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profileStatus = snapshot.data ?? const _AuthProfileStatus();
        if (profileStatus.hasProfile) {
          return const HomeScreen();
        }

        return CompleteProfileScreen(
          user: widget.user,
          onProfileSaved: _refreshProfileStatus,
        );
      },
    );
  }
}

class _AuthProfileStatus {
  final bool hasClient;
  final bool hasCompany;

  const _AuthProfileStatus({this.hasClient = false, this.hasCompany = false});

  bool get hasProfile => hasClient || hasCompany;
}
