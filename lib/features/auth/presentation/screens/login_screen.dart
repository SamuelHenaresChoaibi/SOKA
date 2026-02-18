import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soka/shared/widgets/widgets.dart';
import 'package:soka/services/auth_service.dart';
import 'package:soka/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;

  String _mapGoogleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-blocked':
        return 'El navegador bloqueó la ventana de Google. Habilita popups para este sitio.';
      case 'popup-closed-by-user':
        return 'Cerraste la ventana de Google antes de terminar el inicio de sesión.';
      case 'unauthorized-domain':
        return 'Dominio no autorizado en Firebase Auth. Añádelo en Authorized domains.';
      case 'operation-not-allowed':
        return 'Google Sign-In no está habilitado en Firebase Authentication.';
      case 'network-request-failed':
        return 'Error de red. Revisa tu conexión e inténtalo de nuevo.';
      default:
        return e.message ?? 'Error al iniciar sesión con Google.';
    }
  }

  String _mapResetPasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'missing-email':
        return 'Debes introducir un correo electrónico.';
      case 'network-request-failed':
        return 'Error de red. Revisa tu conexión.';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo de nuevo más tarde.';
      case 'user-not-found':
        // Evita filtrar si existe o no la cuenta; UX consistente.
        return 'Si el correo está registrado, recibirás un email de recuperación.';
      default:
        return e.message ?? 'No se pudo enviar el correo de recuperación.';
    }
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(
          text: emailController.text.trim(),
        );
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'tu@correo.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (!mounted || email == null) return;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un email válido.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await authService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el correo está registrado, recibirás un email de recuperación.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapResetPasswordError(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await authService.login(emailController.text, passwordController.text);
      // AuthGate se encarga de la navegación
    } on FirebaseAuthException catch (e) {
      String message = 'Error sign in';
      switch (e.code) {
        case 'user-not-found':
          message = 'User not registered';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final user = await authService.signInWithGoogle();

      if (user == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in cancelled')),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuthException code: ${e.code}');
      debugPrint('Google Sign-In FirebaseAuthException message: ${e.message}');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapGoogleAuthError(e))));
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In unexpected error: $e');
      debugPrint('StackTrace: $stackTrace');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SokaLuxuryBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SokaEntrance(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Image(
                            image: AssetImage('lib/assets/SOKA.png'),
                            height: 110,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to continue exploring the best events.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _input(
                            emailController,
                            'Email',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 14),
                          _input(
                            passwordController,
                            'Password',
                            obscure: true,
                            icon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _login,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Expanded(child: Divider(color: AppColors.border)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _loginWithGoogle,
                              icon: Image.asset(
                                'lib/assets/iconfinder-new-google-favicon-682665.png',
                                height: 22,
                                width: 22,
                              ),
                              label: const Text('Continue with Google'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: isLoading ? null : _forgotPassword,
                            child: const Text('Forgot your password?'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, 'register');
                                },
                                child: const Text('Register'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required field';
        }
        if (!obscure && !value.contains('@')) {
          return 'Invalid email format';
        }
        if (obscure && value.length < 6) {
          return 'Minimum 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.accent.withValues(alpha: 0.9))
            : null,
      ),
    );
  }
}
