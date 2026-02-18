import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final profileImageUrlController = TextEditingController();

  final companyNameController = TextEditingController();
  final companyPhoneController = TextEditingController();
  final companyAddressController = TextEditingController();
  final companyWebsiteController = TextEditingController();
  final companyInstagramController = TextEditingController();
  final companyDescriptionController = TextEditingController();

  bool isSaving = false;
  bool _isUploadingImage = false;
  bool _populated = false;
  double _profileImageOffsetX = 0;
  double _profileImageOffsetY = 0;

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
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    userNameController.dispose();
    phoneController.dispose();
    birthdateController.dispose();
    profileImageUrlController.dispose();
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
      profileImageUrlController.text = client.profileImageUrl;
      _profileImageOffsetX = client.profileImageOffsetX.clamp(-1.0, 1.0);
      _profileImageOffsetY = client.profileImageOffsetY.clamp(-1.0, 1.0);
    }

    if (company != null) {
      companyNameController.text = company.companyName;
      companyPhoneController.text = company.contactInfo.phoneNumber;
      companyAddressController.text = company.contactInfo.adress;
      companyWebsiteController.text = company.contactInfo.website;
      companyInstagramController.text = company.contactInfo.instagram;
      companyDescriptionController.text = company.description;
      profileImageUrlController.text = company.profileImageUrl;
      _profileImageOffsetX = company.profileImageOffsetX.clamp(-1.0, 1.0);
      _profileImageOffsetY = company.profileImageOffsetY.clamp(-1.0, 1.0);
    }
  }

  Future<void> _pickAndUploadImage({required bool isCompany}) async {
    final currentUser = _user;
    if (currentUser == null || _isUploadingImage) return;
    final sokaService = context.read<SokaService>();

    setState(() => _isUploadingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final uploadedUrl = await sokaService.uploadUserProfileImage(
        bytes: bytes,
        userId: currentUser.uid,
        isCompany: isCompany,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() => profileImageUrlController.text = uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo uploaded successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload profile photo')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveChanges({Client? client, Company? company}) async {
    final currentUser = _user;
    if (currentUser == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (isSaving) return;

    setState(() => isSaving = true);
    final sokaService = context.read<SokaService>();
    final profileImageUrl = profileImageUrlController.text.trim();

    try {
      if (client != null) {
        final updatedData = <String, dynamic>{
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'userName': userNameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'profileImageOffsetX': _profileImageOffsetX,
          'profileImageOffsetY': _profileImageOffsetY,
          'profileImageUrl': profileImageUrl,
        };
        await sokaService.updateClient(currentUser.uid, updatedData);
      } else if (company != null) {
        final websiteText = companyWebsiteController.text.trim();
        final instagramText = companyInstagramController.text.trim();
        final updatedData = <String, dynamic>{
          'companyName': companyNameController.text.trim(),
          'description': companyDescriptionController.text.trim(),
          'profileImageOffsetX': _profileImageOffsetX,
          'profileImageOffsetY': _profileImageOffsetY,
          'profileImageUrl': profileImageUrl,
          'contactInfo': {
            'adress': companyAddressController.text.trim(),
            'email': currentUser.email ?? company.contactInfo.email,
            'instagram': instagramText.isEmpty
                ? company.contactInfo.instagram
                : instagramText,
            'phoneNumber': companyPhoneController.text.trim(),
            'website': websiteText.isEmpty
                ? company.contactInfo.website
                : websiteText,
          },
        };
        await sokaService.updateCompany(currentUser.uid, updatedData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving changes')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  bool _isValidImageUrl(String value) {
    if (value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Widget _buildProfileImageEditor({required bool isCompany}) {
    final imageUrl = profileImageUrlController.text.trim();
    final hasImage = _isValidImageUrl(imageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ProfileAvatar(
              radius: 34,
              imageUrl: imageUrl,
              alignment: Alignment(_profileImageOffsetX, _profileImageOffsetY),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage
                            ? null
                            : () => _pickAndUploadImage(isCompany: isCompany),
                        icon: _isUploadingImage
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_rounded),
                        label: Text(
                          _isUploadingImage ? 'Uploading...' : 'Upload',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            profileImageUrlController.clear();
                            _profileImageOffsetX = 0;
                            _profileImageOffsetY = 0;
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _profileImageOffsetX = 0;
                            _profileImageOffsetY = 0;
                          });
                        },
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text('Center'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: profileImageUrlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Profile image URL',
            hintText: 'https://...',
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isNotEmpty && !_isValidImageUrl(trimmed)) {
              return 'Invalid URL';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          Text(
            'Horizontal position (${_profileImageOffsetX.toStringAsFixed(2)})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            value: _profileImageOffsetX,
            min: -1,
            max: 1,
            divisions: 40,
            onChanged: (value) {
              setState(() => _profileImageOffsetX = value);
            },
          ),
          Text(
            'Vertical position (${_profileImageOffsetY.toStringAsFixed(2)})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            value: _profileImageOffsetY,
            min: -1,
            max: 1,
            divisions: 40,
            onChanged: (value) {
              setState(() => _profileImageOffsetY = value);
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait<dynamic>([_clientFuture, _companyFuture]),
        builder: (context, snapshot) {
          final Client? client = snapshot.data != null
              ? snapshot.data![0] as Client?
              : null;
          final Company? company = snapshot.data != null
              ? snapshot.data![1] as Company?
              : null;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (client == null && company == null) {
            return const Center(child: Text('Profile not found.'));
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
                    value: _user?.email ?? 'No email',
                  ),
                  const SizedBox(height: 16),
                  _buildProfileImageEditor(isCompany: company != null),
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
                        : const Text('Save changes'),
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
      _textInput(controller: nameController, label: 'Name', required: false),
      const SizedBox(height: 16),
      _textInput(
        controller: surnameController,
        label: 'Surname',
        required: false,
      ),
      const SizedBox(height: 16),
      _textInput(
        controller: userNameController,
        label: 'Username',
        required: false,
      ),
      const SizedBox(height: 16),
      _textInput(
        controller: phoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
    ];
  }

  List<Widget> _buildCompanyFields() {
    return [
      _textInput(
        controller: companyNameController,
        label: 'Company Name',
        required: false,
      ),
      const SizedBox(height: 16),
      _textInput(
        controller: companyPhoneController,
        label: 'Phone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      _textInput(
        controller: companyAddressController,
        label: 'Address',
        required: false,
      ),
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
          return 'Required field';
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

class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final String imageUrl;
  final Alignment alignment;

  const _ProfileAvatar({
    required this.radius,
    required this.imageUrl,
    required this.alignment,
  });

  bool get _hasImage {
    final trimmed = imageUrl.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final bgColor = Theme.of(context).colorScheme.secondaryContainer;

    if (!_hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: const Icon(Icons.person_rounded, size: 34),
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl.trim(),
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person_rounded, size: 34);
        },
      ),
    );
  }
}
