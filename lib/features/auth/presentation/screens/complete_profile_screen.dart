import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/soka_service.dart';
import 'package:soka/shared/widgets/widgets.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/utils/birth_date_input_formatter.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback onProfileSaved;

  const CompleteProfileScreen({
    super.key,
    required this.user,
    required this.onProfileSaved,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
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

  int _selectedTypeIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final email = widget.user.email?.trim() ?? '';
    final displayName = (widget.user.displayName ?? '').trim();
    final parts = displayName.isEmpty
        ? <String>[]
        : displayName.split(RegExp(r'\s+'));

    emailController.text = email;
    nameController.text = parts.isNotEmpty ? parts.first : '';
    surnameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final fallbackUserName = email.contains('@')
        ? email.split('@').first
        : widget.user.uid.substring(0, 8);
    userNameController.text = fallbackUserName;

    companyNameController.text = displayName.isNotEmpty
        ? displayName
        : fallbackUserName;
  }

  @override
  void dispose() {
    emailController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    final sokaService = context.read<SokaService>();
    final email = (widget.user.email?.trim().isNotEmpty == true
        ? widget.user.email!.trim()
        : emailController.text.trim());
    final photoUrl = widget.user.photoURL?.trim() ?? '';

    try {
      if (_selectedTypeIndex == 0) {
        final birthDate = DateTime.parse(birthdateController.text.trim());
        final client = Client(
          age: _calculateAge(birthDate),
          createdAt: DateTime.now(),
          email: email,
          favoriteEventIds: const [],
          historyEventIds: const [],
          interests: const <String?>[],
          name: nameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          profileImageOffsetX: 0,
          profileImageOffsetY: 0,
          profileImageUrl: photoUrl,
          surname: surnameController.text.trim(),
          userName: userNameController.text.trim(),
        );
        final status = await sokaService.createClientWithId(
          widget.user.uid,
          client,
        );
        if (status != 200) {
          throw Exception('Failed to create client profile');
        }
        try {
          await sokaService.deleteCompany(widget.user.uid);
        } catch (_) {
          // no-op
        }
      } else {
        final company = Company(
          companyName: companyNameController.text.trim(),
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
          profileImageUrl: photoUrl,
          verified: false,
        );
        final status = await sokaService.createCompany(
          widget.user.uid,
          company,
        );
        if (status != 200) {
          throw Exception('Failed to create company profile');
        }
        try {
          await sokaService.deleteClient(widget.user.uid);
        } catch (_) {
          // no-op
        }
      }

      if (!mounted) return;
      widget.onProfileSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    birthdateController.text =
        '${selected.year}-${twoDigits(selected.month)}-${twoDigits(selected.day)}';
  }

  int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    var age = now.year - birthdate.year;
    final hadBirthdayThisYear =
        (now.month > birthdate.month) ||
        (now.month == birthdate.month && now.day >= birthdate.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }
    return age;
  }

  List<Widget> _buildClientFields() {
    return [
      Row(
        children: [
          Expanded(
            child: _textInput(controller: nameController, label: 'Name'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _textInput(controller: surnameController, label: 'Surname'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _textInput(controller: userNameController, label: 'Username'),
      const SizedBox(height: 12),
      _textInput(
        controller: phoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: birthdateController,
        keyboardType: TextInputType.number,
        inputFormatters: [BirthDateInputFormatter()],
        decoration: InputDecoration(
          labelText: 'Birth date (YYYY-MM-DD)',
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickBirthdate,
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Required field';
          final parsed = DateTime.tryParse(text);
          if (parsed == null || text.length != 10) return 'Use YYYY-MM-DD';
          if (parsed.isAfter(DateTime.now())) return 'Invalid birth date';
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildCompanyFields() {
    return [
      _textInput(controller: companyNameController, label: 'Company name'),
      const SizedBox(height: 12),
      _textInput(
        controller: companyPhoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      _textInput(controller: companyAddressController, label: 'Address'),
      const SizedBox(height: 12),
      _textInput(
        controller: companyWebsiteController,
        label: 'Website',
        required: false,
      ),
      const SizedBox(height: 12),
      _textInput(
        controller: companyInstagramController,
        label: 'Instagram',
        required: false,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: companyDescriptionController,
        decoration: const InputDecoration(labelText: 'Description'),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required field';
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
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Required field';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
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
                          const Text(
                            'Complete your profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose your account type and fill in your details to continue.',
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
                                setState(() => _selectedTypeIndex = index);
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
                                  child: Text('Client'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text('Company'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _textInput(
                            controller: emailController,
                            label: 'Email',
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          if (_selectedTypeIndex == 0) ..._buildClientFields(),
                          if (_selectedTypeIndex == 1) ..._buildCompanyFields(),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Text('Save and continue'),
                            ),
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
}
