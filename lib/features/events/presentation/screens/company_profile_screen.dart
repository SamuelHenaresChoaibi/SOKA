import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:soka/features/events/presentation/screens/event_details_screen.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

enum _CompanyEventSort {
  createdNewest,
  createdOldest,
  eventDateNearest,
  eventDateLatest,
  titleAz,
}

enum _CompanyEventDateFilter { all, upcoming, past }

class CompanyProfileScreen extends StatefulWidget {
  final String companyId;
  final Company initialCompany;

  const CompanyProfileScreen({
    super.key,
    required this.companyId,
    required this.initialCompany,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  late Company _company;
  final TextEditingController _searchController = TextEditingController();

  _CompanyEventSort _sort = _CompanyEventSort.createdNewest;
  _CompanyEventDateFilter _dateFilter = _CompanyEventDateFilter.all;
  bool _onlyWithAvailableTickets = false;
  String _selectedCategory = 'All';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _company = widget.initialCompany;
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    Future.microtask(_refreshCompanyData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCompanyData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    final sokaService = context.read<SokaService>();
    try {
      await sokaService.fetchEvents();
      final updatedCompany = await sokaService.fetchCompanyById(
        widget.companyId,
      );
      if (!mounted) return;
      if (updatedCompany != null) {
        setState(() => _company = updatedCompany);
      }
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _matchesCompanyOrganizer(Event event) {
    final organizerRaw = event.organizerId.trim();
    if (organizerRaw.isEmpty) return false;

    final rawCompanyName = _company.companyName.trim();
    final rawCompanyId = widget.companyId.trim();
    final rawCompanyEmail = _company.contactInfo.email.trim();
    final rawCompanyInstagram = _company.contactInfo.instagram.trim();

    if (organizerRaw == rawCompanyId || organizerRaw == rawCompanyName) {
      return true;
    }

    final normalizedCompanyIdentifiers = <String>{
      _normalize(rawCompanyId),
      _normalize(rawCompanyName),
      if (rawCompanyEmail.isNotEmpty) _normalize(rawCompanyEmail),
      if (rawCompanyInstagram.isNotEmpty) _normalize(rawCompanyInstagram),
    }..removeWhere((e) => e.isEmpty);

    final organizer = _normalize(organizerRaw);
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

  List<Event> _collectCompanyEvents(List<Event> allEvents) {
    final eventById = <String, Event>{for (final e in allEvents) e.id: e};
    final linkedEvents = _company.createdEventIds
        .map((id) => eventById[id])
        .whereType<Event>()
        .toList();
    final detectedEvents = allEvents.where(_matchesCompanyOrganizer).toList();

    final merged = <String, Event>{
      for (final event in linkedEvents) event.id: event,
      for (final event in detectedEvents) event.id: event,
    };

    return merged.values.toList();
  }

  bool _matchesDateFilter(Event event) {
    if (_dateFilter == _CompanyEventDateFilter.all) return true;
    final now = DateTime.now();
    if (_dateFilter == _CompanyEventDateFilter.upcoming) {
      return !event.date.isBefore(now);
    }
    return event.date.isBefore(now);
  }

  void _sortEvents(List<Event> events) {
    switch (_sort) {
      case _CompanyEventSort.createdNewest:
        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return;
      case _CompanyEventSort.createdOldest:
        events.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return;
      case _CompanyEventSort.eventDateNearest:
        events.sort((a, b) => a.date.compareTo(b.date));
        return;
      case _CompanyEventSort.eventDateLatest:
        events.sort((a, b) => b.date.compareTo(a.date));
        return;
      case _CompanyEventSort.titleAz:
        events.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        return;
    }
  }

  String _sortLabel(_CompanyEventSort sort) {
    switch (sort) {
      case _CompanyEventSort.createdNewest:
        return 'Created (newest)';
      case _CompanyEventSort.createdOldest:
        return 'Created (oldest)';
      case _CompanyEventSort.eventDateNearest:
        return 'Event date (nearest)';
      case _CompanyEventSort.eventDateLatest:
        return 'Event date (latest)';
      case _CompanyEventSort.titleAz:
        return 'Title (A-Z)';
    }
  }

  String _dateFilterLabel(_CompanyEventDateFilter filter) {
    switch (filter) {
      case _CompanyEventDateFilter.all:
        return 'All dates';
      case _CompanyEventDateFilter.upcoming:
        return 'Upcoming';
      case _CompanyEventDateFilter.past:
        return 'Past';
    }
  }

  Future<void> _openLink(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(
      trimmed.startsWith('http') ? trimmed : 'https://$trimmed',
    );
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInstagram(String handle) async {
    final normalized = handle.trim().replaceFirst('@', '');
    if (normalized.isEmpty) return;
    final uri = Uri.parse('https://instagram.com/$normalized');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: trimmed);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = context.watch<SokaService>().events;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.companyId;
    final companyEvents = _collectCompanyEvents(
      allEvents,
    ).where((event) => isOwner || event.isActive).toList();
    final categories =
        <String>{
          'All',
          ...companyEvents
              .map((event) => event.category.trim())
              .where((c) => c.isNotEmpty),
        }.toList()..sort((a, b) {
          if (a == 'All') return -1;
          if (b == 'All') return 1;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : 'All';

    final query = _searchController.text.trim().toLowerCase();
    final filteredEvents = companyEvents.where((event) {
      if (selectedCategory != 'All' && event.category != selectedCategory) {
        return false;
      }
      if (!_matchesDateFilter(event)) return false;
      if (_onlyWithAvailableTickets && event.totalRemaining <= 0) return false;
      if (query.isEmpty) return true;
      return event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.category.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query);
    }).toList();

    _sortEvents(filteredEvents);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Company profile'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshCompanyData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _CompanyHeaderCard(
                    company: _company,
                    onOpenWebsite: _company.contactInfo.website.trim().isEmpty
                        ? null
                        : () => _openLink(_company.contactInfo.website),
                    onOpenInstagram:
                        _company.contactInfo.instagram.trim().isEmpty
                        ? null
                        : () => _openInstagram(_company.contactInfo.instagram),
                    onOpenEmail: _company.contactInfo.email.trim().isEmpty
                        ? null
                        : () => _openEmail(_company.contactInfo.email),
                  ),
                  const SizedBox(height: 14),
                  _FiltersCard(
                    searchController: _searchController,
                    sort: _sort,
                    dateFilter: _dateFilter,
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onlyWithAvailableTickets: _onlyWithAvailableTickets,
                    onSortChanged: (value) {
                      setState(() => _sort = value);
                    },
                    onDateFilterChanged: (value) {
                      setState(() => _dateFilter = value);
                    },
                    onCategoryChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                    onOnlyWithTicketsChanged: (value) {
                      setState(() => _onlyWithAvailableTickets = value);
                    },
                    sortLabel: _sortLabel,
                    dateFilterLabel: _dateFilterLabel,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Events (${filteredEvents.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_isRefreshing)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (filteredEvents.isEmpty)
                    const _EmptyCompanyEvents()
                  else
                    ...filteredEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CompanyPublicEventCard(
                          event: event,
                          showVisibility: isOwner,
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailsScreen(event: event),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeaderCard extends StatelessWidget {
  final Company company;
  final VoidCallback? onOpenWebsite;
  final VoidCallback? onOpenInstagram;
  final VoidCallback? onOpenEmail;
  const _CompanyHeaderCard({
    required this.company,
    this.onOpenWebsite,
    this.onOpenInstagram,
    this.onOpenEmail,
  });
  @override
  Widget build(BuildContext context) {
    final companyName = company.companyName.trim().isEmpty
        ? 'Company'
        : company.companyName.trim();
    final description = company.description.trim();
    final website = company.contactInfo.website.trim();
    final instagram = company.contactInfo.instagram.trim();
    final email = company.contactInfo.email.trim();
    final address = company.contactInfo.adress.trim();
    final phone = company.contactInfo.phoneNumber.trim();
    final hasContactLinks =
        website.isNotEmpty || instagram.isNotEmpty || email.isNotEmpty;
    Widget buildInfoPill(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.94),
            AppColors.surface,
          ],
          stops: const [0, 0.42],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.24),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _CompanyAvatar(
              imageUrl: company.profileImageUrl,
              fallbackText: companyName.substring(0, 1).toUpperCase(),
              alignment: Alignment(
                company.profileImageOffsetX.clamp(-1.0, 1.0),
                company.profileImageOffsetY.clamp(-1.0, 1.0),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                companyName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (company.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description.isEmpty
                ? 'No company description available.'
                : description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (address.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (address.isNotEmpty)
                  buildInfoPill(Icons.location_on_outlined, address),
                if (phone.isNotEmpty) buildInfoPill(Icons.call_outlined, phone),
              ],
            ),
          ],
          if (hasContactLinks) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (website.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.language_rounded, size: 16),
                    label: const Text('Website'),
                    backgroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: onOpenWebsite,
                  ),
                if (instagram.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text('Instagram'),
                    backgroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: onOpenInstagram,
                  ),
                if (email.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.email_outlined, size: 16),
                    label: const Text('Email'),
                    backgroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: onOpenEmail,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  final Alignment alignment;

  const _CompanyAvatar({
    required this.imageUrl,
    required this.fallbackText,
    required this.alignment,
  });

  bool get _hasImage {
    final trimmed = imageUrl.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      return CircleAvatar(
        radius: 42,
        backgroundColor: AppColors.accent,
        child: Text(
          fallbackText,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl.trim(),
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              fallbackText,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final TextEditingController searchController;
  final _CompanyEventSort sort;
  final _CompanyEventDateFilter dateFilter;
  final List<String> categories;
  final String selectedCategory;
  final bool onlyWithAvailableTickets;
  final ValueChanged<_CompanyEventSort> onSortChanged;
  final ValueChanged<_CompanyEventDateFilter> onDateFilterChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onOnlyWithTicketsChanged;
  final String Function(_CompanyEventSort) sortLabel;
  final String Function(_CompanyEventDateFilter) dateFilterLabel;

  const _FiltersCard({
    required this.searchController,
    required this.sort,
    required this.dateFilter,
    required this.categories,
    required this.selectedCategory,
    required this.onlyWithAvailableTickets,
    required this.onSortChanged,
    required this.onDateFilterChanged,
    required this.onCategoryChanged,
    required this.onOnlyWithTicketsChanged,
    required this.sortLabel,
    required this.dateFilterLabel,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search events',
              hintText: 'Title, description, category or location',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          _InlineDropdown<_CompanyEventSort>(
            label: 'Sort',
            value: sort,
            items: _CompanyEventSort.values
                .map(
                  (value) => DropdownMenuItem<_CompanyEventSort>(
                    value: value,
                    child: Text(sortLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          ),
          const SizedBox(height: 10),
          _InlineDropdown<_CompanyEventDateFilter>(
            label: 'Date filter',
            value: dateFilter,
            items: _CompanyEventDateFilter.values
                .map(
                  (value) => DropdownMenuItem<_CompanyEventDateFilter>(
                    value: value,
                    child: Text(dateFilterLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onDateFilterChanged(value);
            },
          ),
          const SizedBox(height: 10),
          _InlineDropdown<String>(
            label: 'Category',
            value: selectedCategory,
            items: categories
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: onlyWithAvailableTickets,
            onChanged: onOnlyWithTicketsChanged,
            title: const Text('Only events with available tickets'),
          ),
        ],
      ),
    );
  }
}

class _InlineDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _InlineDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CompanyPublicEventCard extends StatelessWidget {
  final Event event;
  final bool showVisibility;
  final VoidCallback onTap;

  const _CompanyPublicEventCard({
    required this.event,
    required this.showVisibility,
    required this.onTap,
  });

  static String _formatDateTime(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    event.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Created: ${_formatDateTime(event.createdAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Event date: ${_formatDateTime(event.date)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.locationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  event.totalRemaining > 0
                      ? '${event.totalRemaining} tickets available'
                      : 'Sold out',
                  style: TextStyle(
                    color: event.totalRemaining > 0
                        ? AppColors.accent
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showVisibility) ...[
                  const SizedBox(width: 8),
                  Text(
                    event.isActive ? 'Active' : 'Hidden',
                    style: TextStyle(
                      color: event.isActive
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompanyEvents extends StatelessWidget {
  const _EmptyCompanyEvents();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No events found with current filters.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing search, date filter, category or sorting.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
