import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/shared/widgets/widgets.dart';
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
  String? _clientUserName;
  bool _clientIdentityLoaded = false;

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
        _errorMessage = 'Could not fetch ticket information.';
      });
      await _scannerController.start();
      return;
    }

    if (!mounted) return;

    if (ticketEntry == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'No ticket exists for that QR.';
      });
      await _scannerController.start();
      return;
    }

    if (_canValidateAccess && ticketEntry.value.isCheckedIn) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'This ticket has already been validated and cannot be scanned again.';
      });
      await _scannerController.start();
      return;
    }

    if (!_canValidateAccess) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Debes iniciar sesión para escanear tus entradas.';
        });
        await _scannerController.start();
        return;
      }

      final clientUserName = await _resolveClientUserName();
      final belongsToClient = _isTicketOwnedByClient(
        ticketEntry.value,
        userId: currentUser.uid,
        userName: clientUserName,
      );
      if (!belongsToClient) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Este ticket no es suyo. Vuelva a intentarlo con un ticket que haya comprado.';
        });
        await _scannerController.start();
        return;
      }
    }

    if (!mounted) return;
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

  Future<String?> _resolveClientUserName() async {
    if (_clientIdentityLoaded) {
      final normalized = _clientUserName?.trim();
      return (normalized == null || normalized.isEmpty) ? null : normalized;
    }

    _clientIdentityLoaded = true;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final client = await context.read<SokaService>().fetchClientById(
        currentUser.uid,
      );
      final normalized = client?.userName.trim();
      _clientUserName = (normalized == null || normalized.isEmpty)
          ? null
          : normalized;
    } catch (_) {
      _clientUserName = null;
    }

    return _clientUserName;
  }

  bool _isTicketOwnedByClient(
    SoldTicket ticket, {
    required String userId,
    String? userName,
  }) {
    final normalizedUserId = userId.trim();
    final normalizedUserName = userName?.trim();
    final owner = ticket.buyerUserId.trim();

    if (normalizedUserId.isNotEmpty && owner == normalizedUserId) {
      return true;
    }
    if (normalizedUserName != null &&
        normalizedUserName.isNotEmpty &&
        owner == normalizedUserName) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textPrimary,
        title: Text(_canValidateAccess ? 'Scan ticket' : 'Scan ticket QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Center(
            child: IgnorePointer(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.82),
                          width: 2,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.15, end: 0.85),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return Positioned(
                          top: 240 * value,
                          left: 18,
                          right: 18,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.55,
                                  ),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Point the camera at the ticket QR.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _canValidateAccess
                        ? 'Companies: validate the ticket and allow access to the event.'
                        : 'Client mode: you can only view ticket details.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
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
            content: Text(
              'This ticket has already been validated and cannot be scanned again.',
            ),
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
          content: Text('Could not update ticket.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final holderName = ticket.holder.fullName.trim().isEmpty
        ? 'No holder'
        : ticket.holder.fullName.trim();
    final title = widget.event?.title.trim().isNotEmpty == true
        ? widget.event!.title
        : ticket.eventId;
    final alreadyCheckedIn = ticket.isCheckedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.allowValidation ? 'Validate ticket' : 'Ticket details',
        ),
      ),
      body: SokaLuxuryBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: SokaEntrance(
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
                            ? 'This ticket has already been scanned and validated.'
                            : widget.allowValidation
                            ? 'Ticket pending validation.'
                            : 'Ticket pending. Only viewable for client.',
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
                      _InfoRow(label: 'Holder', value: holderName),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Type', value: ticket.ticketType),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Ticket ID', value: '${ticket.idTicket}'),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Scanned QR', value: widget.scannedValue),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Purchased on',
                        value: _formatDateTime(ticket.purchaseDate),
                      ),
                      if (ticket.holder.dni.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Document', value: ticket.holder.dni),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        !widget.allowValidation ||
                            _isSubmitting ||
                            alreadyCheckedIn
                        ? null
                        : _allowAccess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.allowValidation
                          ? AppColors.accent
                          : AppColors.textMuted,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Text(
                            widget.allowValidation
                                ? (alreadyCheckedIn
                                      ? 'Already used'
                                      : 'Allow entry')
                                : 'Read-only',
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
                      widget.allowValidation ? 'Do not allow entry' : 'Close',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
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
