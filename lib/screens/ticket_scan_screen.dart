import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';

enum TicketScannerMode { company, client }

class TicketScanScreen extends StatefulWidget {
  final TicketScannerMode mode;

  const TicketScanScreen({super.key, required this.mode});

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;

  bool get _canValidateAccess => widget.mode == TicketScannerMode.company;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final scanValue = capture.barcodes
        .map((code) => code.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (scanValue.isEmpty) return;
    final sokaService = context.read<SokaService>();

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    await _scannerController.stop();

    MapEntry<String, SoldTicket>? ticketEntry;
    Event? event;

    try {
      ticketEntry = await sokaService.fetchSoldTicketEntryByScanValue(
        scanValue,
      );
      if (ticketEntry != null) {
        event = await sokaService.fetchEventById(ticketEntry.value.eventId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'No se pudo validar el código. Inténtalo de nuevo.';
      });
      await _scannerController.start();
      return;
    }

    if (!mounted) return;

    if (ticketEntry == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'No existe ningún ticket para ese QR.';
      });
      await _scannerController.start();
      return;
    }

    if (_canValidateAccess && ticketEntry.value.isCheckedIn) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Este ticket ya fue validado y no puede volver a pasar.';
      });
      await _scannerController.start();
      return;
    }

    final allowAccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannedTicketValidationScreen(
          ticketKey: ticketEntry!.key,
          ticket: ticketEntry.value,
          event: event,
          scannedValue: scanValue,
          allowValidation: _canValidateAccess,
        ),
      ),
    );

    if (!mounted) return;

    if (_canValidateAccess && allowAccess == true) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isProcessing = false);
    await _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.surface,
        title: Text(
          _canValidateAccess ? 'Escanear ticket' : 'Escanear QR de ticket',
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apunta al QR de la entrada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _canValidateAccess
                        ? 'Modo empresa: puedes validar una sola vez cada ticket.'
                        : 'Modo cliente: solo puedes consultar los detalles del ticket.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isProcessing)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannedTicketValidationScreen extends StatefulWidget {
  final String ticketKey;
  final SoldTicket ticket;
  final Event? event;
  final String scannedValue;
  final bool allowValidation;

  const ScannedTicketValidationScreen({
    super.key,
    required this.ticketKey,
    required this.ticket,
    required this.event,
    required this.scannedValue,
    required this.allowValidation,
  });

  @override
  State<ScannedTicketValidationScreen> createState() =>
      _ScannedTicketValidationScreenState();
}

class _ScannedTicketValidationScreenState
    extends State<ScannedTicketValidationScreen> {
  bool _isSubmitting = false;

  Future<void> _allowAccess() async {
    if (_isSubmitting || !widget.allowValidation) return;

    setState(() => _isSubmitting = true);

    try {
      final sokaService = context.read<SokaService>();
      final latestTicket = await sokaService.fetchSoldTicketById(
        widget.ticketKey,
      );
      final alreadyCheckedIn =
          latestTicket?.isCheckedIn ?? widget.ticket.isCheckedIn;

      if (alreadyCheckedIn) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este ticket ya fue validado anteriormente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await sokaService.updateSoldTicket(widget.ticketKey, {
        'isCheckedIn': true,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el ticket.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final holderName = ticket.holder.fullName.trim().isEmpty
        ? 'Sin titular'
        : ticket.holder.fullName.trim();
    final title = widget.event?.title.trim().isNotEmpty == true
        ? widget.event!.title
        : ticket.eventId;
    final alreadyCheckedIn = ticket.isCheckedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: Text(
          widget.allowValidation ? 'Validar ticket' : 'Detalle del ticket',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alreadyCheckedIn
                        ? 'Este ticket ya fue escaneado anteriormente y validado para pasar.'
                        : widget.allowValidation
                        ? 'Ticket pendiente de validación.'
                        : 'Ticket pendiente. Solo vista de consulta para cliente.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: alreadyCheckedIn
                          ? Colors.orange
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              child: Column(
                children: [
                  _InfoRow(label: 'Titular', value: holderName),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Tipo', value: ticket.ticketType),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'ID ticket', value: '${ticket.idTicket}'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'QR escaneado', value: widget.scannedValue),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Compra',
                    value: _formatDateTime(ticket.purchaseDate),
                  ),
                  if (ticket.holder.dni.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Documento', value: ticket.holder.dni),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    !widget.allowValidation || _isSubmitting || alreadyCheckedIn
                    ? null
                    : _allowAccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.allowValidation
                      ? Colors.green
                      : AppColors.textMuted,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.allowValidation
                            ? (alreadyCheckedIn
                                  ? 'Ya utilizado'
                                  : 'Dejar pasar')
                            : 'Solo lectura',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.allowValidation ? 'No dejar pasar' : 'Cerrar',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
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
