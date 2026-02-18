import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/features/tickets/presentation/screens/ticket_details_screen.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/shared/widgets/event_card.dart';

class FavoritesHistoryScreen extends StatelessWidget {
  final String userId;
  final Client client;
  final Future<void> Function(String eventId) onToggleFavorite;

  const FavoritesHistoryScreen({
    super.key,
    required this.userId,
    required this.client,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final events = context.watch<SokaService>().events;
    final allEventById = <String, Event>{for (final e in events) e.id: e};
    final activeEventById = <String, Event>{
      for (final e in events)
        if (e.isActive) e.id: e,
    };

    final favoriteEvents = client.favoriteEventIds
        .map((id) => activeEventById[id])
        .whereType<Event>()
        .toList();
    final purchasedTickets =
        context
            .watch<SokaService>()
            .soldTickets
            .where(
              (ticket) =>
                  ticket.buyerUserId == userId ||
                  ticket.buyerUserId == client.userName,
            )
            .toList()
          ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _FavoritesHistoryHeader(
              eventsCount: client.favoriteEventIds.length,
              ticketsCount: purchasedTickets.length,
            ),
            const _TabsCard(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _EventsList(
                    events: favoriteEvents,
                    idsCount: client.favoriteEventIds.length,
                    emptyIcon: Icons.event_note_rounded,
                    emptyTitle: 'No events saved yet',
                    emptySubtitle:
                        'Save events with the heart to always have them handy.',
                    favoriteEventIds: client.favoriteEventIds,
                    onToggleFavorite: onToggleFavorite,
                  ),
                  _TicketsList(
                    tickets: purchasedTickets,
                    eventById: allEventById,
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
  final int eventsCount;
  final int ticketsCount;

  const _FavoritesHistoryHeader({
    required this.eventsCount,
    required this.ticketsCount,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = '$eventsCount events · $ticketsCount tickets';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Events & Tickets',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            Tab(icon: Icon(Icons.event_rounded), text: 'Events'),
            Tab(icon: Icon(Icons.confirmation_number_rounded), text: 'Tickets'),
          ],
        ),
      ),
    );
  }
}

class _TicketsList extends StatelessWidget {
  final List<SoldTicket> tickets;
  final Map<String, Event> eventById;

  const _TicketsList({required this.tickets, required this.eventById});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.primary,
        onRefresh: () async {
          await context.read<SokaService>().fetchSoldTickets();
          await context.read<SokaService>().fetchEvents();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
          children: const [
            SizedBox(height: 32),
            _EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'You haven\'t bought any tickets yet',
              subtitle: 'Your purchased tickets will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.primary,
      onRefresh: () async {
        await context.read<SokaService>().fetchSoldTickets();
        await context.read<SokaService>().fetchEvents();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          final event = eventById[ticket.eventId];
          final title = event?.title ?? 'Event not available';
          final subtitle =
              '${ticket.ticketType} · ${_formatDateTime(ticket.purchaseDate)}';

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TicketDetailsScreen(ticket: ticket, event: event),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
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
          _EmptyState(icon: emptyIcon, title: emptyTitle, subtitle: subtitle),
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
        Icon(icon, size: 64, color: AppColors.cursorColor),
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
