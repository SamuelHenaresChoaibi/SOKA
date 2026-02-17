import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:provider/provider.dart';
import 'package:soka/config/payment_config.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:soka/utils/birth_date_input_formatter.dart';

enum PaymentMethod { paypal }

class TicketCheckoutScreen extends StatefulWidget {
  final Event event;

  const TicketCheckoutScreen({super.key, required this.event});

  @override
  State<TicketCheckoutScreen> createState() => _TicketCheckoutScreenState();
}

class _TicketCheckoutScreenState extends State<TicketCheckoutScreen> {
  Event? _event;
  Client? _client;
  PaypalCredentials? _paypalCredentials;
  String? _errorMessage;
  final List<_TicketHolderDraft> _holderDrafts = [];

  bool _isLoading = true;
  bool _isPaying = false;

  int _selectedTicketTypeIndex = 0;
  int _quantity = 1;
  int _alreadyPurchased = 0;
  PaymentMethod _paymentMethod = PaymentMethod.paypal;

  Event get event => _event ?? widget.event;

  @override
  void initState() {
    super.initState();
    _syncHolderDraftsWithQuantity();
    _load();
  }

  @override
  void dispose() {
    for (final draft in _holderDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final sokaService = context.read<SokaService>();
    final currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final refreshed = await sokaService.fetchEventById(widget.event.id);
      final client = currentUser == null
          ? null
          : await sokaService.fetchClientById(currentUser.uid);
      PaypalCredentials? paypalCredentials;
      try {
        paypalCredentials = await sokaService.resolvePaypalCredentials();
      } catch (_) {
        paypalCredentials = null;
      }

      if (!mounted) return;

      final loadedEvent = refreshed ?? widget.event;
      final defaultIndex = _firstAvailableTicketTypeIndex(
        loadedEvent.ticketTypes,
      );

      setState(() {
        _event = loadedEvent;
        _client = client;
        _paypalCredentials = paypalCredentials;
        _selectedTicketTypeIndex = defaultIndex;
      });

      if (currentUser != null) {
        final purchased = await sokaService.countUserTicketsForEvent(
          eventId: loadedEvent.id,
          userId: currentUser.uid,
          userName: client?.userName,
        );
        if (!mounted) return;
        setState(() => _alreadyPurchased = purchased);
      }

      _clampQuantity();
      _prefillFirstHolderFromClient();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not load event details. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _firstAvailableTicketTypeIndex(List<TicketType> types) {
    if (types.isEmpty) return 0;
    for (var i = 0; i < types.length; i++) {
      if (types[i].remaining > 0) return i;
    }
    return 0;
  }

  TicketType? get _selectedTicketType {
    if (event.ticketTypes.isEmpty) return null;
    final safeIndex = _selectedTicketTypeIndex.clamp(
      0,
      event.ticketTypes.length - 1,
    );
    return event.ticketTypes[safeIndex];
  }

  int get _maxByStock => _selectedTicketType?.remaining ?? 0;

  int get _maxByEventLimit {
    final limit = event.maxTicketsPerUser;
    if (limit <= 0) return _maxByStock;
    return math.max(0, limit - _alreadyPurchased);
  }

  int get _maxSelectable => math.min(_maxByStock, _maxByEventLimit);

  int get _unitPrice => _selectedTicketType?.price ?? 0;

  int get _totalPrice => _unitPrice * _quantity;

  bool get _canBuy =>
      !_isPaying &&
      FirebaseAuth.instance.currentUser != null &&
      _maxSelectable > 0 &&
      _quantity >= 1;

  Future<PaypalCredentials?> _ensurePaypalCredentials() async {
    final current = _paypalCredentials;
    if (current != null) {
      try {
        current.validate();
        return current;
      } catch (_) {
        // Continue with remote/cache resolution.
      }
    }

    final resolved = await context
        .read<SokaService>()
        .resolvePaypalCredentials();
    if (resolved == null) return null;
    if (mounted) {
      setState(() => _paypalCredentials = resolved);
    }
    return resolved;
  }

  void _syncHolderDraftsWithQuantity() {
    while (_holderDrafts.length > _quantity) {
      _holderDrafts.removeLast().dispose();
    }
    while (_holderDrafts.length < _quantity) {
      _holderDrafts.add(_TicketHolderDraft.empty());
    }
  }

  void _prefillFirstHolderFromClient() {
    final client = _client;
    if (client == null || _holderDrafts.isEmpty) return;

    final fullName = '${client.name.trim()} ${client.surname.trim()}';

    if (fullName.isNotEmpty) {
      final firstDraft = _holderDrafts.first;
      if (firstDraft.fullNameController.text.trim().isEmpty) {
        firstDraft.fullNameController.text = fullName;
      }
    }
  }

  void _setQuantity(int value) {
    final maxAllowed = math.max(1, _maxSelectable);
    final nextQuantity = value.clamp(1, maxAllowed).toInt();
    if (_quantity == nextQuantity) return;

    setState(() => _quantity = nextQuantity);
    _syncHolderDraftsWithQuantity();
    _prefillFirstHolderFromClient();
  }

  List<TicketHolder> _buildHolders() {
    return _holderDrafts
        .take(_quantity)
        .map((draft) => draft.toTicketHolder())
        .toList();
  }

  void _clampQuantity() {
    final maxAllowed = _maxSelectable;
    final nextQuantity = maxAllowed <= 0
        ? 1
        : _quantity.clamp(1, maxAllowed).toInt();

    if (_quantity != nextQuantity) {
      setState(() => _quantity = nextQuantity);
    }
    _syncHolderDraftsWithQuantity();
    _prefillFirstHolderFromClient();
  }

  Future<void> _onPay() async {
    if (!_canBuy) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final client = _client;
    final selectedTicketType = _selectedTicketType;
    _syncHolderDraftsWithQuantity();

    if (currentUser == null || selectedTicketType == null) {
      return;
    }

    final holderValidationError = _validateHolders();
    if (holderValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(holderValidationError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final holders = _buildHolders();
    final invalidHolderIndex = holders.indexWhere((holder) => !holder.isValid);
    if (holders.length != _quantity || invalidHolderIndex >= 0) {
      final message = invalidHolderIndex >= 0
          ? 'Fill in the owner\'s details correctly at the entrance. ${invalidHolderIndex + 1}.'
          : 'You must provide a holder for each ticket.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final needsPayment = _totalPrice > 0;
    PaypalCredentials? paypalCredentials;
    if (needsPayment) {
      if (_paymentMethod == PaymentMethod.paypal) {
        paypalCredentials = await _ensurePaypalCredentials();
      }
      if (_paymentMethod == PaymentMethod.paypal && paypalCredentials == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not load secure PayPal credentials.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isPaying = true);
    try {
      if (needsPayment) {
        final ok = _paymentMethod == PaymentMethod.paypal
            ? await _payWithPayPal(
                eventTitle: event.title,
                ticketType: selectedTicketType.type,
                quantity: _quantity,
                unitPrice: _unitPrice,
                credentials: paypalCredentials!,
              )
            : false;
        if (!ok) return;
      }

      final updatedEvent = await context.read<SokaService>().purchaseTickets(
        eventId: event.id,
        ticketType: selectedTicketType.type,
        quantity: _quantity,
        userId: currentUser.uid,
        userName: client?.userName,
        holders: holders,
      );

      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compra completada. ¡Tus entradas ya están en tu cuenta!',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      Navigator.pop(context, updatedEvent);
    } on TicketPurchaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete the purchase.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  String? _validateHolders() {
    if (_holderDrafts.length < _quantity) {
      return 'You must provide a holder for each ticket.';
    }

    for (var i = 0; i < _quantity; i++) {
      final draft = _holderDrafts[i];
      final entryLabel = 'ticket ${i + 1}';

      final fullName = draft.fullNameController.text.trim();
      if (fullName.isEmpty) {
        return 'Fill in the full name of the holder in ticket $entryLabel.';
      }

      final document = draft.dniController.text.trim();
      if (document.isEmpty) {
        return 'Fill in the document (DNI/NIE/Pasaporte) in ticket $entryLabel.';
      }

      if (!_isValidDocument(document)) {
        return 'Invalid document in ticket $entryLabel. Please use a valid DNI, NIE or passport.';
      }

      final countryCodeRaw = draft.countryCodeController.text.trim();
      final phoneRaw = draft.phoneController.text.trim();
      if (countryCodeRaw.isEmpty || phoneRaw.isEmpty) {
        return 'Complete the phone number in ticket $entryLabel.';
      }
      if (!_isValidCountryCode(countryCodeRaw)) {
        return 'Invalid country code in ticket $entryLabel. Example: +34.';
      }
      if (!_isValidInternationalPhone(countryCodeRaw, phoneRaw)) {
        return 'Invalid phone number in ticket $entryLabel. Use international format: +countryCode number.';
      }

      final birthDateRaw = draft.birthDateController.text.trim();
      if (birthDateRaw.isEmpty) {
        return 'Complete the birth date in ticket $entryLabel.';
      }

      final birthDate = _parseBirthDate(birthDateRaw);
      if (birthDate == null) {
        return 'Invalid birth date in ticket $entryLabel. Valid format: YYYY-MM-DD.';
      }

      if (birthDate.isAfter(DateTime.now())) {
        return 'The birth date cannot be in the future ($entryLabel).';
      }
    }

    return null;
  }

  DateTime? _parseBirthDate(String input) {
    final raw = input.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  bool _isValidDocument(String input) {
    final value = input.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    return _isValidDni(value) || _isValidNie(value) || _isValidPassport(value);
  }

  bool _isValidDni(String value) {
    final match = RegExp(r'^(\d{8})([A-Z])$').firstMatch(value);
    if (match == null) return false;

    const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
    final number = int.parse(match.group(1)!);
    final letter = match.group(2)!;
    return letters[number % 23] == letter;
  }

  bool _isValidNie(String value) {
    final match = RegExp(r'^([XYZ])(\d{7})([A-Z])$').firstMatch(value);
    if (match == null) return false;

    const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
    final prefix = match.group(1)!;
    final middle = match.group(2)!;
    final letter = match.group(3)!;

    final prefixNumber = switch (prefix) {
      'X' => '0',
      'Y' => '1',
      'Z' => '2',
      _ => '',
    };

    if (prefixNumber.isEmpty) return false;
    final number = int.parse('$prefixNumber$middle');
    return letters[number % 23] == letter;
  }

  bool _isValidPassport(String value) {
    return RegExp(r'^[A-Z0-9]{6,9}$').hasMatch(value);
  }

  bool _isValidCountryCode(String input) {
    final normalized = input.trim().replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^\+[1-9]\d{0,3}$').hasMatch(normalized);
  }

  bool _isValidInternationalPhone(String countryCode, String phoneNumber) {
    final normalizedCode = countryCode.trim().replaceAll(RegExp(r'\s+'), '');
    final normalizedPhone = phoneNumber
        .trim()
        .replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\d{6,14}$').hasMatch(normalizedPhone)) return false;
    final merged = '$normalizedCode$normalizedPhone';
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(merged);
  }

  Future<bool> _payWithPayPal({
    required String eventTitle,
    required String ticketType,
    required int quantity,
    required int unitPrice,
    required PaypalCredentials credentials,
  }) async {
    final sokaService = context.read<SokaService>();
    final company = await sokaService.fetchCompanyById(event.organizerId);

    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not retrieve organizer information.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final totalRaw = (unitPrice * quantity).toDouble();
    final total = double.parse(totalRaw.toStringAsFixed(2));

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaypalCheckoutView(
          sandboxMode: PaymentConfig.paypalSandboxMode,
          clientId: credentials.clientId,
          secretKey: credentials.secretKey,
          transactions: [
            {
              "amount": {
                "total": total.toStringAsFixed(2),
                "currency": "EUR",
                "details": {
                  "subtotal": total.toStringAsFixed(2),
                  "shipping": '0',
                  "shipping_discount": 0,
                },
              },
              "description":
                  "Entrada: $ticketType / \nEvento: ${event.title} / \nOrganizador: ${company.companyName} / \nPlataforma: SOKA",
              "item_list": {
                "items": [
                  {
                    "name": eventTitle,
                    "quantity": quantity,
                    "price": unitPrice.toStringAsFixed(2),
                    "currency": "EUR",
                  },
                ],
              },
            },
          ],
          note: "Pago de entradas SOKA",
          onSuccess: (Map params) async {
            print("Pago exitoso: $params");
            Navigator.pop(context, true);
          },
          onError: (error) {
            print("Error PayPal: $error");
            Navigator.pop(context, false);
          },
          onCancel: () {
            print('Pago cancelado');
            Navigator.pop(context, false);
          },
        ),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selectedTicketType;

    final limitLabel = event.maxTicketsPerUser <= 0
        ? 'Sin límite'
        : '${event.maxTicketsPerUser} máx.';

    final remainingByUser = event.maxTicketsPerUser <= 0
        ? null
        : math.max(0, event.maxTicketsPerUser - _alreadyPurchased);

    final payLabel = _totalPrice <= 0
        ? 'Confirmar'
        : _paymentMethod == PaymentMethod.paypal
        ? 'Pagar con PayPal'
        : 'Pagar con Redsys';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Buy tickets',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canBuy ? _onPay : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isPaying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      payLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Entrada',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (event.ticketTypes.isEmpty)
                          const Text(
                            'This event has no tickets available.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<int>(
                            initialValue: math.min(
                              _selectedTicketTypeIndex,
                              math.max(0, event.ticketTypes.length - 1),
                            ),
                            items: List.generate(event.ticketTypes.length, (
                              index,
                            ) {
                              final t = event.ticketTypes[index];
                              final label =
                                  '${t.type} • €${t.price} • ${t.remaining} available';
                              return DropdownMenuItem(
                                value: index,
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedTicketTypeIndex = value);
                              _clampQuantity();
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Available: ${selected?.remaining ?? 0}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'LLimit: $limitLabel',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (remainingByUser != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Remaining: $remainingByUser',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _QuantitySelector(
                          value: _quantity,
                          max: _maxSelectable,
                          onChanged: _setQuantity,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Holder per ticket',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Each ticket must have its own holder to validate access.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_quantity, (index) {
                          final draft = _holderDrafts[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _quantity - 1 ? 0 : 10,
                            ),
                            child: _TicketHolderFields(
                              index: index,
                              draft: draft,
                              enabled: !_isPaying,
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        const Text(
                          'Payment method',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<PaymentMethod>(
                          value: PaymentMethod.paypal,
                          groupValue: _paymentMethod,
                          onChanged: _isPaying
                              ? null
                              : (value) =>
                                    setState(() => _paymentMethod = value!),
                          title: const Text('PayPal'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _card(
                    child: Column(
                      children: [
                        _KeyValueRow(
                          label: 'Unit price',
                          value: _unitPrice <= 0 ? 'Free' : '€$_unitPrice',
                        ),
                        const SizedBox(height: 10),
                        _KeyValueRow(label: 'Quantity', value: '$_quantity'),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _KeyValueRow(
                          label: 'Total',
                          value: _totalPrice <= 0 ? 'Free' : '€$_totalPrice',
                          isEmphasis: true,
                        ),
                      ],
                    ),
                  ),
                  if (_client == null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'No tienes perfil de cliente. Puedes comprar igualmente, pero algunos datos no se autocompletarán.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _TicketHolderDraft {
  final TextEditingController fullNameController;
  final TextEditingController dniController;
  final TextEditingController countryCodeController;
  final TextEditingController phoneController;
  final TextEditingController birthDateController;

  _TicketHolderDraft({
    required this.fullNameController,
    required this.dniController,
    required this.countryCodeController,
    required this.phoneController,
    required this.birthDateController,
  });

  factory _TicketHolderDraft.empty() {
    return _TicketHolderDraft(
      fullNameController: TextEditingController(),
      dniController: TextEditingController(),
      countryCodeController: TextEditingController(text: '+34'),
      phoneController: TextEditingController(),
      birthDateController: TextEditingController(),
    );
  }

  TicketHolder toTicketHolder() {
    final birthDateInput = birthDateController.text.trim();
    final countryCode = countryCodeController.text.trim();
    final phone = phoneController.text.trim();
    return TicketHolder(
      fullName: fullNameController.text.trim(),
      dni: dniController.text.trim(),
      phoneNumber: '$countryCode$phone',
      birthDate: DateTime.tryParse(birthDateInput) ?? DateTime(1900, 1, 1),
    );
  }

  void dispose() {
    fullNameController.dispose();
    dniController.dispose();
    countryCodeController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
  }
}

class _TicketHolderFields extends StatelessWidget {
  final int index;
  final _TicketHolderDraft draft;
  final bool enabled;

  const _TicketHolderFields({
    required this.index,
    required this.draft,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket ${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: draft.fullNameController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.dniController,
            enabled: enabled,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Document (DNI / NIE / Passport)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8), 
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: draft.countryCodeController,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Country code',
                    hintText: '+34',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: draft.phoneController,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '600111222',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), 
          TextField( 
            controller: draft.birthDateController, 
            enabled: enabled, 
            keyboardType: TextInputType.number,
            inputFormatters: [BirthDateInputFormatter()],
            decoration: const InputDecoration( 
              labelText: 'Birth date (YYYY-MM-DD)', 
              border: OutlineInputBorder(), 
              isDense: true, ), ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > 1;
    final canIncrease = value < math.max(1, max);

    return Row(
      children: [
        IconButton(
          onPressed: canDecrease ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Expanded(
          child: Center(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: (max <= 0 || !canIncrease)
              ? null
              : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const _KeyValueRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isEmphasis ? 16 : 13,
      fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w700,
      color: AppColors.textPrimary,
    );

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
        Text(value, style: style),
      ],
    );
  }
}
