import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/screens/calendar_screen.dart';
import 'package:soka/screens/company_events_screen.dart';
import 'package:soka/screens/favorites_history_screen.dart';
import 'package:soka/screens/settings_screen.dart';
import 'package:soka/screens/ticket_scan_screen.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/widgets/widgets.dart';

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
  String? _userId;
  Client? _client;
  Company? _company;
  bool _isProfileLoading = false;
  StreamSubscription<User?>? _authSubscription;

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
      await Provider.of<SokaService>(context, listen: false).fetchEvents();
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

    try {
      await sokaService.fetchSoldTickets();
    } catch (_) {
      return;
    }

    final ticketEventIds = sokaService.soldTickets
        .where(
          (t) => t.buyerUserId == clientId || t.buyerUserId == client.userName,
        )
        .map((t) => t.eventId.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (ticketEventIds.isEmpty) return;

    final updatedHistory = List<String>.from(client.historyEventIds);
    for (final id in ticketEventIds) {
      if (!updatedHistory.contains(id)) {
        updatedHistory.add(id);
      }
    }

    if (updatedHistory.length == client.historyEventIds.length) return;

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

  Future<void> _openTicketScanner({
    required bool isCompanyUser,
    required bool isClientUser,
  }) async {
    if (!isCompanyUser && !isClientUser) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitas perfil de cliente o compañía para escanear.',
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
          content: Text('Cliente satisfecho'),
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
    final filteredEvents = query.isEmpty
        ? categoryFiltered
        : categoryFiltered.where((event) {
            return event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                event.location.toLowerCase().contains(query) ||
                event.category.toLowerCase().contains(query);
          }).toList();

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
                    eventCount: events.length,
                    onSearchChanged: (value) {
                      setState(() => _query = value);
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
                    child: EventSlider(events: filteredEvents),
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
            ? Icons.favorite_border
            : isCompanyUser
            ? Icons.event_note_outlined
            : Icons.person_outline,
      ),
      selectedIcon: Icon(
        isClientUser
            ? Icons.favorite
            : isCompanyUser
            ? Icons.event_note
            : Icons.person,
      ),
      label: isClientUser
          ? 'Favorites'
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
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(MaterialState.selected)) {
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
