import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final User? _user;
  late final Future<Client?> _clientFuture;
  late final Future<Company?> _companyFuture;

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

  bool isSaving = false;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _clientFuture = _user == null
        ? Future.value(null)
        : context.read<SokaService>().fetchClientById(_user!.uid);
    _companyFuture = _user == null
        ? Future.value(null)
        : context.read<SokaService>().fetchCompanyById(_user!.uid);
  }

  @override
  void dispose() {
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

  void _populateFields({Client? client, Company? company}) {
    if (_populated) return;
    if (client == null && company == null) return;
    _populated = true;

    if (client != null) {
      nameController.text = client.name;
      surnameController.text = client.surname;
      userNameController.text = client.userName;
      phoneController.text = client.phoneNumber;
    }

    if (company != null) {
      companyNameController.text = company.companyName;
      companyPhoneController.text = company.contactInfo.phoneNumber;
      companyAddressController.text = company.contactInfo.adress;
      companyWebsiteController.text = company.contactInfo.website;
      companyInstagramController.text = company.contactInfo.instagram;
      companyDescriptionController.text = company.description;
    }
  }

  Future<void> _saveChanges({Client? client, Company? company}) async {
    if (_user == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (isSaving) return;

    setState(() => isSaving = true);
    final sokaService = context.read<SokaService>();

    try {
      if (client != null) {
        final updatedData = <String, dynamic>{
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'userName': userNameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
        };
        await sokaService.updateClient(_user!.uid, updatedData);
      } else if (company != null) {
        final websiteText = companyWebsiteController.text.trim();
        final instagramText = companyInstagramController.text.trim();
        final updatedData = <String, dynamic>{
          'companyName': companyNameController.text.trim(),
          'description': companyDescriptionController.text.trim(),
          'contactInfo': {
            'adress': companyAddressController.text.trim(),
            'email': _user?.email ?? company.contactInfo.email,
            'instagram': instagramText.isEmpty
                ? company.contactInfo.instagram
                : instagramText,
            'phoneNumber': companyPhoneController.text.trim(),
            'website':
                websiteText.isEmpty ? company.contactInfo.website : websiteText,
          },
        };
        await sokaService.updateCompany(_user!.uid, updatedData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar los cambios')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait<dynamic>([_clientFuture, _companyFuture]),
        builder: (context, snapshot) {
          final Client? client =
              snapshot.data != null ? snapshot.data![0] as Client? : null;
          final Company? company =
              snapshot.data != null ? snapshot.data![1] as Company? : null;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (client == null && company == null) {
            return const Center(child: Text('No se encontró el perfil.'));
          }

          _populateFields(client: client, company: company);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _readonlyField(
                    label: 'Email',
                    value: _user?.email ?? 'Sin correo',
                  ),
                  const SizedBox(height: 16),
                  if (client != null) ..._buildClientFields(),
                  if (company != null) ..._buildCompanyFields(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () => _saveChanges(client: client, company: company),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildClientFields() {
    return [
      _textInput(controller: nameController, label: 'Nombre', required: false),
      const SizedBox(height: 16),
      _textInput(controller: surnameController, label: 'Apellido', required: false),
      const SizedBox(height: 16),
      _textInput(controller: userNameController, label: 'Username', required: false),
      const SizedBox(height: 16),
      _textInput(
        controller: phoneController,
        label: 'Teléfono',
        keyboardType: TextInputType.phone,
      ),
    ];
  }

  List<Widget> _buildCompanyFields() {
    return [
      _textInput(controller: companyNameController, label: 'Company Name', required: false),
      const SizedBox(height: 16),
      _textInput(
        controller: companyPhoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      _textInput(controller: companyAddressController, label: 'Address', required: false),
      const SizedBox(height: 16),
      _textInput(
        controller: companyWebsiteController,
        label: 'Website',
        required: false,
      ),
      const SizedBox(height: 16),
      _textInput(
        controller: companyInstagramController,
        label: 'Instagram',
        required: false,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: companyDescriptionController,
        decoration: const InputDecoration(labelText: 'Description'),
        maxLines: 3,
      ),
    ];
  }

  Widget _textInput({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Campo obligatorio';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _readonlyField({required String label, required String value}) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
    );
  }
}
