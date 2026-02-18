import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/features/events/presentation/screens/company_profile_screen.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';

enum _CompanyFilter { all, verified, withActiveEvents, withoutActiveEvents }

enum _CompanySort {
  featured,
  nameAz,
  nameZa,
  activeEventsDesc,
  newestCreated,
  oldestCreated,
}

class CompaniesDirectoryScreen extends StatefulWidget {
  const CompaniesDirectoryScreen({super.key});

  @override
  State<CompaniesDirectoryScreen> createState() =>
      _CompaniesDirectoryScreenState();
}

class _CompaniesDirectoryScreenState extends State<CompaniesDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  _CompanyFilter _filter = _CompanyFilter.all;
  _CompanySort _sort = _CompanySort.featured;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final sokaService = context.read<SokaService>();
    await sokaService.fetchCompanies();
    await sokaService.fetchEvents();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _matchesCompanyOrganizer(Event event, Company company) {
    final organizerRaw = event.organizerId.trim();
    if (organizerRaw.isEmpty) return false;

    final rawCompanyName = company.companyName.trim();
    final rawCompanyId = company.id.trim();
    final rawCompanyEmail = company.contactInfo.email.trim();
    final rawCompanyInstagram = company.contactInfo.instagram.trim();

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

  Map<String, _CompanyStats> _buildStats(
    List<Company> companies,
    List<Event> allEvents,
  ) {
    final eventById = <String, Event>{for (final e in allEvents) e.id: e};
    final statsById = <String, _CompanyStats>{};

    for (final company in companies) {
      final linkedEvents = company.createdEventIds
          .map((id) => eventById[id])
          .whereType<Event>()
          .toList();

      final detectedEvents = allEvents
          .where((event) => _matchesCompanyOrganizer(event, company))
          .toList();

      final merged = <String, Event>{
        for (final event in linkedEvents) event.id: event,
        for (final event in detectedEvents) event.id: event,
      };

      final events = merged.values.toList();
      final activeCount = events.where((event) => event.isActive).length;
      statsById[company.id] = _CompanyStats(
        totalEvents: events.length,
        activeEvents: activeCount,
      );
    }

    return statsById;
  }

  String _filterLabel(_CompanyFilter filter) {
    switch (filter) {
      case _CompanyFilter.all:
        return 'All companies';
      case _CompanyFilter.verified:
        return 'Verified only';
      case _CompanyFilter.withActiveEvents:
        return 'With active events';
      case _CompanyFilter.withoutActiveEvents:
        return 'Without active events';
    }
  }

  String _sortLabel(_CompanySort sort) {
    switch (sort) {
      case _CompanySort.featured:
        return 'Featured';
      case _CompanySort.nameAz:
        return 'Name A-Z';
      case _CompanySort.nameZa:
        return 'Name Z-A';
      case _CompanySort.activeEventsDesc:
        return 'More active events';
      case _CompanySort.newestCreated:
        return 'Newest companies';
      case _CompanySort.oldestCreated:
        return 'Oldest companies';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sokaService = context.watch<SokaService>();
    final companies = sokaService.companies
        .where((company) => company.id.trim().isNotEmpty)
        .toList();
    final statsById = _buildStats(companies, sokaService.events);

    final query = _searchController.text.trim().toLowerCase();
    final filtered = companies.where((company) {
      final stats = statsById[company.id] ?? const _CompanyStats();

      if (_filter == _CompanyFilter.verified && !company.verified) {
        return false;
      }
      if (_filter == _CompanyFilter.withActiveEvents &&
          stats.activeEvents <= 0) {
        return false;
      }
      if (_filter == _CompanyFilter.withoutActiveEvents &&
          stats.activeEvents > 0) {
        return false;
      }

      if (query.isEmpty) return true;
      return company.companyName.toLowerCase().contains(query) ||
          company.description.toLowerCase().contains(query) ||
          company.contactInfo.email.toLowerCase().contains(query) ||
          company.contactInfo.instagram.toLowerCase().contains(query) ||
          company.contactInfo.website.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final statsA = statsById[a.id] ?? const _CompanyStats();
      final statsB = statsById[b.id] ?? const _CompanyStats();

      switch (_sort) {
        case _CompanySort.featured:
          final verifiedCompare = (b.verified ? 1 : 0).compareTo(
            a.verified ? 1 : 0,
          );
          if (verifiedCompare != 0) return verifiedCompare;
          final activeCompare = statsB.activeEvents.compareTo(
            statsA.activeEvents,
          );
          if (activeCompare != 0) return activeCompare;
          final totalCompare = statsB.totalEvents.compareTo(statsA.totalEvents);
          if (totalCompare != 0) return totalCompare;
          return b.createdAt.compareTo(a.createdAt);
        case _CompanySort.nameAz:
          return a.companyName.toLowerCase().compareTo(
            b.companyName.toLowerCase(),
          );
        case _CompanySort.nameZa:
          return b.companyName.toLowerCase().compareTo(
            a.companyName.toLowerCase(),
          );
        case _CompanySort.activeEventsDesc:
          final activeCompare = statsB.activeEvents.compareTo(
            statsA.activeEvents,
          );
          if (activeCompare != 0) return activeCompare;
          return b.createdAt.compareTo(a.createdAt);
        case _CompanySort.newestCreated:
          return b.createdAt.compareTo(a.createdAt);
        case _CompanySort.oldestCreated:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All companies'),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _FiltersBox(
              searchController: _searchController,
              filter: _filter,
              sort: _sort,
              filterLabel: _filterLabel,
              sortLabel: _sortLabel,
              onFilterChanged: (value) {
                setState(() => _filter = value);
              },
              onSortChanged: (value) {
                setState(() => _sort = value);
              },
            ),
            const SizedBox(height: 12),
            Text(
              '${filtered.length} companies',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              const _NoCompanies()
            else
              ...filtered.map((company) {
                final stats = statsById[company.id] ?? const _CompanyStats();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompanyCard(
                    company: company,
                    stats: stats,
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompanyProfileScreen(
                            companyId: company.id,
                            initialCompany: company,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _FiltersBox extends StatelessWidget {
  final TextEditingController searchController;
  final _CompanyFilter filter;
  final _CompanySort sort;
  final String Function(_CompanyFilter) filterLabel;
  final String Function(_CompanySort) sortLabel;
  final ValueChanged<_CompanyFilter> onFilterChanged;
  final ValueChanged<_CompanySort> onSortChanged;

  const _FiltersBox({
    required this.searchController,
    required this.filter,
    required this.sort,
    required this.filterLabel,
    required this.sortLabel,
    required this.onFilterChanged,
    required this.onSortChanged,
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
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search company',
              hintText: 'Name, description, email, instagram...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          _InlineDropdown<_CompanyFilter>(
            label: 'Filter',
            value: filter,
            items: _CompanyFilter.values
                .map(
                  (value) => DropdownMenuItem<_CompanyFilter>(
                    value: value,
                    child: Text(filterLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onFilterChanged(value);
            },
          ),
          const SizedBox(height: 10),
          _InlineDropdown<_CompanySort>(
            label: 'Sort',
            value: sort,
            items: _CompanySort.values
                .map(
                  (value) => DropdownMenuItem<_CompanySort>(
                    value: value,
                    child: Text(sortLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
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
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final _CompanyStats stats;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.company,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = company.companyName.trim().isEmpty
        ? 'Company'
        : company.companyName.trim();
    final description = company.description.trim();

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompanyAvatar(company: company),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (company.verified)
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description.isEmpty
                        ? 'No description available'
                        : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniPill(
                        label: '${stats.activeEvents} active',
                        color: stats.activeEvents > 0
                            ? Colors.green.withValues(alpha: 0.14)
                            : AppColors.secondary,
                        textColor: stats.activeEvents > 0
                            ? Colors.green.shade200
                            : AppColors.textSecondary,
                      ),
                      _MiniPill(
                        label: '${stats.totalEvents} total events',
                        color: AppColors.secondary,
                        textColor: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  final Company company;

  const _CompanyAvatar({required this.company});

  bool get _hasImage {
    final url = company.profileImageUrl.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final initials = company.companyName.trim().isEmpty
        ? 'C'
        : company.companyName.trim().substring(0, 1).toUpperCase();
    if (!_hasImage) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.accent,
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        company.profileImageUrl.trim(),
        fit: BoxFit.cover,
        alignment: Alignment(
          company.profileImageOffsetX.clamp(-1.0, 1.0),
          company.profileImageOffsetY.clamp(-1.0, 1.0),
        ),
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _MiniPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoCompanies extends StatelessWidget {
  const _NoCompanies();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.business_outlined, size: 42, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'No companies found with current filters.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompanyStats {
  final int totalEvents;
  final int activeEvents;

  const _CompanyStats({this.totalEvents = 0, this.activeEvents = 0});
}
