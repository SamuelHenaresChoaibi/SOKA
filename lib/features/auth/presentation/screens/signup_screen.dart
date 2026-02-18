import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/shared/widgets/widgets.dart';
import 'package:soka/services/auth_service.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/utils/birth_date_input_formatter.dart';

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
        throw Exception('Could not create user');
      }

      final sokaService = context.read<SokaService>();
      if (_selectedTypeIndex == 0) {
        final birthdate = DateTime.parse(birthdateController.text);
        final age = _calculateAge(birthdate);
        final client = Client(
          age: age,
          createdAt: DateTime.now(),
          email: emailController.text.trim(),
          favoriteEventIds: const [],
          historyEventIds: const [],
          interests: [],
          name: nameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          profileImageOffsetX: 0,
          profileImageOffsetY: 0,
          profileImageUrl: '',
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
          createdEventIds: const [],
          description: companyDescriptionController.text.trim(),
          profileImageOffsetX: 0,
          profileImageOffsetY: 0,
          profileImageUrl: '',
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
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final user = await authService.signupWithGoogle();
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-up cancelled')),
        );
        return;
      }

      await _createProfileForGoogleUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedTypeIndex == 0
                ? 'Cuenta Google registrada como cliente'
                : 'Cuenta Google registrada como empresa',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google signup failed: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createProfileForGoogleUser(User user) async {
    final sokaService = context.read<SokaService>();
    final email = user.email?.trim().isNotEmpty == true
        ? user.email!.trim()
        : emailController.text.trim();
    final displayName = (user.displayName ?? '').trim();
    final displayParts = displayName.isEmpty
        ? <String>[]
        : displayName.split(' ');

    if (_selectedTypeIndex == 0) {
      final fallbackUserName = email.contains('@')
          ? email.split('@').first
          : user.uid.substring(0, 8);
      final birthdateText = birthdateController.text.trim();
      final parsedBirthdate = DateTime.tryParse(birthdateText);
      final age = parsedBirthdate != null ? _calculateAge(parsedBirthdate) : 18;

      final client = Client(
        age: age,
        createdAt: DateTime.now(),
        email: email,
        favoriteEventIds: const [],
        historyEventIds: const [],
        interests: const <String?>[],
        name: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : (displayParts.isNotEmpty ? displayParts.first : 'Usuario'),
        phoneNumber: phoneController.text.trim(),
        profileImageOffsetX: 0,
        profileImageOffsetY: 0,
        profileImageUrl: user.photoURL?.trim() ?? '',
        surname: surnameController.text.trim().isNotEmpty
            ? surnameController.text.trim()
            : (displayParts.length > 1
                  ? displayParts.sublist(1).join(' ')
                  : ''),
        userName: userNameController.text.trim().isNotEmpty
            ? userNameController.text.trim()
            : fallbackUserName,
      );
      final status = await sokaService.createClientWithId(user.uid, client);
      if (status != 200) {
        throw Exception('No se pudo crear el perfil de cliente');
      }
      await sokaService.deleteCompany(user.uid);
      return;
    }

    final companyName = companyNameController.text.trim().isNotEmpty
        ? companyNameController.text.trim()
        : (displayName.isNotEmpty
              ? displayName
              : (email.contains('@') ? email.split('@').first : 'Empresa'));

    final company = Company(
      companyName: companyName,
      contactInfo: ContactInfo(
        adress: companyAddressController.text.trim(),
        email: email,
        instagram: companyInstagramController.text.trim(),
        phoneNumber: companyPhoneController.text.trim(),
        website: companyWebsiteController.text.trim(),
      ),
      createdAt: DateTime.now(),
      createdEventIds: const [],
      description: companyDescriptionController.text.trim(),
      profileImageOffsetX: 0,
      profileImageOffsetY: 0,
      profileImageUrl: user.photoURL?.trim() ?? '',
      verified: false,
    );
    final status = await sokaService.createCompany(user.uid, company);
    if (status != 200) {
      throw Exception('No se pudo crear el perfil de empresa');
    }
    await sokaService.deleteClient(user.uid);
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
      body: SokaLuxuryBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SokaEntrance(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.34),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Image(
                            image: AssetImage('lib/assets/SOKA.png'),
                            height: 100,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Create your account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join as attendee or company and start publishing or buying tickets.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ToggleButtons(
                              isSelected: [
                                _selectedTypeIndex == 0,
                                _selectedTypeIndex == 1,
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _selectedTypeIndex = index;
                                });
                              },
                              borderColor: Colors.transparent,
                              selectedBorderColor: Colors.transparent,
                              fillColor: AppColors.accent,
                              selectedColor: AppColors.primary,
                              color: AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(12),
                              constraints: const BoxConstraints(
                                minWidth: 120,
                                minHeight: 42,
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text('Clients'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text('Companies'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required field';
                              }
                              if (!value.contains('@')) {
                                return 'Invalid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_selectedTypeIndex == 0) ..._buildClientFields(),
                          if (_selectedTypeIndex == 1) ..._buildCompanyFields(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _signup,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Text('Sign Up'),
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
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _signupWithGoogle,
                              icon: Image.asset(
                                'lib/assets/iconfinder-new-google-favicon-682665.png',
                                height: 22,
                                width: 22,
                              ),
                              label: const Text('Continue with Google'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
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
          Expanded(
            child: _textInput(controller: nameController, label: 'Name'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _textInput(controller: surnameController, label: 'Surname'),
          ),
        ],
      ),
      const SizedBox(height: 16.0),
      _textInput(controller: userNameController, label: 'Username'),
      const SizedBox(height: 16.0),
      _textInput(
        controller: phoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: birthdateController,
        keyboardType: TextInputType.number,
        inputFormatters: [BirthDateInputFormatter()],
        decoration: InputDecoration(
          labelText: 'Date of Birth (YYYY-MM-DD)',
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickBirthdate,
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Required field';
          final parsed = DateTime.tryParse(text);
          if (parsed == null || text.length != 10) {
            return 'Use YYYY-MM-DD';
          }
          if (parsed.isAfter(DateTime.now())) {
            return 'Birth date cannot be in the future';
          }
          return null;
        },
      ),
    ];
  }

  // Campos específicos para empresas
  List<Widget> _buildCompanyFields() {
    return [
      _textInput(controller: companyNameController, label: 'Company Name'),
      const SizedBox(height: 16.0),
      _textInput(
        controller: companyPhoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16.0),
      _textInput(controller: companyAddressController, label: 'Address'),
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
            return 'Required field';
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
          return 'Required field';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}
