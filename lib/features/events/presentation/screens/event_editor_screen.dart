import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';

class EventEditorScreen extends StatefulWidget {
  final String organizerId;
  final Event? event;

  const EventEditorScreen({super.key, required this.organizerId, this.event});

  bool get isEditing => event != null;

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _otherCategoryController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _dateTimeController;
  late final TextEditingController _maxTicketsPerUserController;

  final List<_TicketTypeControllers> _ticketTypeControllers = [];

  final GeoapifyService _geoapifyService = GeoapifyService();
  final List<GeoapifySuggestion> _locationSuggestions = [];
  GeoapifySuggestion? _selectedLocation;
  String _initialLocation = '';
  bool _isFetchingSuggestions = false;
  Timer? _locationDebounce;
  bool _ignoreLocationChange = false;

  static const List<String> _defaultCategoryOptions = [
    'Verbena',
    'Club',
    'Festival',
    'ChillOut',
    'Pubs',
    'Other',
  ];
  static const String _otherCategoryOption = 'Other';
  List<String> _categoryOptions = List<String>.from(_defaultCategoryOptions);
  String _selectedCategory = _defaultCategoryOptions.first;
  bool _isLoadingCategories = false;

  DateTime? _selectedDateTime;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImageMimeType;

  @override
  void initState() {
    super.initState();

    final event = widget.event;
    _selectedDateTime = event?.date;

    _titleController = TextEditingController(text: event?.title ?? '');
    final initialCategory = event?.category ?? '';
    _categoryController = TextEditingController(text: initialCategory);
    _otherCategoryController = TextEditingController();
    _configureCategorySelection(initialCategory);
    _locationController = TextEditingController(text: event?.location ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _imageUrlController = TextEditingController(text: event?.imageUrl ?? '');
    _dateTimeController = TextEditingController(
      text: _selectedDateTime == null
          ? ''
          : _formatDateTime(_selectedDateTime!),
    );
    _maxTicketsPerUserController = TextEditingController(
      text: event == null ? '4' : event.maxTicketsPerUser.toString(),
    );

    final existingTickets = event?.ticketTypes ?? const [];
    if (existingTickets.isNotEmpty) {
      _ticketTypeControllers.addAll(
        existingTickets.map(_TicketTypeControllers.fromTicketType),
      );
    } else {
      _ticketTypeControllers.add(_TicketTypeControllers(type: 'General'));
    }

    _initialLocation = _locationController.text.trim();
    Future.microtask(_loadCategoryOptionsFromFirebase);
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _titleController.dispose();
    _categoryController.dispose();
    _otherCategoryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _dateTimeController.dispose();
    _maxTicketsPerUserController.dispose();
    for (final c in _ticketTypeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTicketType() {
    setState(() {
      _ticketTypeControllers.add(_TicketTypeControllers(type: ''));
    });
  }

  void _removeTicketType(int index) {
    if (_ticketTypeControllers.length <= 1) return;
    setState(() {
      final removed = _ticketTypeControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _selectedDateTime ?? now.add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDateTime = selected;
      _dateTimeController.text = _formatDateTime(selected);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select date and time')));
      return;
    }

    setState(() => _isSaving = true);

    final locationValid = await _validateLocation();
    if (!locationValid) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final resolvedCategory = _resolveCategory();
    if (resolvedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a valid category')));
      setState(() => _isSaving = false);
      return;
    }

    final location = _locationController.text.trim();
    final locationSuggestion = _selectedLocation;

    final ticketTypes = _buildTicketTypes();

    final sokaService = context.read<SokaService>();
    final maxTicketsPerUser =
        int.tryParse(_maxTicketsPerUserController.text.trim()) ??
        (widget.event?.maxTicketsPerUser ?? 4);

    try {
      var imageUrl = _imageUrlController.text.trim();
      if (_selectedImageBytes != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await sokaService.uploadEventImage(
          bytes: _selectedImageBytes!,
          organizerId: widget.organizerId,
          eventId: widget.event?.id,
          fileName: _selectedImageName,
          contentType: _selectedImageMimeType,
        );
        _imageUrlController.text = imageUrl;
      }

      if (widget.isEditing) {
        final event = widget.event!;
        final updatedData = <String, dynamic>{
          'category': resolvedCategory,
          'date': _selectedDateTime!.toIso8601String(),
          'description': _descriptionController.text.trim(),
          'imageUrl': imageUrl,
          'isActive': event.isActive,
          'location': location,
          'locationFormatted': locationSuggestion?.formatted,
          'locationLat': locationSuggestion?.lat,
          'locationLng': locationSuggestion?.lon,
          'locationCity': locationSuggestion?.city,
          'locationState': locationSuggestion?.state,
          'locationPostcode': locationSuggestion?.postcode,
          'locationCountry': locationSuggestion?.country,
          'maxTicketsPerUser': maxTicketsPerUser,
          'organizerId': widget.organizerId,
          'ticketTypes': ticketTypes.map((e) => e.toJson()).toList(),
          'title': _titleController.text.trim(),
          'validated': event.validated,
        };

        await sokaService.updateEvent(event.id, updatedData);
        if (!mounted) return;
        Navigator.pop(context, event.id);
      } else {
        final now = DateTime.now();
        final event = Event(
          id: '',
          category: resolvedCategory,
          createdAt: now,
          date: _selectedDateTime!,
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          isActive: true,
          //imageUrl: _imageUrlController.text.trim(),
          location: location,
          //location: _locationController.text.trim(),
          locationFormatted: locationSuggestion?.formatted,
          locationLat: locationSuggestion?.lat,
          locationLng: locationSuggestion?.lon,
          locationCity: locationSuggestion?.city,
          locationState: locationSuggestion?.state,
          locationPostcode: locationSuggestion?.postcode,
          locationCountry: locationSuggestion?.country,
          organizerId: widget.organizerId,
          ticketTypes: ticketTypes,
          maxTicketsPerUser: maxTicketsPerUser,
          title: _titleController.text.trim(),
          validated: false,
        );

        final createdEventId = await sokaService.createEvent(event);
        if (!mounted) return;

        if (createdEventId == null || createdEventId.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not publish the event')),
          );
          return;
        }

        Navigator.pop(context, createdEventId);
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      String message;
      if (code == 'permission-denied' || code == 'unauthenticated') {
        message = 'You do not have permission to save this event or image.';
      } else {
        message = e.message ?? 'Firebase error while saving.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      String message = 'Error while saving.';
      if (raw.contains('Storage[unauthorized]')) {
        message = 'Firebase Storage rejected the upload (no permissions).';
      } else if (raw.contains('Storage[quota-exceeded]')) {
        message = 'Firebase Storage quota exceeded.';
      } else if (raw.contains('Storage[canceled]')) {
        message = 'Image upload was canceled.';
      } else if (raw.contains('Storage[retry-limit-exceeded]')) {
        message = 'Upload failed due to unstable network. Please try again.';
      } else if (raw.contains('organizerId vacío')) {
        message = 'Could not identify the organizer to upload the image.';
      } else {
        message = 'Error while saving: $e';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit event' : 'Create event';
    final subtitle = widget.isEditing
        ? 'Update your event information'
        : 'Complete the details and publish it';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: title,
              subtitle: subtitle,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _card(
                        child: Column(
                          children: [
                            _textField(
                              controller: _titleController,
                              label: 'Event name',
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value:
                                  _categoryOptions.contains(_selectedCategory)
                                  ? _selectedCategory
                                  : _categoryOptions.first,
                              items: _categoryOptions
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isLoadingCategories
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedCategory = value;
                                        if (!_isOtherCategory(value)) {
                                          _categoryController.text = value;
                                          _otherCategoryController.clear();
                                        } else {
                                          _categoryController.clear();
                                        }
                                      });
                                    },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Select a category';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                            ),
                            if (_isLoadingCategories)
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (_isOtherCategory(_selectedCategory)) ...[
                              const SizedBox(height: 10),
                              _textField(
                                controller: _otherCategoryController,
                                label: 'Other category',
                              ),
                            ],
                            const SizedBox(height: 14),
                            _textField(
                              controller: _locationController,
                              label: 'Location',
                              onChanged: _onLocationChanged,
                            ),
                            if (_isFetchingSuggestions)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (_locationSuggestions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _SuggestionsList(
                                  suggestions: _locationSuggestions,
                                  onTap: _applySuggestion,
                                ),
                              ),
                            if (_selectedLocation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _LocationDetails(
                                  suggestion: _selectedLocation!,
                                ),
                              ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _dateTimeController,
                              label: 'Date and time',
                              readOnly: true,
                              onTap: _pickDateTime,
                            ),
                            const SizedBox(height: 14),
                            _PhotoPicker(
                              selectedImageBytes: _selectedImageBytes,
                              imageUrl: _imageUrlController.text.trim(),
                              isBusy: _isSaving || _isUploadingImage,
                              onPick: _pickImageFromDevice,
                              onRemove: _clearSelectedImage,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _descriptionController,
                              label: 'Description',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _maxTicketsPerUserController,
                              label:
                                  'Límite de compra por usuario (0 = sin límite)',
                              required: false,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Tickets',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _isSaving ? null : _addTicketType,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(_ticketTypeControllers.length, (
                              index,
                            ) {
                              final c = _ticketTypeControllers[index];
                              final canRemove =
                                  _ticketTypeControllers.length > 1;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      index == _ticketTypeControllers.length - 1
                                      ? 0
                                      : 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                    color: AppColors.background.withAlpha(120),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Type ${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (canRemove)
                                            IconButton(
                                              onPressed: _isSaving
                                                  ? null
                                                  : () => _removeTicketType(
                                                      index,
                                                    ),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                              tooltip: 'Remove type',
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _textField(
                                        controller: c.type,
                                        label: 'Type',
                                      ),
                                      const SizedBox(height: 12),
                                      _textField(
                                        controller: c.description,
                                        label: 'Type description',
                                        required: false,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _textField(
                                              controller: c.price,
                                              label: 'Price (€)',
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _textField(
                                              controller: c.capacity,
                                              label: 'Capacity',
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _textField(
                                        controller: c.remaining,
                                        label:
                                            'Available tickets (leave empty to match capacity)',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        required: false,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.surface,
                                  ),
                                )
                              : Icon(
                                  widget.isEditing
                                      ? Icons.save_rounded
                                      : Icons.publish_rounded,
                                ),
                          label: Text(
                            widget.isEditing ? 'Save changes' : 'Publish',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  static Widget _textField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    bool required = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (!required) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Required field';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  static String _formatDateTime(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} · '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String? _resolveCategory() {
    if (_isOtherCategory(_selectedCategory)) {
      final other = _otherCategoryController.text.trim();
      return other.isEmpty ? null : other;
    }
    return _selectedCategory.trim().isEmpty ? null : _selectedCategory;
  }

  Future<void> _loadCategoryOptionsFromFirebase() async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);

    final remoteCategories = await context
        .read<SokaService>()
        .fetchEventCategories();
    final normalized = _normalizeCategoryOptions(remoteCategories);
    final initialCategory = widget.event?.category ?? '';

    if (!mounted) return;
    setState(() {
      _categoryOptions = normalized.isEmpty
          ? List<String>.from(_defaultCategoryOptions)
          : normalized;
      _configureCategorySelection(initialCategory);
      _isLoadingCategories = false;
    });
  }

  List<String> _normalizeCategoryOptions(List<String> input) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final raw in input) {
      final category = raw.trim();
      if (category.isEmpty) continue;
      final key = category.toLowerCase();
      if (!seen.add(key)) continue;
      normalized.add(category);
    }

    if (!normalized.any((item) => _isOtherCategory(item))) {
      normalized.add(_otherCategoryOption);
    }

    return normalized;
  }

  void _configureCategorySelection(String initialCategory) {
    final normalizedInitial = initialCategory.trim();
    if (normalizedInitial.isNotEmpty) {
      final match = _categoryOptions.firstWhere(
        (option) => option.toLowerCase() == normalizedInitial.toLowerCase(),
        orElse: () => '',
      );

      if (match.isNotEmpty && !_isOtherCategory(match)) {
        _selectedCategory = match;
        _categoryController.text = match;
        _otherCategoryController.clear();
        return;
      }

      _selectedCategory = _categoryOptions.firstWhere(
        _isOtherCategory,
        orElse: () => _otherCategoryOption,
      );
      _categoryController.clear();
      _otherCategoryController.text = normalizedInitial;
      return;
    }

    final defaultCategory = _categoryOptions.firstWhere(
      (option) => !_isOtherCategory(option),
      orElse: () => _categoryOptions.first,
    );
    _selectedCategory = defaultCategory;
    _categoryController.text = defaultCategory;
    _otherCategoryController.clear();
  }

  bool _isOtherCategory(String value) {
    return value.trim().toLowerCase() == _otherCategoryOption.toLowerCase();
  }

  void _onLocationChanged(String value) {
    if (_ignoreLocationChange) return;
    _selectedLocation = null;

    final trimmed = value.trim();
    if (trimmed.length < 3 || !GeoapifyService.hasApiKey) {
      if (_locationSuggestions.isNotEmpty || _isFetchingSuggestions) {
        setState(() {
          _locationSuggestions.clear();
          _isFetchingSuggestions = false;
        });
      }
      return;
    }

    _locationDebounce?.cancel();
    _locationDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isFetchingSuggestions = true);

      final suggestions = await _geoapifyService.suggest(trimmed, limit: 5);

      if (!mounted) return;
      setState(() {
        _locationSuggestions
          ..clear()
          ..addAll(suggestions);
        _isFetchingSuggestions = false;
      });
    });
  }

  Future<void> _applySuggestion(GeoapifySuggestion suggestion) async {
    _ignoreLocationChange = true;
    _locationController.text = suggestion.displayLabel;
    _ignoreLocationChange = false;

    setState(() {
      _selectedLocation = suggestion;
      _locationSuggestions.clear();
      _isFetchingSuggestions = false;
    });
  }

  List<TicketType> _buildTicketTypes() {
    final types = <TicketType>[];
    for (final c in _ticketTypeControllers) {
      final type = c.type.text.trim();
      final description = c.description.text.trim();
      final price = int.tryParse(c.price.text.trim()) ?? 0;
      final capacity = int.tryParse(c.capacity.text.trim()) ?? 0;
      final remainingText = c.remaining.text.trim();
      final remaining = remainingText.isEmpty
          ? capacity
          : int.tryParse(remainingText) ?? capacity;

      if (type.isEmpty &&
          description.isEmpty &&
          price == 0 &&
          capacity == 0 &&
          remaining == 0) {
        continue;
      }

      types.add(
        TicketType(
          capacity: capacity,
          description: description,
          price: price,
          remaining: remaining,
          type: type.isEmpty ? 'General' : type,
        ),
      );
    }
    return types;
  }

  Future<bool> _validateLocation() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location cannot be empty.')),
      );
      return false;
    }

    if (!GeoapifyService.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure GEOAPIFY_API_KEY to validate the location.'),
        ),
      );
      return false;
    }

    if (_selectedLocation != null) {
      return true;
    }

    if (location == _initialLocation && widget.isEditing) {
      return true;
    }

    try {
      final suggestions = await _geoapifyService.suggest(location, limit: 1);
      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Location not found.')));
        return false;
      }
      _selectedLocation = suggestions.first;
      return true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not validate the location')),
      );
      return false;
    }
  }

  Future<void> _pickImageFromDevice() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name;
        _selectedImageMimeType = file.mimeType;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      final error = (e.code.toLowerCase() + e.message.toString().toLowerCase());
      if (error.contains('denied') ||
          error.contains('permission') ||
          error.contains('access')) {
        await _showGalleryPermissionDialog();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening gallery: ${e.code}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select the photo')),
      );
    }
  }

  Future<void> _showGalleryPermissionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gallery permission required'),
        content: const Text(
          'To upload a photo, you must allow access to Photos/Gallery in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedImageMimeType = null;
      _imageUrlController.clear();
    });
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<GeoapifySuggestion> suggestions;
  final ValueChanged<GeoapifySuggestion> onTap;

  const _SuggestionsList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            title: Text(
              suggestion.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: suggestion.displayLabel == suggestion.name
                ? null
                : Text(
                    suggestion.displayLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
            onTap: () => onTap(suggestion),
          );
        },
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final Uint8List? selectedImageBytes;
  final String imageUrl;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.selectedImageBytes,
    required this.imageUrl,
    required this.isBusy,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = selectedImageBytes != null;
    final hasRemoteImage = imageUrl.isNotEmpty;
    final hasImage = hasLocalImage || hasRemoteImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Photo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            color: AppColors.background.withAlpha(120),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: hasLocalImage
                ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                : hasRemoteImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(hasImage ? 'Change photo' : 'Upload photo'),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: isBusy ? null : onRemove,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, color: AppColors.textSecondary),
          SizedBox(height: 6),
          Text(
            'No photo selected',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LocationDetails extends StatelessWidget {
  final GeoapifySuggestion suggestion;

  const _LocationDetails({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final city = suggestion.city?.trim();
    final state = suggestion.state?.trim();
    final postcode = suggestion.postcode?.trim();
    final country = suggestion.country?.trim();

    final rows = <MapEntry<String, String>>[];
    if (city != null && city.isNotEmpty) {
      rows.add(MapEntry('City', city));
    }
    if (state != null && state.isNotEmpty) {
      rows.add(MapEntry('State', state));
    }
    if (postcode != null && postcode.isNotEmpty) {
      rows.add(MapEntry('Postal Code', postcode));
    }
    if (country != null && country.isNotEmpty) {
      rows.add(MapEntry('Country', country));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TicketTypeControllers {
  final TextEditingController type;
  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController capacity;
  final TextEditingController remaining;

  _TicketTypeControllers({
    required String type,
    String description = '',
    String price = '',
    String capacity = '',
    String remaining = '',
  }) : type = TextEditingController(text: type),
       description = TextEditingController(text: description),
       price = TextEditingController(text: price),
       capacity = TextEditingController(text: capacity),
       remaining = TextEditingController(text: remaining);

  factory _TicketTypeControllers.fromTicketType(TicketType ticketType) {
    return _TicketTypeControllers(
      type: ticketType.type,
      description: ticketType.description,
      price: ticketType.price.toString(),
      capacity: ticketType.capacity.toString(),
      remaining: ticketType.remaining.toString(),
    );
  }

  void dispose() {
    type.dispose();
    description.dispose();
    price.dispose();
    capacity.dispose();
    remaining.dispose();
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.secondary.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
