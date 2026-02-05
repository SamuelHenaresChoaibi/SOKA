import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/screens/calendar_screen.dart';
import 'package:soka/screens/photos_screen.dart';
import 'package:soka/screens/settings_screen.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadEvents);
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
        _errorMessage = 'No se pudieron cargar los eventos.';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<SokaService>(context).events;
    final theme = Theme.of(context);
    final categorySet = <String>{...events.map((event) => event.category)};
    final categories = <String>['Todos', ...categorySet];
    final safeSelectedIndex = _selectedCategoryIndex
        .clamp(0, categories.length - 1)
        .toInt();
    final selectedCategory = categories[safeSelectedIndex];
    final categoryFiltered = selectedCategory == 'Todos'
        ? events
        : events
            .where((event) => event.category == selectedCategory)
            .toList();
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
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
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
                            child: const Text('Reintentar'),
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
                      'Eventos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: theme.textTheme.bodyMedium?.color ??
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
                              'No hay eventos disponibles',
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          EventCard(event: filteredEvents[index]),
                      childCount: filteredEvents.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ],
          ),
        ),
      ),
      const CalendarScreen(),
      const PhotosScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.accent,
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return theme.textTheme.bodySmall?.copyWith(
              color: AppColors.cursorColor,
            );
          },
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Fotos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
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
