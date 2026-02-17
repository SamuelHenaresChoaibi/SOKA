import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/features/home/presentation/screens/calendar_screen.dart';
import 'package:soka/features/events/presentation/screens/company_events_screen.dart';
import 'package:soka/features/events/presentation/screens/favorites_history_screen.dart';
import 'package:soka/features/settings/presentation/screens/settings_screen.dart';
import 'package:soka/features/tickets/presentation/screens/ticket_scan_screen.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/shared/widgets/widgets.dart';

enum _EventDateFilter { all, upcoming, thisWeek, thisMonth }

enum _EventSortFilter { defaultOrder, nearestDate, latestDate, titleAz }

class _EventFiltersResult {
  final String category;
  final String companyQuery;
  final _EventDateFilter dateFilter;
  final _EventSortFilter sortFilter;
  final bool onlyWithAvailableTickets;

  const _EventFiltersResult({
    required this.category,
    required this.companyQuery,
    required this.dateFilter,
    required this.sortFilter,
    required this.onlyWithAvailableTickets,
  });
}

class _EventFiltersSheet extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final String initialCompanyQuery;
  final _EventDateFilter initialDateFilter;
  final _EventSortFilter initialSortFilter;
  final bool initialOnlyWithTickets;
  final List<String> companySuggestions;

  const _EventFiltersSheet({
    required this.categories,
    required this.selectedCategory,
    required this.initialCompanyQuery,
    required this.initialDateFilter,
    required this.initialSortFilter,
    required this.initialOnlyWithTickets,
    required this.companySuggestions,
  });

  @override
  State<_EventFiltersSheet> createState() => _EventFiltersSheetState();
}

