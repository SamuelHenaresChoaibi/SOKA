import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/widgets/bottom_cta.dart';
import 'package:soka/widgets/category_chip.dart';
import 'package:soka/widgets/icon_circle.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final price = event.ticketTypes.price;
    final priceLabel = price <= 0 ? 'Gratis' : '€$price';
    final ticketSubtitle =
        '${event.ticketTypes.type} • ${event.ticketTypes.remaining} disponibles';
    Future<Company?> company = Provider.of<SokaService>(context, listen: false)
        .fetchCompanyById(event.organizerId);
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomCTA(
        title: 'Comprar entrada',
        subtitle: ticketSubtitle,
        priceLabel: priceLabel,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Pronto podrás comprar entradas!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconCircle(
                  icon: Icons.ios_share_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compartir (próximamente)'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
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
                        label: 'Fecha',
                        value: _formatDate(event.date),
                      ),
                      _InfoTile(
                        icon: Icons.schedule_outlined,
                        label: 'Hora',
                        value: _formatTime(event.date),
                      ),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Lugar',
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
                          label: 'Ciudad',
                          value: event.locationCity?.trim() ?? '-',
                        ),
                        _InfoTile(
                          icon: Icons.public_outlined,
                          label: 'País',
                          value: event.locationCountry?.trim() ?? '-',
                        ),
                        if ((event.locationState ?? '').trim().isNotEmpty)
                          _InfoTile(
                            icon: Icons.map_outlined,
                            label: 'Provincia',
                            value: event.locationState!.trim(),
                          ),
                        if ((event.locationPostcode ?? '').trim().isNotEmpty)
                          _InfoTile(
                            icon: Icons.markunread_mailbox_outlined,
                            label: 'CP',
                            value: event.locationPostcode!.trim(),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle('Acerca del evento'),
                  const SizedBox(height: 12),
                  _Card(
                    child: Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textPrimary.withOpacity(0.86),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle('Entrada'),
                  const SizedBox(height: 12),
                  _TicketCard(
                    type: event.ticketTypes.type,
                    description: event.ticketTypes.description,
                    remaining: event.ticketTypes.remaining,
                    capacity: event.ticketTypes.capacity,
                    priceLabel: priceLabel,
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle('Detalles'),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      children: [
                        _KeyValueRow(
                          label: 'Creado',
                          value: _formatDate(event.createdAt),
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        FutureBuilder<Company?>(
                          future: company,
                          builder: (context, companySnapshot) {
                            final companyName = companySnapshot.data?.companyName ?? 'Desconocido';
                            return _KeyValueRow(
                              label: 'Organizador',
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
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La ubicacion esta vacia.')),
      );
      return;
    }

    final uri = hasCoords
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$query',
          );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
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
        Positioned(
          left: 20,
          bottom: 22,
          child: _PricePill(text: priceLabel),
        ),
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
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.08),
        ),
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
      color: isInteractive ? AppColors.primary : AppColors.textPrimary,
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
            'Validado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.surface,
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
        ? '$remaining disponibles'
        : '$remaining/$capacity disponibles';

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
