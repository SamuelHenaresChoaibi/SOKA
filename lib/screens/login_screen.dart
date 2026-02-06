import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';
import '../services/auth_service.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await authService.login(
        emailController.text,
        passwordController.text,
      );
      // AuthGate se encarga de la navegación
    } on FirebaseAuthException catch (e) {
      String message = 'Error al iniciar sesión';
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no registrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Correo inválido';
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
        const SnackBar(
          content: Text('Inicio de sesión con Google cancelado'),
        ),
      );
      return;
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message ?? 'Error al iniciar sesión con Google'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error inesperado. Intenta nuevamente.'),
      ),
    );
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Image(
                    image: AssetImage('lib/assets/SOKA.png'),
                    height: 200,
                  ),
                  const SizedBox(height: 40),

                  _input(emailController, 'Email', icon: Icons.person),
                  const SizedBox(height: 16),
                  _input(passwordController, 'Contraseña',
                      obscure: true, icon: Icons.lock),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.surface,
                            )
                          : const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: const [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('o'),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _loginWithGoogle,
                      icon: Image.asset(
                        'lib/assets/iconfinder-new-google-favicon-682665.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text('Continuar con Google'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () async {
                      if (emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Introduce tu email primero')),
                        );
                        return;
                      }
                      try {
                        await authService.resetPassword(emailController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Email de recuperación enviado correctamente')),
                        );
                      } on FirebaseAuthException {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error al enviar el email')),
                        );
                      }
                    },
                    child: const Text('¿Has olvidado la contraseña?'),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'register');
                        },
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label,
      {bool obscure = false, IconData? icon}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obligatorio';
        }
        if (!obscure && !value.contains('@')) {
          return 'Email inválido';
        }
        if (obscure && value.length < 6) {
          return 'Mínimo 6 caracteres';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
