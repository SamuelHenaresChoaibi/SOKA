import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';

class EventEditorScreen extends StatefulWidget {
  final String organizerId;
  final Event? event;

  const EventEditorScreen({
    super.key,
    required this.organizerId,
    this.event,
  });

  bool get isEditing => event != null;

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _dateTimeController;

  late final TextEditingController _ticketTypeController;
  late final TextEditingController _ticketDescriptionController;
  late final TextEditingController _ticketPriceController;
  late final TextEditingController _ticketCapacityController;
  late final TextEditingController _ticketRemainingController;

  DateTime? _selectedDateTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final event = widget.event;
    _selectedDateTime = event?.date;

    _titleController = TextEditingController(text: event?.title ?? '');
    _categoryController = TextEditingController(text: event?.category ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _imageUrlController = TextEditingController(text: event?.imageUrl ?? '');
    _dateTimeController = TextEditingController(
      text: _selectedDateTime == null ? '' : _formatDateTime(_selectedDateTime!),
    );

    _ticketTypeController =
        TextEditingController(text: event?.ticketTypes.type ?? 'General');
    _ticketDescriptionController = TextEditingController(
      text: event?.ticketTypes.description ?? '',
    );
    _ticketPriceController = TextEditingController(
      text: event == null ? '' : event.ticketTypes.price.toString(),
    );
    _ticketCapacityController = TextEditingController(
      text: event == null ? '' : event.ticketTypes.capacity.toString(),
    );
    _ticketRemainingController = TextEditingController(
      text: event == null ? '' : event.ticketTypes.remaining.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _dateTimeController.dispose();
    _ticketTypeController.dispose();
    _ticketDescriptionController.dispose();
    _ticketPriceController.dispose();
    _ticketCapacityController.dispose();
    _ticketRemainingController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ticketPrice = int.tryParse(_ticketPriceController.text.trim()) ?? 0;
    final capacity = int.tryParse(_ticketCapacityController.text.trim()) ?? 0;
    final remaining = int.tryParse(_ticketRemainingController.text.trim()) ??
        (widget.event?.ticketTypes.remaining ?? capacity);

    final ticketTypes = TicketType(
      capacity: capacity,
      description: _ticketDescriptionController.text.trim(),
      price: ticketPrice,
      remaining: remaining,
      type: _ticketTypeController.text.trim(),
    );

    final sokaService = context.read<SokaService>();

    try {
      if (widget.isEditing) {
        final event = widget.event!;
        final updatedData = <String, dynamic>{
          'category': _categoryController.text.trim(),
          'date': _selectedDateTime!.toIso8601String(),
          'description': _descriptionController.text.trim(),
          'imageUrl': _imageUrlController.text.trim(),
          'location': _locationController.text.trim(),
          'organizerId': widget.organizerId,
          'ticketTypes': ticketTypes.toJson(),
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
          category: _categoryController.text.trim(),
          createdAt: now,
          date: _selectedDateTime!,
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          location: _locationController.text.trim(),
          organizerId: widget.organizerId,
          ticketTypes: ticketTypes,
          title: _titleController.text.trim(),
          validated: false,
        );

        final createdEventId = await sokaService.createEvent(event);
        if (!mounted) return;

        if (createdEventId == null || createdEventId.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo publicar el evento')),
          );
          return;
        }

        Navigator.pop(context, createdEventId);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el evento')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Editar evento' : 'Crear evento';
    final subtitle = widget.isEditing
        ? 'Actualiza la información de tu evento'
        : 'Completa los datos y publícalo';

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
                              label: 'Nombre del evento',
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _categoryController,
                              label: 'Categoría',
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _locationController,
                              label: 'Ubicación',
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _dateTimeController,
                              label: 'Fecha y hora',
                              readOnly: true,
                              onTap: _pickDateTime,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _imageUrlController,
                              label: 'Foto (URL)',
                              required: false,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _descriptionController,
                              label: 'Descripción',
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Entradas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _ticketTypeController,
                              label: 'Tipo',
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _ticketDescriptionController,
                              label: 'Descripción del tipo',
                              required: false,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    controller: _ticketPriceController,
                                    label: 'Precio (€)',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    controller: _ticketCapacityController,
                                    label: 'Aforo',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _ticketRemainingController,
                              label: 'Disponibles',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              required: false,
                            ),
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
                            widget.isEditing ? 'Guardar cambios' : 'Publicar',
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
    bool required = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (!required) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Campo obligatorio';
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
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
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.surface,
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
                  color: AppColors.surface.withAlpha(191),
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
