import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:soka/models/models.dart';
import 'package:soka/theme/app_colors.dart';

class TicketDetailsScreen extends StatelessWidget {
  final SoldTicket ticket;
  final Event? event;

  const TicketDetailsScreen({super.key, required this.ticket, this.event});

  @override
  Widget build(BuildContext context) {
    final holderName = ticket.holder.fullName.trim().isEmpty
        ? 'No holder'
        : ticket.holder.fullName.trim();
    final statusText = ticket.isCheckedIn ? 'Scanned' : 'Pending';
    final statusColor = ticket.isCheckedIn ? Colors.green : AppColors.textMuted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Ticket details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(
                      data: ticket.idTicket.toString(),
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'QR ticket #${ticket.idTicket}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Show this QR at the event entrance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Event',
                    value: event?.title.trim().isNotEmpty == true
                        ? event!.title
                        : ticket.eventId,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Type', value: ticket.ticketType),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Ticket ID', value: '${ticket.idTicket}'),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'QR Code',
                    value: ticket.idTicket.toString(),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Purchased on',
                    value: _formatDateTime(ticket.purchaseDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              child: Column(
                children: [
                  _DetailRow(label: 'Holder', value: holderName),
                  if (ticket.holder.dni.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(label: 'Document', value: ticket.holder.dni),
                  ],
                  if (ticket.holder.phoneNumber.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Phone number',
                      value: ticket.holder.phoneNumber,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Birth date',
                    value: _formatDate(ticket.holder.birthDate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }

  static String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${_formatDate(local)} $h:$m';
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value.trim(),
            textAlign: TextAlign.right,
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