class _EventFiltersSheetState extends State<_EventFiltersSheet> {
  late String _localCategory;
  late _EventDateFilter _localDateFilter;
  late _EventSortFilter _localSortFilter;
  late bool _localOnlyWithTickets;
  late final TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _localCategory = widget.selectedCategory;
    _localDateFilter = widget.initialDateFilter;
    _localSortFilter = widget.initialSortFilter;
    _localOnlyWithTickets = widget.initialOnlyWithTickets;
    _companyController = TextEditingController(text: widget.initialCompanyQuery)
      ..addListener(_onCompanyQueryChanged);
  }

  @override
  void dispose() {
    _companyController.removeListener(_onCompanyQueryChanged);
    _companyController.dispose();
    super.dispose();
  }

  void _onCompanyQueryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _labelForDateFilter(_EventDateFilter filter) {
    switch (filter) {
      case _EventDateFilter.all:
        return 'All';
      case _EventDateFilter.upcoming:
        return 'Upcoming';
      case _EventDateFilter.thisWeek:
        return 'This week';
      case _EventDateFilter.thisMonth:
        return 'This month';
    }
  }

  String _labelForSortFilter(_EventSortFilter filter) {
    switch (filter) {
      case _EventSortFilter.defaultOrder:
        return 'Proximity';
      case _EventSortFilter.nearestDate:
        return 'Nearest first';
      case _EventSortFilter.latestDate:
        return 'Latest';
      case _EventSortFilter.titleAz:
        return 'Name (A-Z)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final normalizedCompanyQuery = _companyController.text.trim().toLowerCase();
    final matchingCompanies = normalizedCompanyQuery.isEmpty
        ? <String>[]
        : widget.companySuggestions
              .where(
                (companyName) =>
                    companyName.toLowerCase().contains(normalizedCompanyQuery),
              )
              .take(8)
              .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: widget.categories.contains(_localCategory)
                  ? _localCategory
                  : widget.categories.first,
              decoration: const InputDecoration(labelText: 'Event type'),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _localCategory = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company name',
                hintText: 'E.g. Soka Events',
              ),
            ),
            if (matchingCompanies.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.cursorColor.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: matchingCompanies.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, thickness: 1),
                  itemBuilder: (context, index) {
                    final companyName = matchingCompanies[index];
                    return ListTile(
                      dense: true,
                      title: Text(companyName),
                      onTap: () {
                        _companyController.value = TextEditingValue(
                          text: companyName,
                          selection: TextSelection.collapsed(
                            offset: companyName.length,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<_EventDateFilter>(
              initialValue: _localDateFilter,
              decoration: const InputDecoration(labelText: 'Event date'),
              items: _EventDateFilter.values
                  .map(
                    (filter) => DropdownMenuItem<_EventDateFilter>(
                      value: filter,
                      child: Text(_labelForDateFilter(filter)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _localDateFilter = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_EventSortFilter>(
              initialValue: _localSortFilter,
              decoration: const InputDecoration(labelText: 'Sort'),
              items: _EventSortFilter.values
                  .map(
                    (filter) => DropdownMenuItem<_EventSortFilter>(
                      value: filter,
                      child: Text(_labelForSortFilter(filter)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _localSortFilter = value);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Only with available tickets'),
              value: _localOnlyWithTickets,
              onChanged: (value) {
                setState(() => _localOnlyWithTickets = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const _EventFiltersResult(
                          category: 'All',
                          companyQuery: '',
                          dateFilter: _EventDateFilter.all,
                          sortFilter: _EventSortFilter.defaultOrder,
                          onlyWithAvailableTickets: false,
                        ),
                      );
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _EventFiltersResult(
                          category: _localCategory,
                          companyQuery: _companyController.text.trim(),
                          dateFilter: _localDateFilter,
                          sortFilter: _localSortFilter,
                          onlyWithAvailableTickets: _localOnlyWithTickets,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  String _companyNameQuery = '';
  _EventDateFilter _eventDateFilter = _EventDateFilter.all;
  _EventSortFilter _eventSortFilter = _EventSortFilter.defaultOrder;
  bool _onlyWithAvailableTickets = false;
  final Map<String, String> _organizerNameById = {};
  String? _userId;
  Client? _client;
  Company? _company;
  bool _isProfileLoading = false;
  StreamSubscription<User?>? _authSubscription;
  Position? _userPosition;
  bool _isResolvingLocation = false;

  @override
  void initState() {
    super.initState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _userId = null;
          _client = null;
          _company = null;
          _isProfileLoading = false;
        });
        return;
      }

      if (_isProfileLoading && _userId == user.uid) return;
      await _loadUserProfile(user: user);
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Future.microtask(() {
        _loadUserProfile(user: currentUser);
      });
    }

    Future.microtask(_loadEvents);
    Future.microtask(_loadUserLocation);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sokaService = Provider.of<SokaService>(context, listen: false);
      await sokaService.fetchEvents();
      await _warmOrganizerNames(sokaService.events);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Events could not be loaded. Please check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserLocation() async {
    if (!mounted || _isResolvingLocation) return;
    setState(() => _isResolvingLocation = true);

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      setState(() => _userPosition = position);
    } catch (_) {
      // no-op
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  Future<void> _loadUserProfile({User? user}) async {
    user ??= FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() {
      _isProfileLoading = true;
      _userId = user!.uid;
    });

    final sokaService = context.read<SokaService>();
    Client? client;
    Company? company;

    try {
      try {
        client = await sokaService.fetchClientById(user.uid);
      } catch (_) {
        // no-op (we still want to try loading the company profile)
      }

      try {
        company = await sokaService.fetchCompanyById(user.uid);
      } catch (_) {
        // no-op
      }

      if (!mounted) return;
      setState(() {
        _client = client;
        _company = company;
      });

      if (client != null && company == null) {
        await _syncHistoryFromTickets(client);
      }
    } finally {
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
    }
  }

  Future<void> _syncHistoryFromTickets(Client client) async {
    final clientId = _userId;
    if (clientId == null) return;

    final sokaService = context.read<SokaService>();
    final now = DateTime.now();

    try {
      await sokaService.fetchSoldTickets();
    } catch (_) {
      return;
    }

    if (sokaService.events.isEmpty) {
      try {
        await sokaService.fetchEvents();
      } catch (_) {
        // no-op
      }
    }

    final eventById = <String, Event>{for (final e in sokaService.events) e.id: e};

    final attendedPastEventIds = sokaService.soldTickets
        .where(
          (t) =>
              (t.buyerUserId == clientId || t.buyerUserId == client.userName) &&
              t.isCheckedIn,
        )
        .map((t) => eventById[t.eventId.trim()])
        .whereType<Event>()
        .where((event) => event.date.isBefore(now))
        .map((event) => event.id)
        .toSet()
        .toList()
      ..sort((a, b) {
        final dateA = eventById[a]?.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = eventById[b]?.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    final updatedHistory = attendedPastEventIds
        .where((id) => id.isNotEmpty)
        .toList();

    final currentHistory = client.historyEventIds;
    if (updatedHistory.length == currentHistory.length &&
        updatedHistory.asMap().entries.every(
          (entry) => currentHistory[entry.key] == entry.value,
        )) {
      return;
    }

    final updatedClient = client.copyWith(historyEventIds: updatedHistory);
    if (!mounted) return;
    setState(() => _client = updatedClient);

    try {
      await sokaService.updateClient(clientId, {
        'historyEventIds': updatedHistory,
      });
    } catch (_) {
      // no-op
    }
  }

  Future<void> _toggleFavorite(String eventId) async {
    final clientId = _userId;
    final currentClient = _client;
    if (clientId == null || currentClient == null) return;

    final previousFavorites = List<String>.from(currentClient.favoriteEventIds);
    final updatedFavorites = List<String>.from(previousFavorites);
    if (updatedFavorites.contains(eventId)) {
      updatedFavorites.remove(eventId);
    } else {
      updatedFavorites.add(eventId);
    }

    setState(() {
      _client = currentClient.copyWith(favoriteEventIds: updatedFavorites);
    });

    try {
      await context.read<SokaService>().updateClient(clientId, {
        'favoriteEventIds': updatedFavorites,
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _client = currentClient.copyWith(favoriteEventIds: previousFavorites);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites')),
      );
    }
  }

  Future<void> _warmOrganizerNames(List<Event> events) async {
    final missingOrganizerIds = events
        .map((event) => event.organizerId.trim())
        .where((id) => id.isNotEmpty && !_organizerNameById.containsKey(id))
        .toSet()
        .toList();

    if (missingOrganizerIds.isEmpty) return;

    final sokaService = context.read<SokaService>();
    final loadedEntries = await Future.wait(
      missingOrganizerIds.map((organizerId) async {
        try {
          final company = await sokaService.fetchCompanyById(organizerId);
          final companyName = company?.companyName.trim() ?? '';
          return MapEntry(
            organizerId,
            companyName.isEmpty ? organizerId : companyName,
          );
        } catch (_) {
          return MapEntry(organizerId, organizerId);
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      for (final entry in loadedEntries) {
        _organizerNameById[entry.key] = entry.value;
      }
    });
  }

  String _organizerNameForEvent(Event event) {
    final organizerId = event.organizerId.trim();
    if (organizerId.isEmpty) return 'No company';
    return _organizerNameById[organizerId] ?? organizerId;
  }

  bool _matchesDateFilter(DateTime eventDate) {
    if (_eventDateFilter == _EventDateFilter.all) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(eventDate.year, eventDate.month, eventDate.day);

    switch (_eventDateFilter) {
      case _EventDateFilter.all:
        return true;
      case _EventDateFilter.upcoming:
        return !date.isBefore(today);
      case _EventDateFilter.thisWeek:
        final weekEnd = today.add(const Duration(days: 7));
        return !date.isBefore(today) && date.isBefore(weekEnd);
      case _EventDateFilter.thisMonth:
        return date.year == now.year &&
            date.month == now.month &&
            !date.isBefore(today);
    }
  }

  String _labelForDateFilter(_EventDateFilter filter) {
    switch (filter) {
      case _EventDateFilter.all:
        return 'All';
      case _EventDateFilter.upcoming:
        return 'Upcoming';
      case _EventDateFilter.thisWeek:
        return 'This week';
      case _EventDateFilter.thisMonth:
        return 'This month';
    }
  }

  String _labelForSortFilter(_EventSortFilter filter) {
    switch (filter) {
      case _EventSortFilter.defaultOrder:
        return 'Proximity';
      case _EventSortFilter.nearestDate:
        return 'Nearest first';
      case _EventSortFilter.latestDate:
        return 'Latest';
      case _EventSortFilter.titleAz:
        return 'Name (A-Z)';
    }
  }

  void _sortEvents(List<Event> events) {
    switch (_eventSortFilter) {
      case _EventSortFilter.defaultOrder:
        _sortEventsByProximityOrDate(events);
        return;
      case _EventSortFilter.nearestDate:
        _sortEventsByProximityOrDate(events);
        return;
      case _EventSortFilter.latestDate:
        events.sort((a, b) => b.date.compareTo(a.date));
        return;
      case _EventSortFilter.titleAz:
        events.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        return;
    }
  }

  void _sortEventsByProximityOrDate(List<Event> events) {
    final userPosition = _userPosition;
    if (userPosition == null) {
      events.sort((a, b) => a.date.compareTo(b.date));
      return;
    }

    events.sort(
      (a, b) => _compareEventsByProximity(
        a,
        b,
        userPosition.latitude,
        userPosition.longitude,
      ),
    );
  }

  int _compareEventsByProximity(
    Event a,
    Event b,
    double userLat,
    double userLng,
  ) {
    final aHasCoords = a.locationLat != null && a.locationLng != null;
    final bHasCoords = b.locationLat != null && b.locationLng != null;

    if (aHasCoords && bHasCoords) {
      final aDistance = Geolocator.distanceBetween(
        userLat,
        userLng,
        a.locationLat!,
        a.locationLng!,
      );
      final bDistance = Geolocator.distanceBetween(
        userLat,
        userLng,
        b.locationLat!,
        b.locationLng!,
      );
      final distanceCompare = aDistance.compareTo(bDistance);
      if (distanceCompare != 0) return distanceCompare;
      return a.date.compareTo(b.date);
    }

    if (aHasCoords && !bHasCoords) return -1;
    if (!aHasCoords && bHasCoords) return 1;
    return a.date.compareTo(b.date);
  }

  List<Event> _nearbyEvents(List<Event> events) {
    final now = DateTime.now();
    final upcomingEvents = events
        .where((event) => !event.date.isBefore(now))
        .toList();

    if (upcomingEvents.isEmpty) {
      return events.take(8).toList();
    }

    final userPosition = _userPosition;
    if (userPosition == null) {
      upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
      return upcomingEvents.take(8).toList();
    }

    final eventsWithCoords = upcomingEvents
        .where((event) => event.locationLat != null && event.locationLng != null)
        .toList()
      ..sort(
        (a, b) => _compareEventsByProximity(
          a,
          b,
          userPosition.latitude,
          userPosition.longitude,
        ),
      );

    final eventsWithoutCoords = upcomingEvents
        .where((event) => event.locationLat == null || event.locationLng == null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return [...eventsWithCoords, ...eventsWithoutCoords].take(8).toList();
  }

  Future<void> _openEventFilters({
    required List<Event> events,
    required List<String> categories,
    required String selectedCategory,
  }) async {
    final companySuggestions = <String>{
      ..._organizerNameById.values.map((name) => name.trim()),
      ...events
          .map((event) => _organizerNameForEvent(event).trim())
          .where((name) => name.isNotEmpty),
    }.where((name) => name.isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final result = await showModalBottomSheet<_EventFiltersResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EventFiltersSheet(
        categories: categories,
        selectedCategory: selectedCategory,
        initialCompanyQuery: _companyNameQuery,
        initialDateFilter: _eventDateFilter,
        initialSortFilter: _eventSortFilter,
        initialOnlyWithTickets: _onlyWithAvailableTickets,
        companySuggestions: companySuggestions,
      ),
    );

    if (!mounted || result == null) return;
    final categoryIndex = categories.indexOf(result.category);
    setState(() {
      _companyNameQuery = result.companyQuery;
      _eventDateFilter = result.dateFilter;
      _eventSortFilter = result.sortFilter;
      _onlyWithAvailableTickets = result.onlyWithAvailableTickets;
      _selectedCategoryIndex = categoryIndex < 0 ? 0 : categoryIndex;
    });
  }

  Future<void> _openTicketScanner({
    required bool isCompanyUser,
    required bool isClientUser,
  }) async {
    if (!isCompanyUser && !isClientUser) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need a client or company profile to scan.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final scannerMode = isCompanyUser
        ? TicketScannerMode.company
        : TicketScannerMode.client;

    final validated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TicketScanScreen(mode: scannerMode)),
    );

    if (!mounted) return;
    if (isCompanyUser && validated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client satisfiedly checked in!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<SokaService>(context).events;
    final theme = Theme.of(context);
    final isCompanyUser = _company != null;
    final isClientUser = _client != null && !isCompanyUser;
    final categorySet = <String>{...events.map((event) => event.category)};
    final categories = <String>['All', ...categorySet];
    final safeSelectedIndex = _selectedCategoryIndex
        .clamp(0, categories.length - 1)
        .toInt();
    final selectedCategory = categories[safeSelectedIndex];
    final categoryFiltered = selectedCategory == 'All'
        ? events
        : events.where((event) => event.category == selectedCategory).toList();
    final query = _query.trim().toLowerCase();
    final companyNameQuery = _companyNameQuery.trim().toLowerCase();

    final textFiltered = query.isEmpty
        ? categoryFiltered
        : categoryFiltered.where((event) {
            final organizerName = _organizerNameForEvent(event).toLowerCase();
            return event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                event.location.toLowerCase().contains(query) ||
                event.category.toLowerCase().contains(query) ||
                organizerName.contains(query);
          }).toList();

    final filteredEvents = textFiltered.where((event) {
      final organizerName = _organizerNameForEvent(event).toLowerCase();
      final companyMatch =
          companyNameQuery.isEmpty || organizerName.contains(companyNameQuery);
      final dateMatch = _matchesDateFilter(event.date);
      final availabilityMatch =
          !_onlyWithAvailableTickets || event.totalRemaining > 0;
      return companyMatch && dateMatch && availabilityMatch;
    }).toList();

    _sortEvents(filteredEvents);
    final nearbyEvents = _nearbyEvents(filteredEvents);
    final nearbyTitle = _userPosition == null
        ? 'Eventos cercanos (activa ubicacion para mejorar)'
        : 'Eventos cerca de ti';

    final pages = [
      // HOME REAL
      Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.primary,
          onRefresh: _loadEvents,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  child: HomeHeader(
                    eventCount: filteredEvents.length,
                    onSearchChanged: (value) {
                      setState(() => _query = value);
                    },
                    onFilterTap: () {
                      _openEventFilters(
                        events: events,
                        categories: categories,
                        selectedCategory: selectedCategory,
                      );
                    },
                    onQrTap: () {
                      _openTicketScanner(
                        isCompanyUser: isCompanyUser,
                        isClientUser: isClientUser,
                      );
                    },
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (_errorMessage != null && events.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 56,
                            color: AppColors.cursorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.cursorColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadEvents,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: CategoryBar(
                    categories: categories,
                    selectedIndex: safeSelectedIndex,
                    onSelected: (index) {
                      setState(() => _selectedCategoryIndex = index);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: EventSlider(
                      events: nearbyEvents,
                      title: nearbyTitle,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Text(
                      'Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color:
                            theme.textTheme.bodyMedium?.color ??
                            AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (filteredEvents.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: AppColors.cursorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events available for the selected category or search query.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.cursorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = filteredEvents[index];
                      final isFavorite =
                          isClientUser &&
                          (_client?.favoriteEventIds.contains(event.id) ??
                              false);

                      return EventCard(
                        event: event,
                        showFavoriteButton: isClientUser,
                        isFavorite: isFavorite,
                        onToggleFavorite: isClientUser
                            ? () {
                                _toggleFavorite(event.id);
                              }
                            : null,
                      );
                    }, childCount: filteredEvents.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ],
          ),
        ),
      ),
      const CalendarScreen(),
      if (_isProfileLoading && _userId != null)
        const Center(child: CircularProgressIndicator())
      else if (isClientUser)
        FavoritesHistoryScreen(
          userId: _userId!,
          client: _client!,
          onToggleFavorite: _toggleFavorite,
        )
      else if (isCompanyUser)
        CompanyEventsScreen(
          companyId: _userId!,
          company: _company!,
          onCompanyUpdated: (company) {
            setState(() => _company = company);
          },
        )
      else
        _NoProfileScreen(
          onRetry: () {
            _loadUserProfile();
          },
        ),
      const SettingsScreen(),
    ];

    final thirdDestination = NavigationDestination(
      icon: Icon(
        isClientUser
            ? Icons.event_outlined
            : isCompanyUser
            ? Icons.event_note_outlined
            : Icons.person_outline,
      ),
      selectedIcon: Icon(
        isClientUser
            ? Icons.event
            : isCompanyUser
            ? Icons.event_note
            : Icons.person,
      ),
      label: isClientUser
          ? 'Eventos'
          : isCompanyUser
          ? 'My Events'
          : 'Account',
    );

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.accent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return theme.textTheme.bodySmall?.copyWith(
            color: AppColors.cursorColor,
          );
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          thirdDestination,
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _HomeHeaderDelegate({required this.child});

  @override
  double get minExtent => 230;

  @override
  double get maxExtent => 230;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _NoProfileScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoProfileScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 56,
              color: AppColors.cursorColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No user or company profile found for this account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.cursorColor,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
