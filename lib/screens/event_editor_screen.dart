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

  final List<_TicketTypeControllers> _ticketTypeControllers = [];

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

    final initialTicketTypes = event?.ticketTypes ?? const <TicketType>[];
    if (initialTicketTypes.isEmpty) {
      _ticketTypeControllers.add(
        _TicketTypeControllers(type: 'General'),
      );
    } else {
      for (final t in initialTicketTypes) {
        _ticketTypeControllers.add(
          _TicketTypeControllers.fromTicketType(t),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _dateTimeController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final previousTypes = widget.event?.ticketTypes ?? const <TicketType>[];
    final ticketTypes = <TicketType>[];
    for (var i = 0; i < _ticketTypeControllers.length; i++) {
      final c = _ticketTypeControllers[i];
      final ticketPrice = int.tryParse(c.price.text.trim()) ?? 0;
      final capacity = int.tryParse(c.capacity.text.trim()) ?? 0;
      final fallbackRemaining = i < previousTypes.length
          ? previousTypes[i].remaining
          : capacity;
      final remaining =
          int.tryParse(c.remaining.text.trim()) ?? fallbackRemaining;

      ticketTypes.add(
        TicketType(
          capacity: capacity,
          description: c.description.text.trim(),
          price: ticketPrice,
          remaining: remaining,
          type: c.type.text.trim(),
        ),
      );
    }

    if (ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un tipo de entrada')),
      );
      setState(() => _isSaving = false);
      return;
    }

    for (final t in ticketTypes) {
      if (t.capacity > 0 && t.remaining > t.capacity) {
        final typeLabel = t.type.trim().isEmpty ? 'este tipo' : t.type.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'En "$typeLabel": las disponibles no pueden ser mayores que el aforo',
            ),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

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
                            Row(
                              children: [
                                const Text(
                                  'Entradas',
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
                                  label: const Text('Añadir'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(_ticketTypeControllers.length, (index) {
                              final c = _ticketTypeControllers[index];
                              final canRemove = _ticketTypeControllers.length > 1;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == _ticketTypeControllers.length - 1 ? 0 : 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                    color: AppColors.background.withAlpha(120),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Tipo ${index + 1}',
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
                                                  : () => _removeTicketType(index),
                                              icon: const Icon(Icons.close_rounded),
                                              tooltip: 'Eliminar tipo',
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _textField(
                                        controller: c.type,
                                        label: 'Tipo',
                                      ),
                                      const SizedBox(height: 12),
                                      _textField(
                                        controller: c.description,
                                        label: 'Descripción del tipo',
                                        required: false,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _textField(
                                              controller: c.price,
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
                                              controller: c.capacity,
                                              label: 'Aforo',
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _textField(
                                        controller: c.remaining,
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
  })  : type = TextEditingController(text: type),
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
