import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/screens/event_editor_screen.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';

class CompanyEventsScreen extends StatefulWidget {
  final String companyId;
  final Company company;
  final ValueChanged<Company> onCompanyUpdated;

  const CompanyEventsScreen({
    super.key,
    required this.companyId,
    required this.company,
    required this.onCompanyUpdated,
  });

  @override
  State<CompanyEventsScreen> createState() => _CompanyEventsScreenState();
}

class _CompanyEventsScreenState extends State<CompanyEventsScreen> {
  bool _isWorking = false;

  Future<void> _refresh() async {
    final sokaService = context.read<SokaService>();
    await sokaService.fetchEvents();

    try {
      final updatedCompany = await sokaService.fetchCompanyById(widget.companyId);
      if (!mounted) return;
      if (updatedCompany != null) {
        widget.onCompanyUpdated(updatedCompany);
      }
    } catch (_) {
      // no-op
    }
  }

  Future<void> _createEvent() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);

    try {
      final createdEventId = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => EventEditorScreen(organizerId: widget.companyId),
        ),
      );

      if (!mounted) return;
      if (createdEventId == null || createdEventId.trim().isEmpty) return;

      final updatedIds = [
        ...widget.company.createdEventIds,
        createdEventId.trim(),
      ];

      await context.read<SokaService>().updateCompany(
        widget.companyId,
        {'createdEventIds': updatedIds},
      );

      if (!mounted) return;
      widget.onCompanyUpdated(
        widget.company.copyWith(createdEventIds: updatedIds),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento publicado')),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _editEvent(Event event) async {
    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(
          organizerId: widget.companyId,
          event: event,
        ),
      ),
    );
  }

  Future<void> _linkDetectedEvents(List<String> eventIds) async {
    if (_isWorking) return;
    if (eventIds.isEmpty) return;

    setState(() => _isWorking = true);
    try {
      final updatedIds = <String>{
        ...widget.company.createdEventIds,
        ...eventIds,
      }.toList();

      await context.read<SokaService>().updateCompany(
        widget.companyId,
        {'createdEventIds': updatedIds},
      );

      if (!mounted) return;
      widget.onCompanyUpdated(
        widget.company.copyWith(createdEventIds: updatedIds),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eventos vinculados a tu cuenta')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron vincular los eventos')),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _deleteEvent(Event event) async {
    if (_isWorking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar evento'),
          content: Text('¿Seguro que quieres eliminar "${event.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isWorking = true);
    try {
      await context.read<SokaService>().deleteEvent(event.id);
      if (!mounted) return;

      if (widget.company.createdEventIds.contains(event.id)) {
        final updatedIds = List<String>.from(widget.company.createdEventIds)
          ..remove(event.id);
        await context.read<SokaService>().updateCompany(
          widget.companyId,
          {'createdEventIds': updatedIds},
        );
        widget.onCompanyUpdated(
          widget.company.copyWith(createdEventIds: updatedIds),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el evento')),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<SokaService>().events;
    final eventById = <String, Event>{for (final e in events) e.id: e};

    final createdIds = widget.company.createdEventIds;
    final createdEvents = createdIds
        .map((id) => eventById[id])
        .whereType<Event>()
        .toList();

    String normalize(String value) {
      return value
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    final normalizedCompanyId = normalize(widget.companyId);
    final normalizedCompanyName = normalize(widget.company.companyName);
    final rawCompanyName = widget.company.companyName.trim();
    final rawCompanyId = widget.companyId.trim();
    final rawCompanyEmail = widget.company.contactInfo.email.trim();
    final rawCompanyInstagram = widget.company.contactInfo.instagram.trim();

    final normalizedCompanyIdentifiers = <String>{
      normalizedCompanyId,
      normalizedCompanyName,
      if (rawCompanyEmail.isNotEmpty) normalize(rawCompanyEmail),
      if (rawCompanyInstagram.isNotEmpty) normalize(rawCompanyInstagram),
    }..removeWhere((e) => e.isEmpty);

    bool matchesCompanyOrganizer(Event event) {
      final organizerRaw = event.organizerId.trim();
      if (organizerRaw.isEmpty) return false;

      if (organizerRaw == rawCompanyId || organizerRaw == rawCompanyName) {
        return true;
      }

      final organizer = normalize(organizerRaw);
      if (normalizedCompanyIdentifiers.contains(organizer)) {
        return true;
      }

      for (final id in normalizedCompanyIdentifiers) {
        if (organizer.contains(id) || id.contains(organizer)) {
          return true;
        }
      }

      if (rawCompanyEmail.isNotEmpty && organizerRaw == rawCompanyEmail) {
        return true;
      }

      if (rawCompanyInstagram.isNotEmpty && organizerRaw == rawCompanyInstagram) {
        return true;
      }

      return false;
    }

    final fallbackEvents = events.where(matchesCompanyOrganizer).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final mergedById = <String, Event>{
      for (final event in createdEvents) event.id: event,
      for (final event in fallbackEvents) event.id: event,
    };

    final visibleEvents = mergedById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final showingFallback = fallbackEvents.any(
      (event) => !createdIds.contains(event.id),
    );
    final missingLinkedIds = fallbackEvents
        .map((e) => e.id)
        .where((id) => !createdIds.contains(id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CompanyEventsHeader(
                count: visibleEvents.length,
                onCreate: _createEvent,
                isWorking: _isWorking,
              ),
            ),
            if (showingFallback)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _InfoBanner(
                    text:
                        'Mostrando eventos detectados por organizador. Puedes vincularlos a tu cuenta para gestionarlos más fácilmente.',
                    actionLabel:
                        missingLinkedIds.isEmpty ? null : 'Vincular',
                    onAction: missingLinkedIds.isEmpty
                        ? null
                        : () => _linkDetectedEvents(missingLinkedIds),
                  ),
                ),
              ),
            if (visibleEvents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onCreate: _createEvent),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CompanyEventCard(
                    event: visibleEvents[index],
                    onEdit: () => _editEvent(visibleEvents[index]),
                    onDelete: () => _deleteEvent(visibleEvents[index]),
                  ),
                  childCount: visibleEvents.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _CompanyEventsHeader extends StatelessWidget {
  final int count;
  final VoidCallback onCreate;
  final bool isWorking;

  const _CompanyEventsHeader({
    required this.count,
    required this.onCreate,
    required this.isWorking,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = count == 0
        ? 'Crea tu primer evento y publícalo'
        : 'Tienes $count evento${count == 1 ? '' : 's'} publicado${count == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mis eventos',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isWorking ? null : onCreate,
                    icon: isWorking
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: const Text('Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.surface.withAlpha(191),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = event.minTicketPrice;
    final maxPrice = event.maxTicketPrice;
    final priceLabel = !event.hasTicketTypes
        ? 'Sin entradas'
        : minPrice <= 0
            ? 'Gratis'
            : minPrice == maxPrice
                ? '€$minPrice'
                : 'Desde €$minPrice';
    final dateLabel = _formatDateTime(event.date.toLocal());
    final remaining = event.totalRemaining;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        priceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.event,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$remaining disponibles',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 64,
              color: AppColors.cursorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no has publicado eventos',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.cursorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa en "Crear" para publicar tu primer evento.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear evento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoBanner({
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
