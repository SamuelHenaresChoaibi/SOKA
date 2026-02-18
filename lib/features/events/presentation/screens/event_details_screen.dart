import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/features/tickets/presentation/screens/ticket_checkout_screen.dart';
import 'package:soka/features/tickets/presentation/screens/ticket_details_screen.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/shared/widgets/bottom_cta.dart';
import 'package:soka/shared/widgets/category_chip.dart';
import 'package:soka/shared/widgets/icon_circle.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Event _event;
  Client? _client;
  List<SoldTicket> _userTickets = const [];
  int _alreadyPurchased = 0;
  bool _isLoadingUserTickets = true;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    Future.microtask(_refreshEventAndUserTickets);
  }

  Future<void> _refreshEventAndUserTickets() async {
    final sokaService = context.read<SokaService>();
    final currentUser = FirebaseAuth.instance.currentUser;
    var eventToUse = _event;
    Client? client;
    List<SoldTicket> userTickets = const [];

    if (mounted) {
      setState(() => _isLoadingUserTickets = true);
    }

    try {
      final refreshed = await sokaService.fetchEventById(_event.id);
      if (refreshed != null) {
        eventToUse = refreshed;
      }
    } catch (_) {
      // no-op
    }

    if (currentUser != null) {
      try {
        client = await sokaService.fetchClientById(currentUser.uid);
        userTickets = await sokaService.fetchUserTicketsForEvent(
          eventId: eventToUse.id,
          userId: currentUser.uid,
          userName: client?.userName,
        );
      } catch (_) {
        // no-op
      }
    }

    if (!mounted) return;
    setState(() {
      _event = eventToUse;
      _client = client;
      _userTickets = userTickets;
      _alreadyPurchased = userTickets.length;
      _isLoadingUserTickets = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasAuthenticatedSession = currentUser != null;

    final minPrice = event.minTicketPrice;
    final maxPrice = event.maxTicketPrice;
    final totalRemaining = event.totalRemaining;

    final priceLabel = !event.hasTicketTypes
        ? 'No tickets'
        : minPrice <= 0
        ? 'Free'
        : minPrice == maxPrice
        ? '€$minPrice'
        : 'From €$minPrice';

    final ticketSubtitle = !event.hasTicketTypes
        ? 'No ticket types configured'
        : event.ticketTypes.length == 1
        ? '${event.ticketTypes.first.type} • ${event.ticketTypes.first.remaining} disponibles'
        : '${event.ticketTypes.length} tipos • $totalRemaining disponibles';
    Future<Company?> company = Provider.of<SokaService>(
      context,
      listen: false,
    ).fetchCompanyById(event.organizerId);

    final remainingByUser = event.maxTicketsPerUser <= 0
        ? null
        : math.max(0, event.maxTicketsPerUser - _alreadyPurchased);
    final availableToBuyNow = remainingByUser == null
        ? totalRemaining
        : math.min(totalRemaining, remainingByUser);

    final isSoldOut = !event.hasTicketTypes || totalRemaining <= 0;
    final isUserContextLoading = currentUser != null && _isLoadingUserTickets;
    final isLimitReachedForUser =
        hasAuthenticatedSession &&
        remainingByUser != null &&
        remainingByUser <= 0;
    final canOpenCheckout =
        !isSoldOut && !isLimitReachedForUser && !isUserContextLoading;

    final ctaTitle = isSoldOut
        ? 'Agotado'
        : isUserContextLoading
        ? 'Cargando...'
        : isLimitReachedForUser
        ? 'Límite alcanzado'
        : _alreadyPurchased > 0
        ? 'Comprar entradas restantes'
        : 'Comprar entrada';

    final ctaSubtitle = isSoldOut
        ? 'No quedan más entradas'
        : isUserContextLoading
        ? 'Estamos comprobando tus entradas compradas.'
        : isLimitReachedForUser
        ? 'Ya compraste $_alreadyPurchased de ${event.maxTicketsPerUser}.'
        : remainingByUser != null && _alreadyPurchased > 0
        ? 'Puedes comprar $availableToBuyNow más ahora.'
        : ticketSubtitle;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomCTA(
        title: ctaTitle,
        subtitle: ctaSubtitle,
        priceLabel: priceLabel,
        onPressed: canOpenCheckout
            ? () async {
                final updated = await Navigator.push<Event?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketCheckoutScreen(event: event),
                  ),
                );
                if (!context.mounted) return;
                await _refreshEventAndUserTickets();
                if (!context.mounted) return;
                if (updated != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compra completada.'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            : null,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconCircle(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _Hero(
                priceLabel: priceLabel,
                imageUrl: event.imageUrl,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      CategoryChip(text: event.category),
                      if (event.validated) const _ValidatedChip(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    event.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: _formatDate(event.date),
                      ),
                      _InfoTile(
                        icon: Icons.schedule_outlined,
                        label: 'Time',
                        value: _formatTime(event.date),
                      ),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: event.locationLabel,
                        onTap: () => _openMaps(
                          context,
                          event.locationLabel,
                          event.locationLat,
                          event.locationLng,
                        ),
                      ),
                      if (_hasExtraLocation(event)) ...[
                        _InfoTile(
                          icon: Icons.location_city_outlined,
                          label: 'City',
                          value: event.locationCity?.trim() ?? '-',
                        ),
                        _InfoTile(
                          icon: Icons.public_outlined,
                          label: 'Country',
                          value: event.locationCountry?.trim() ?? '-',
                        ),
                        if ((event.locationState ?? '').trim().isNotEmpty)
                          _InfoTile(
                            icon: Icons.map_outlined,
                            label: 'State',
                            value: event.locationState!.trim(),
                          ),
                        if ((event.locationPostcode ?? '').trim().isNotEmpty)
                          _InfoTile(
                            icon: Icons.markunread_mailbox_outlined,
                            label: 'Postal Code',
                            value: event.locationPostcode!.trim(),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle('About the event'),
                  const SizedBox(height: 12),
                  _Card(
                    child: Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textPrimary.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle('Tickets'),
                  const SizedBox(height: 12),
                  if (!event.hasTicketTypes)
                    const _Card(
                      child: Text(
                        'No ticket types configured.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(event.ticketTypes.length, (
                        index,
                      ) {
                        final ticketType = event.ticketTypes[index];
                        final typePriceLabel = ticketType.price <= 0
                            ? 'Free'
                            : '€${ticketType.price}';

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == event.ticketTypes.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _TicketCard(
                            type: ticketType.type,
                            description: ticketType.description,
                            remaining: ticketType.remaining,
                            capacity: ticketType.capacity,
                            priceLabel: typePriceLabel,
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 26),
                  const _SectionTitle('Tus entradas'),
                  const SizedBox(height: 12),
                  ..._buildUserTicketSection(
                    event: event,
                    currentUser: currentUser,
                    remainingByUser: remainingByUser,
                    availableToBuyNow: availableToBuyNow,
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle('Detalles'),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      children: [
                        _KeyValueRow(
                          label: 'Created',
                          value: _formatDate(event.createdAt),
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        FutureBuilder<Company?>(
                          future: company,
                          builder: (context, companySnapshot) {
                            final companyName =
                                companySnapshot.data?.companyName ??
                                'Desconocido';
                            return _KeyValueRow(
                              label: 'Organizer',
                              value: _shortId(companyName),
                            );
                          },
                        ),
                      ],
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

  List<Widget> _buildUserTicketSection({
    required Event event,
    required User? currentUser,
    required int? remainingByUser,
    required int availableToBuyNow,
  }) {
    if (currentUser == null) {
      return const [
        _Card(
          child: Text(
            'Inicia sesión para ver tus entradas compradas en este evento.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ];
    }

    if (_isLoadingUserTickets) {
      return const [
        _Card(
          child: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cargando tus entradas...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (_client == null) {
      return const [
        _Card(
          child: Text(
            'Esta cuenta no tiene perfil de cliente, por eso no hay entradas asociadas.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ];
    }

    final summaryLabel = event.maxTicketsPerUser <= 0
        ? 'Compradas: $_alreadyPurchased (sin límite por usuario) • Disponibles ahora: $availableToBuyNow'
        : 'Compradas: $_alreadyPurchased/${event.maxTicketsPerUser} • Te quedan ${remainingByUser ?? 0} • Disponibles ahora: $availableToBuyNow';

    if (_userTickets.isEmpty) {
      return [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aún no has comprado entradas para este evento.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summaryLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summaryLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ];

    for (var i = 0; i < _userTickets.length; i++) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i == _userTickets.length - 1 ? 0 : 10,
          ),
          child: _UserTicketCard(ticket: _userTickets[i], event: event),
        ),
      );
    }
    return widgets;
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}…';
  }

  static String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static bool _hasExtraLocation(Event event) {
    return (event.locationCity ?? '').trim().isNotEmpty ||
        (event.locationCountry ?? '').trim().isNotEmpty ||
        (event.locationState ?? '').trim().isNotEmpty ||
        (event.locationPostcode ?? '').trim().isNotEmpty;
  }

  static Future<void> _openMaps(
    BuildContext context,
    String location,
    double? lat,
    double? lng,
  ) async {
    final hasCoords = lat != null && lng != null;
    final query = Uri.encodeComponent(location.trim());
    if (!hasCoords && query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location is empty.')));
      return;
    }

    final uri = hasCoords
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }
}

class _Hero extends StatelessWidget {
  final String priceLabel;
  final String imageUrl;

  const _Hero({required this.priceLabel, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        SizedBox.expand(
          child: url.isEmpty
              ? Image.asset('lib/assets/SOKA.png', fit: BoxFit.cover)
              : FadeInImage(
                  placeholder: const AssetImage('lib/assets/SOKA.png'),
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.65),
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Positioned(left: 20, bottom: 22, child: _PricePill(text: priceLabel)),
      ],
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text;

  const _PricePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null;
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isInteractive ? AppColors.accent : AppColors.textPrimary,
      height: 1.2,
      decoration: isInteractive ? TextDecoration.underline : null,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      child: GestureDetector(
        onTap: onTap,
        child: _Card(
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidatedChip extends StatelessWidget {
  const _ValidatedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified, size: 16, color: AppColors.accent),
          SizedBox(width: 6),
          Text(
            'Validated',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String type;
  final String description;
  final int remaining;
  final int capacity;
  final String priceLabel;

  const _TicketCard({
    required this.type,
    required this.description,
    required this.remaining,
    required this.capacity,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final availability = capacity <= 0
        ? '$remaining available'
        : '$remaining/$capacity available';

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  availability,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            priceLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTicketCard extends StatelessWidget {
  final SoldTicket ticket;
  final Event event;

  const _UserTicketCard({required this.ticket, required this.event});

  @override
  Widget build(BuildContext context) {
    final scannedLabel = ticket.isCheckedIn ? 'Escaneada' : 'Pendiente';
    final holderName = ticket.holder.fullName.isEmpty
        ? 'Sin titular'
        : ticket.holder.fullName;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailsScreen(ticket: ticket, event: event),
          ),
        );
      },
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ticket.ticketType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  scannedLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ticket.isCheckedIn
                        ? Colors.green
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _KeyValueRow(label: 'Titular', value: holderName),
            if (ticket.holder.dni.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _KeyValueRow(label: 'Documento', value: ticket.holder.dni),
            ],
            const SizedBox(height: 8),
            _KeyValueRow(label: 'ID ticket', value: ticket.idTicket.toString()),
            const SizedBox(height: 8),
            _KeyValueRow(
              label: 'Compra',
              value: _EventDetailsScreenState._formatDateTime(
                ticket.purchaseDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
