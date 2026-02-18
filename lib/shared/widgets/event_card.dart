import 'package:flutter/material.dart';
import 'package:soka/models/models.dart';
import 'package:soka/theme/app_colors.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const EventCard({
    super.key,
    required this.event,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _opacityAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final minPrice = event.minTicketPrice;
    final maxPrice = event.maxTicketPrice;

    final priceLabel = !event.hasTicketTypes
        ? 'No tickets'
        : minPrice <= 0
        ? 'Free'
        : minPrice == maxPrice
        ? '$minPrice€'
        : 'From $minPrice€';

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, 'details', arguments: widget.event);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.9),
                ),
              ),
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _EventImage(imageUrl: widget.event.imageUrl, height: 210),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withValues(alpha: 0.72),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.94,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.32,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.event.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (widget.showFavoriteButton) ...[
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: Material(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.94,
                                  ),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    onPressed: widget.onToggleFavorite,
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    tooltip: widget.isFavorite
                                        ? 'Remove from favorites'
                                        : 'Add to favorites',
                                    icon: Icon(
                                      widget.isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: widget.isFavorite
                                          ? Colors.redAccent
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.38),
                            ),
                          ),
                          child: Text(
                            priceLabel,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (widget.event.validated)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatDate(widget.event.date)}  ${_formatTime(widget.event.date)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[date.month - 1];
    return '${date.day} $month';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _EventImage extends StatelessWidget {
  final String imageUrl;
  final double height;

  const _EventImage({required this.imageUrl, required this.height});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Image.asset(
        'lib/assets/SOKA.png',
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return FadeInImage(
      placeholder: const AssetImage('lib/assets/SOKA.png'),
      image: NetworkImage(url),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
