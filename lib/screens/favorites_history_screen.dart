import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/widgets/event_card.dart';

class FavoritesHistoryScreen extends StatelessWidget {
  final Client client;
  final Future<void> Function(String eventId) onToggleFavorite;

  const FavoritesHistoryScreen({
    super.key,
    required this.client,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final events = context.watch<SokaService>().events;
    final eventById = <String, Event>{for (final e in events) e.id: e};

    final favoriteEvents = client.favoriteEventIds
        .map((id) => eventById[id])
        .whereType<Event>()
        .toList();

    final historyEvents = client.historyEventIds
        .map((id) => eventById[id])
        .whereType<Event>()
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _FavoritesHistoryHeader(
                  favoriteCount: client.favoriteEventIds.length,
                  historyCount: client.historyEventIds.length,
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: -22,
                  child: _TabsCard(),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Expanded(
              child: TabBarView(
                children: [
                  _EventsList(
                    events: favoriteEvents,
                    idsCount: client.favoriteEventIds.length,
                    emptyIcon: Icons.favorite_border_rounded,
                    emptyTitle: 'No favorite events yet',
                    emptySubtitle:
                        'Save events with the heart to always have them handy.',
                    favoriteEventIds: client.favoriteEventIds,
                    onToggleFavorite: onToggleFavorite,
                  ),
                  _EventsList(
                    events: historyEvents,
                    idsCount: client.historyEventIds.length,
                    emptyIcon: Icons.history_rounded,
                    emptyTitle: 'Your history is empty',
                    emptySubtitle:
                        'Here you will see the events you have participated in.',
                    favoriteEventIds: client.favoriteEventIds,
                    onToggleFavorite: onToggleFavorite,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHistoryHeader extends StatelessWidget {
  final int favoriteCount;
  final int historyCount;

  const _FavoritesHistoryHeader({
    required this.favoriteCount,
    required this.historyCount,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = (favoriteCount == 0 && historyCount == 0)
        ? 'Save events and check your activity.'
        : '$favoriteCount favorite${favoriteCount == 1 ? '' : 's'} · '
            '$historyCount in history';

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favorites',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
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

class _TabsCard extends StatelessWidget {
  const _TabsCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.favorite_rounded), text: 'Favorites'),
                Tab(icon: Icon(Icons.history_rounded), text: 'History'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<Event> events;
  final int idsCount;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final List<String> favoriteEventIds;
  final Future<void> Function(String eventId) onToggleFavorite;

  const _EventsList({
    required this.events,
    required this.idsCount,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = events.isNotEmpty;
    final hasEventsLoaded = context.read<SokaService>().events.isNotEmpty;

    Widget child;
    if (!hasData) {
      final subtitle = idsCount > 0 && !hasEventsLoaded
          ? 'Events have not been loaded yet. Swipe to refresh.'
          : (idsCount > 0 && hasEventsLoaded
              ? 'We couldn\'t find these events. They may no longer be available.'
              : emptySubtitle);

      child = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
        children: [
          const SizedBox(height: 32),
          _EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: subtitle,
          ),
        ],
      );
    } else {
      child = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final isFavorite = favoriteEventIds.contains(event.id);

          return EventCard(
            event: event,
            showFavoriteButton: true,
            isFavorite: isFavorite,
            onToggleFavorite: () => onToggleFavorite(event.id),
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.primary,
      onRefresh: () => context.read<SokaService>().fetchEvents(),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 64,
          color: AppColors.cursorColor,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.cursorColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
