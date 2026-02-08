import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/auth_service.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final userNameController = TextEditingController();
  final phoneController = TextEditingController();
  final birthdateController = TextEditingController();

  final companyNameController = TextEditingController();
  final companyPhoneController = TextEditingController();
  final companyAddressController = TextEditingController();
  final companyWebsiteController = TextEditingController();
  final companyInstagramController = TextEditingController();
  final companyDescriptionController = TextEditingController();

  final authService = AuthService();

  bool isLoading = false;
  int _selectedTypeIndex = 0;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final user = await authService.signup(
        emailController.text,
        passwordController.text,
      );

      if (user == null) {
        throw Exception('No se pudo registrar el usuario');
      }

      final sokaService = context.read<SokaService>();
      if (_selectedTypeIndex == 0) {
        final birthdate = DateTime.parse(birthdateController.text);
        final age = _calculateAge(birthdate);
        final client = Client(
          age: age,
          createdAt: DateTime.now(),
          email: emailController.text.trim(),
          interests: [],
          name: nameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          surname: surnameController.text.trim(),
          userName: userNameController.text.trim(),
        );
        final status = await sokaService.createClientWithId(user.uid, client);
        if (status == 200) {
          await sokaService.deleteCompany(user.uid);
        }
      } else {
        final company = Company(
          companyName: companyNameController.text.trim(),
          contactInfo: ContactInfo(
            adress: companyAddressController.text.trim(),
            email: emailController.text.trim(),
            instagram: companyInstagramController.text.trim(),
            phoneNumber: companyPhoneController.text.trim(),
            website: companyWebsiteController.text.trim(),
          ),
          createdAt: DateTime.now(),
          description: companyDescriptionController.text.trim(),
          verified: false,
        );
        final status = await sokaService.createCompany(user.uid, company);
        if (status == 200) {
          await sokaService.deleteClient(user.uid);
        }
      }
    } catch (e) {
      // Handle error, e.g., show a snackbar or print the error
      print('Signup failed: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => isLoading = true);

    try {
      await authService.signupWithGoogle();
    } catch (e) {
      print('Google signup failed: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    userNameController.dispose();
    phoneController.dispose();
    birthdateController.dispose();
    companyNameController.dispose();
    companyPhoneController.dispose();
    companyAddressController.dispose();
    companyWebsiteController.dispose();
    companyInstagramController.dispose();
    companyDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Image(
                    image: AssetImage('lib/assets/SOKA.png'),
                    height: 200,
                  ),
                  const SizedBox(height: 24),
                  ToggleButtons(
                    isSelected: [
                      _selectedTypeIndex == 0,
                      _selectedTypeIndex == 1,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _selectedTypeIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text('Clientes'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text('Empresas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  if (_selectedTypeIndex == 0) ..._buildClientFields(),
                  if (_selectedTypeIndex == 1) ..._buildCompanyFields(),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: passwordController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _signup,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 16.0),
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
                      onPressed: isLoading ? null : _signupWithGoogle,
                      icon: Image.asset(
                        'lib/assets/iconfinder-new-google-favicon-682665.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text('Continuar con Google'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'login');
                        },
                        child: const Text('Log In'),
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

  int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    final hadBirthdayThisYear =
        (now.month > birthdate.month) ||
        (now.month == birthdate.month && now.day >= birthdate.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }
    return age;
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selected == null) return;

    String twoDigits(int v) => v.toString().padLeft(2, '0');
    final formatted =
        '${selected.year}-${twoDigits(selected.month)}-${twoDigits(selected.day)}';

    setState(() {
      birthdateController.text = formatted;
    });
  }

  // Campos comunes para clientes
  List<Widget> _buildClientFields() {
    return [
      Row(
        children: [
          Expanded(child: _textInput(controller: nameController, label: 'Name')),
          const SizedBox(width: 16),
          Expanded(
            child: _textInput(controller: surnameController, label: 'Surname'),
          ),
        ],
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: userNameController,
        label: 'Username',
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: phoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: birthdateController,
        label: 'Date of Birth',
        readOnly: true,
        onTap: _pickBirthdate,
      ),
    ];
  }

  // Campos específicos para empresas
  List<Widget> _buildCompanyFields() {
    return [
      _textInput(
        controller: companyNameController,
        label: 'Company Name',
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: companyPhoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: companyAddressController,
        label: 'Address',
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: companyWebsiteController,
        label: 'Website',
        required: false,
      ),
      const SizedBox(height: 16.0),
      _textInput(
        controller: companyInstagramController,
        label: 'Instagram',
        required: false,
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: companyDescriptionController,
        decoration: const InputDecoration(labelText: 'Description'),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo obligatorio';
          }
          return null;
        },
      ),
    ];
  }

  Widget _textInput({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Campo obligatorio';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}
