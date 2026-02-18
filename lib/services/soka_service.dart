import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';
import '../models/models.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';
import 'paypal_credentials_cache_service.dart';

class SokaService extends ChangeNotifier {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final String _baseUrl =
      "soka-1a9f3-default-rtdb.europe-west1.firebasedatabase.app";
  final NotificationService _notificationService = NotificationService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final PaypalCredentialsCacheService _paypalCredentialsCacheService =
      PaypalCredentialsCacheService();
  List<Company> companies = [];
  List<Event> events = [];
  List<Client> clients = [];
  List<SoldTicket> soldTickets = [];

  static const int _purchaseMaxRetries = 3;

  SokaService() {
    init();
  }

  Future<void> init() async {
    await _notificationService.initialize();
    await fetchClients();
    await fetchCompanies();
    await fetchEvents();
    await fetchSoldTickets();
  }

  //-----------------------------------------
  //-----------------------------------------
  //CLIENTS
  Future<int> createClientWithId(String clientId, Client newClient) async {
    final url = Uri.https(_baseUrl, '/users/clients/$clientId.json');

    final response = await http.put(url, body: json.encode(newClient.toJson()));

    if (response.statusCode == 200) {
      await fetchClients();
    }

    return response.statusCode;
  }

  Future<void> deleteClient(String clientId) async {
    try {
      final url = Uri.https(_baseUrl, '/users/clients/$clientId.json');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        print('Client deleted successfully');
        await fetchClients();
      } else {
        throw Exception('Failed to delete client');
      }
    } catch (e) {
      print('ERROR deleteClient: $e');
      rethrow;
    }
  }

  Future<void> updateClient(
    String clientId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final url = Uri.https(_baseUrl, '/users/clients/$clientId.json');
      final response = await http.patch(url, body: json.encode(updatedData));
      if (response.statusCode == 200) {
        print('Client updated successfully');
        await fetchClients();
      } else {
        throw Exception('Failed to update client');
      }
    } catch (e) {
      print('ERROR updateClient: $e');
      rethrow;
    }
  }

  Future<void> updateCompany(
    String companyId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final url = Uri.https(_baseUrl, '/users/companies/$companyId.json');
      final response = await http.patch(url, body: json.encode(updatedData));
      if (response.statusCode == 200) {
        print('Company updated successfully');
        await fetchCompanies();
      } else {
        throw Exception('Failed to update company');
      }
    } catch (e) {
      print('ERROR updateCompany: $e');
      rethrow;
    }
  }

  //-----------------------------------------
  //-----------------------------------------
  //USER SETTINGS
  Future<Map<String, dynamic>?> fetchUserSettings(String userId) async {
    try {
      final url = Uri.https(_baseUrl, '/users/settings/$userId.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      }
      return null;
    } catch (e) {
      print('ERROR fetchUserSettings: $e');
      rethrow;
    }
  }

  Future<void> updateUserSettings(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final url = Uri.https(_baseUrl, '/users/settings/$userId.json');
      final response = await http.patch(url, body: json.encode(updatedData));
      if (response.statusCode == 200) {
        print('Settings updated successfully');
      } else {
        throw Exception('Failed to update settings');
      }
    } catch (e) {
      print('ERROR updateUserSettings: $e');
      rethrow;
    }
  }

  Future<Client?> fetchClientById(String clientId) async {
    try {
      final url = Uri.https(_baseUrl, '/users/clients/$clientId.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> clientMap = json.decode(response.body);
        return Client.fromJson(clientMap);
      }
      return null;
    } catch (e) {
      print('ERROR fetchClientById: $e');
      rethrow;
    }
  }

  Future<List<Client>> fetchClients() async {
    try {
      clients.clear();
      final url = Uri.https(_baseUrl, '/users/clients.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value == null) return;
            clients.add(Client.fromJson(value));
          });
        } else if (decoded is List) {
          for (final value in decoded) {
            if (value == null) continue;
            if (value is Map<String, dynamic>) {
              clients.add(Client.fromJson(value));
            }
          }
        }
      }

      notifyListeners();
      return clients;
    } catch (e) {
      print('ERROR fetchClients: $e');
      rethrow;
    }
  }

  //-----------------------------------------
  //-----------------------------------------

  //-----------------------------------------
  //-----------------------------------------
  //COMPANIES
  Future<int> createCompany(String companyId, Company newCompany) async {
    try {
      for (var company in companies) {
        if (company.companyName == newCompany.companyName) {
          throw Exception(
            'Company with name "${newCompany.companyName}" already exists',
          );
        } else if (company.contactInfo.email == newCompany.contactInfo.email) {
          throw Exception(
            'Company with email "${newCompany.contactInfo.email}" already exists',
          );
        } else if (company.contactInfo.phoneNumber ==
            newCompany.contactInfo.phoneNumber) {
          throw Exception(
            'Company with phone number "${newCompany.contactInfo.phoneNumber}" already exists',
          );
        }
      }
      companies.clear();
      final url = Uri.https(_baseUrl, '/users/companies/$companyId.json');
      final response = await http.put(
        url,
        body: json.encode({
          'companyName': newCompany.companyName,
          'contactInfo': newCompany.contactInfo.toJson(),
          'createdAt': newCompany.createdAt.toIso8601String(),
          'createdEventIds': newCompany.createdEventIds,
          'description': newCompany.description,
          'profileImageOffsetX': newCompany.profileImageOffsetX,
          'profileImageOffsetY': newCompany.profileImageOffsetY,
          'profileImageUrl': newCompany.profileImageUrl,
          'verified': newCompany.verified,
        }),
      );
      if (response.statusCode == 200) {
        print('Company created successfully: ${response.body}');
        await fetchCompanies();
      } else {
        print(
          'Failed to create company. Status code: ${response.statusCode}, Response body: ${response.body}',
        );
        throw Exception('Failed to create company');
      }
      return response.statusCode;
    } catch (e) {
      print('ERROR createCompany: $e');
      rethrow;
    }
  }

  Future<void> deleteCompany(String companyId) async {
    try {
      final url = Uri.https(_baseUrl, '/users/companies/$companyId.json');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        print('Company deleted successfully');
        await fetchCompanies();
      } else {
        throw Exception('Failed to delete company');
      }
    } catch (e) {
      print('ERROR deleteCompany: $e');
      rethrow;
    }
  }

  Future<Company?> fetchCompanyById(String companyId) async {
    try {
      final url = Uri.https(_baseUrl, '/users/companies/$companyId.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> companyMap = json.decode(response.body);
        return Company.fromJson(companyMap, id: companyId);
      }
      return null;
    } catch (e) {
      print('ERROR fetchCompanyById: $e');
      rethrow;
    }
  }

  Future<List<Company>> fetchCompanies() async {
    try {
      companies.clear();
      final url = Uri.https(_baseUrl, '/users/companies.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value == null) return;
            companies.add(Company.fromJson(value, id: key));
          });
        } else if (decoded is List) {
          for (var i = 0; i < decoded.length; i++) {
            final value = decoded[i];
            if (value == null) continue;
            if (value is Map<String, dynamic>) {
              companies.add(Company.fromJson(value, id: i.toString()));
            }
          }
        }
      }

      notifyListeners();
      return companies;
    } catch (e) {
      print('ERROR fetchCompanies: $e');
      rethrow;
    }
  }
  //-----------------------------------------
  //-----------------------------------------

  //-----------------------------------------
  //-----------------------------------------
  //EVENTS
  Future<List<String>> fetchEventCategories() async {
    try {
      final url = Uri.https(_baseUrl, '/categories.json');
      final response = await http.get(url);

      if (response.statusCode != 200 || response.body == 'null') {
        return const [];
      }

      final decoded = json.decode(response.body);
      final categories = <String>[];
      final seen = <String>{};

      void addCategory(dynamic raw) {
        if (raw == null) return;
        final value = raw.toString().trim();
        if (value.isEmpty) return;
        final key = value.toLowerCase();
        if (!seen.add(key)) return;
        categories.add(value);
      }

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            addCategory(item['name'] ?? item['label'] ?? item['value']);
          } else {
            addCategory(item);
          }
        }
      } else if (decoded is Map) {
        final nested = decoded['categories'];
        if (nested is List) {
          for (final item in nested) {
            if (item is Map) {
              addCategory(item['name'] ?? item['label'] ?? item['value']);
            } else {
              addCategory(item);
            }
          }
        } else if (nested is Map) {
          for (final item in nested.values) {
            if (item is Map) {
              addCategory(item['name'] ?? item['label'] ?? item['value']);
            } else {
              addCategory(item);
            }
          }
        } else {
          for (final item in decoded.values) {
            if (item is Map) {
              addCategory(item['name'] ?? item['label'] ?? item['value']);
            } else {
              addCategory(item);
            }
          }
        }
      } else {
        addCategory(decoded);
      }

      return categories;
    } catch (e) {
      print('ERROR fetchEventCategories: $e');
      return const [];
    }
  }

  Future<String?> createEvent(Event newEvent) async {
    try {
      events.clear();
      final url = Uri.https(_baseUrl, '/events.json');
      final response = await http.post(
        url,
        body: json.encode(newEvent.toJson()),
      );
      if (response.statusCode == 200) {
        print('Event created successfully: ${response.body}');
        final decoded = json.decode(response.body);
        final createdEventId = decoded is Map
            ? decoded['name']?.toString()
            : null;
        await fetchEvents();
        return createdEventId;
      } else {
        print(
          'Failed to create event. Status code: ${response.statusCode}, Response body: ${response.body}',
        );
        throw Exception('Failed to create event');
      }
    } catch (e) {
      print('ERROR createEvent: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final url = Uri.https(_baseUrl, '/events/$eventId.json');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        print('Event deleted successfully');
        await fetchEvents();
      } else {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      print('ERROR deleteEvent: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final url = Uri.https(_baseUrl, '/events/$eventId.json');
      final response = await http.patch(url, body: json.encode(updatedData));
      if (response.statusCode == 200) {
        print('Event updated successfully');
        await fetchEvents();
      } else {
        throw Exception('Failed to update event');
      }
    } catch (e) {
      print('ERROR updateEvent: $e');
      rethrow;
    }
  }

  Future<Event> purchaseTickets({
    required String eventId,
    required String ticketType,
    required int quantity,
    required String userId,
    required List<TicketHolder> holders,
    String? userName,
  }) async {
    if (quantity <= 0) {
      throw TicketPurchaseException('Selecciona una cantidad válida.');
    }
    if (holders.length != quantity) {
      throw TicketPurchaseException(
        'Debes indicar un titular para cada entrada.',
      );
    }

    final invalidHolderIndex = holders.indexWhere((h) => !h.isValid);
    if (invalidHolderIndex >= 0) {
      throw TicketPurchaseException(
        'Revisa los datos del titular en la entrada ${invalidHolderIndex + 1}.',
      );
    }

    for (var attempt = 0; attempt < _purchaseMaxRetries; attempt++) {
      final etagged = await _fetchEventByIdWithEtag(eventId);

      final event = etagged.event;
      final etag = etagged.etag;
      if (event == null) {
        throw TicketPurchaseException(
          'El evento no existe o no está disponible.',
        );
      }

      final alreadyPurchased = await countUserTicketsForEvent(
        eventId: eventId,
        userId: userId,
        userName: userName,
      );

      final maxTicketsPerUser = event.maxTicketsPerUser;
      if (maxTicketsPerUser > 0 &&
          alreadyPurchased + quantity > maxTicketsPerUser) {
        final remaining = (maxTicketsPerUser - alreadyPurchased).clamp(
          0,
          maxTicketsPerUser,
        );
        throw TicketPurchaseException(
          'Has alcanzado el límite de compra. Te quedan: $remaining.',
        );
      }

      final typeIndex = event.ticketTypes.indexWhere(
        (t) => t.type == ticketType,
      );
      if (typeIndex < 0) {
        throw TicketPurchaseException(
          'El tipo de entrada seleccionado no existe.',
        );
      }

      final currentType = event.ticketTypes[typeIndex];
      if (currentType.remaining < quantity) {
        throw TicketPurchaseException(
          'No quedan suficientes entradas de "${currentType.type}".',
        );
      }

      final updatedTicketTypes = List<TicketType>.from(event.ticketTypes);
      updatedTicketTypes[typeIndex] = TicketType(
        capacity: currentType.capacity,
        description: currentType.description,
        price: currentType.price,
        remaining: currentType.remaining - quantity,
        type: currentType.type,
      );

      final updateOk = await _patchEventTicketTypesIfMatch(
        baseEvent: event,
        eventId: eventId,
        etag: etag,
        ticketTypes: updatedTicketTypes,
      );

      if (!updateOk) {
        continue; // ETag changed, retry.
      }

      final now = DateTime.now();
      final baseTicketId = now.millisecondsSinceEpoch;
      var createdCount = 0;
      try {
        for (var i = 0; i < quantity; i++) {
          final idTicket = baseTicketId + i;
          final sold = SoldTicket(
            buyerUserId: userId,
            eventId: eventId,
            holder: holders[i],
            idTicket: idTicket,
            purchaseDate: now,
            isCheckedIn: false,
            ticketType: currentType.type,
          );
          await createSoldTicket(sold, refresh: false);
          createdCount++;
        }
      } catch (e) {
        // Best effort rollback: re-add the tickets that were not created.
        final rollbackQuantity = quantity - createdCount;
        if (rollbackQuantity > 0) {
          try {
            await _incrementTicketTypeRemainingBestEffort(
              eventId: eventId,
              ticketType: currentType.type,
              quantity: rollbackQuantity,
            );
          } catch (_) {
            // no-op
          }
        }
        rethrow;
      }

      try {
        await fetchEvents();
      } catch (_) {
        // no-op (purchase already completed)
      }

      try {
        await fetchSoldTickets();
      } catch (_) {
        // no-op
      }

      try {
        final refreshed = await fetchEventById(eventId);
        if (refreshed != null) return refreshed;
      } catch (_) {
        // no-op
      }
      return Event(
        id: event.id,
        category: event.category,
        createdAt: event.createdAt,
        date: event.date,
        description: event.description,
        imageUrl: event.imageUrl,
        isActive: event.isActive,
        location: event.location,
        maxTicketsPerUser: event.maxTicketsPerUser,
        organizerId: event.organizerId,
        ticketTypes: updatedTicketTypes,
        title: event.title,
        validated: event.validated,
      );
    }

    throw TicketPurchaseException(
      'No se pudo completar la compra. Inténtalo de nuevo.',
    );
  }

  Future<int> countUserTicketsForEvent({
    required String eventId,
    required String userId,
    String? userName,
  }) async {
    final tickets = await fetchUserTicketsForEvent(
      eventId: eventId,
      userId: userId,
      userName: userName,
    );
    return tickets.length;
  }

  Future<List<SoldTicket>> fetchUserTicketsForEvent({
    required String eventId,
    required String userId,
    String? userName,
  }) async {
    final normalizedUserName = userName?.trim();
    try {
      final tickets = await fetchSoldTicketsForEvent(eventId);
      final filtered = tickets
          .where(
            (t) => _matchesTicketOwner(
              t,
              userId: userId,
              userName: normalizedUserName,
            ),
          )
          .toList();
      filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      return filtered;
    } catch (_) {
      // Fallback to local cache / full fetch.
      await fetchSoldTickets();
      final filtered = soldTickets
          .where((t) => t.eventId == eventId)
          .where(
            (t) => _matchesTicketOwner(
              t,
              userId: userId,
              userName: normalizedUserName,
            ),
          )
          .toList();
      filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      return filtered;
    }
  }

  Future<List<SoldTicket>> fetchSoldTicketsForEvent(String eventId) async {
    final url = Uri.https(_baseUrl, '/soldTickets.json', {
      'orderBy': '"eventId"',
      'equalTo': '"$eventId"',
    });
    final response = await http.get(url);

    if (response.statusCode != 200 || response.body == 'null') {
      return const [];
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map) return const [];

    final result = <SoldTicket>[];
    for (final value in decoded.values) {
      if (value is Map<String, dynamic>) {
        result.add(SoldTicket.fromJson(value));
      } else if (value is Map) {
        result.add(
          SoldTicket.fromJson(value.map((k, v) => MapEntry(k.toString(), v))),
        );
      }
    }

    return result;
  }

  Future<MapEntry<String, SoldTicket>?> fetchSoldTicketEntryByIdTicket(
    int idTicket,
  ) async {
    final url = Uri.https(_baseUrl, '/soldTickets.json', {
      'orderBy': '"idTicket"',
      'equalTo': '$idTicket',
    });
    final response = await http.get(url);

    if (response.statusCode != 200 || response.body == 'null') {
      return null;
    }

    final decoded = json.decode(response.body);
    return _firstSoldTicketEntryFromDecoded(decoded);
  }

  Future<MapEntry<String, SoldTicket>?> fetchSoldTicketEntryByQrCode(
    String qrCode,
  ) async {
    final normalized = qrCode.trim();
    if (normalized.isEmpty) return null;

    final url = Uri.https(_baseUrl, '/soldTickets.json', {
      'orderBy': '"qrCode"',
      'equalTo': '"$normalized"',
    });
    final response = await http.get(url);

    if (response.statusCode != 200 || response.body == 'null') {
      return null;
    }

    final decoded = json.decode(response.body);
    return _firstSoldTicketEntryFromDecoded(decoded);
  }

  Future<MapEntry<String, SoldTicket>?> fetchSoldTicketEntryByScanValue(
    String scanValue,
  ) async {
    final raw = scanValue.trim();
    if (raw.isEmpty) return null;

    final parsedId = int.tryParse(raw);
    if (parsedId != null) {
      final byId = await fetchSoldTicketEntryByIdTicket(parsedId);
      if (byId != null) return byId;
    }

    final byQr = await fetchSoldTicketEntryByQrCode(raw);
    if (byQr != null) return byQr;

    final suffixMatch = RegExp(r'(\d+)$').firstMatch(raw);
    if (suffixMatch != null) {
      final suffixId = int.tryParse(suffixMatch.group(1)!);
      if (suffixId != null && suffixId != parsedId) {
        return fetchSoldTicketEntryByIdTicket(suffixId);
      }
    }

    return null;
  }

  MapEntry<String, SoldTicket>? _firstSoldTicketEntryFromDecoded(
    dynamic decoded,
  ) {
    if (decoded is! Map || decoded.isEmpty) return null;

    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        return MapEntry(key, SoldTicket.fromJson(value));
      }

      if (value is Map) {
        final mapped = value.map((k, v) => MapEntry(k.toString(), v));
        return MapEntry(key, SoldTicket.fromJson(mapped));
      }
    }

    return null;
  }

  Future<_EtaggedEvent> _fetchEventByIdWithEtag(String eventId) async {
    final url = Uri.https(_baseUrl, '/events/$eventId.json');
    final response = await http.get(
      url,
      headers: const {'X-Firebase-ETag': 'true'},
    );

    if (response.statusCode != 200 || response.body == 'null') {
      return const _EtaggedEvent(event: null, etag: '');
    }

    final etag = response.headers['etag'] ?? '';
    final decoded = json.decode(response.body);
    if (decoded is! Map) {
      return _EtaggedEvent(event: null, etag: etag);
    }

    final eventMap = decoded.map((k, v) => MapEntry(k.toString(), v));
    return _EtaggedEvent(
      event: Event.fromJson(eventMap, id: eventId),
      etag: etag,
    );
  }

  Future<bool> _patchEventTicketTypesIfMatch({
    required Event baseEvent,
    required String eventId,
    required String etag,
    required List<TicketType> ticketTypes,
  }) async {
    if (etag.isEmpty) {
      throw TicketPurchaseException(
        'No se pudo verificar la versión del evento (ETag vacío).',
      );
    }

    final url = Uri.https(_baseUrl, '/events/$eventId.json');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'if-match': etag,
    };

    final updatedEventJson = baseEvent.toJson()
      ..['ticketTypes'] = ticketTypes.map((e) => e.toJson()).toList();

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(updatedEventJson),
    );

    if (response.statusCode == 412) return false;
    if (response.statusCode == 200) return true;

    throw TicketPurchaseException(
      'No se pudo actualizar el stock del evento (${response.statusCode}). ${response.body}',
    );
  }

  Future<void> _incrementTicketTypeRemainingBestEffort({
    required String eventId,
    required String ticketType,
    required int quantity,
  }) async {
    for (var attempt = 0; attempt < _purchaseMaxRetries; attempt++) {
      final etagged = await _fetchEventByIdWithEtag(eventId);
      final event = etagged.event;
      if (event == null) return;

      final index = event.ticketTypes.indexWhere((t) => t.type == ticketType);
      if (index < 0) return;

      final current = event.ticketTypes[index];
      final updated = List<TicketType>.from(event.ticketTypes);
      updated[index] = TicketType(
        capacity: current.capacity,
        description: current.description,
        price: current.price,
        remaining: current.remaining + quantity,
        type: current.type,
      );

      final ok = await _patchEventTicketTypesIfMatch(
        baseEvent: event,
        eventId: eventId,
        etag: etagged.etag,
        ticketTypes: updated,
      );
      if (ok) return;
    }
  }

  bool _matchesTicketOwner(
    SoldTicket ticket, {
    required String userId,
    String? userName,
  }) {
    final normalizedUserName = userName?.trim();
    return ticket.buyerUserId == userId ||
        (normalizedUserName != null &&
            normalizedUserName.isNotEmpty &&
            ticket.buyerUserId == normalizedUserName);
  }

  Future<Event?> fetchEventById(String eventId) async {
    try {
      final url = Uri.https(_baseUrl, '/events/$eventId.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> eventMap = json.decode(response.body);
        return Event.fromJson(eventMap, id: eventId);
      }
      return null;
    } catch (e) {
      print('ERROR fetchEventById: $e');
      rethrow;
    }
  }

  Future<List<Event>> fetchEvents() async {
    try {
      events.clear();
      final url = Uri.https(_baseUrl, '/events.json');
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value == null) return;
            events.add(Event.fromJson(value, id: key));
          });
        } else if (decoded is List) {
          for (var i = 0; i < decoded.length; i++) {
            final value = decoded[i];
            if (value == null) continue;
            if (value is Map<String, dynamic>) {
              events.add(Event.fromJson(value, id: i.toString()));
            }
          }
        }
      }

      notifyListeners();
      return events;
    } catch (e) {
      print('ERROR fetchEvents: $e');
      rethrow;
    }
  }
  //-----------------------------------------
  //-----------------------------------------

  Future<String> uploadEventImage({
    required Uint8List bytes,
    required String organizerId,
    String? eventId,
    String? fileName,
    String? contentType,
  }) async {
    final normalizedOrganizerId = organizerId.trim();
    if (normalizedOrganizerId.isEmpty) {
      throw Exception('No se pudo subir la imagen: organizerId vacío');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = (fileName == null || fileName.trim().isEmpty)
        ? 'event_image_$timestamp.jpg'
        : '${timestamp}_${fileName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final folderId = (eventId == null || eventId.trim().isEmpty)
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : eventId.trim();
    final resolvedContentType =
        (contentType == null || contentType.trim().isEmpty)
        ? 'image/jpeg'
        : contentType.trim();
    final folder = 'events/$normalizedOrganizerId/$folderId';

    try {
      return await _cloudinaryService.uploadImage(
        bytes: bytes,
        folder: folder,
        fileName: safeFileName,
      );
    } catch (e) {
      throw Exception('Cloudinary: $e (contentType: $resolvedContentType)');
    }
  }

  Future<String> uploadUserProfileImage({
    required Uint8List bytes,
    required String userId,
    required bool isCompany,
    String? fileName,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw Exception('No se pudo subir la imagen: userId vacío');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = (fileName == null || fileName.trim().isEmpty)
        ? 'profile_$timestamp.jpg'
        : '${timestamp}_${fileName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final folder = isCompany
        ? 'users/companies/$normalizedUserId/profile'
        : 'users/clients/$normalizedUserId/profile';

    return _cloudinaryService.uploadImage(
      bytes: bytes,
      folder: folder,
      fileName: safeFileName,
    );
  }

  //-----------------------------------------
  //-----------------------------------------
  //SOLD TICKETS
  Future<int> createSoldTicket(
    SoldTicket newTicket, {
    bool refresh = true,
  }) async {
    try {
      final url = Uri.https(_baseUrl, '/soldTickets.json');
      final response = await http.post(
        url,
        body: json.encode(newTicket.toJson()),
      );
      if (response.statusCode == 200) {
        print('Sold ticket created successfully: ${response.body}');
        await _scheduleReminderForTicket(newTicket);
        if (refresh) {
          await fetchSoldTickets();
        }
      } else {
        print(
          'Failed to create sold ticket. Status code: ${response.statusCode}, Response body: ${response.body}',
        );
        throw Exception('Failed to create sold ticket');
      }
      return response.statusCode;
    } catch (e) {
      print('ERROR createSoldTicket: $e');
      rethrow;
    }
  }

  Future<void> deleteSoldTicket(String ticketId) async {
    try {
      final url = Uri.https(_baseUrl, '/soldTickets/$ticketId.json');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        print('Sold ticket deleted successfully');
        await fetchSoldTickets();
      } else {
        throw Exception('Failed to delete sold ticket');
      }
    } catch (e) {
      print('ERROR deleteSoldTicket: $e');
      rethrow;
    }
  }

  Future<void> updateSoldTicket(
    String ticketId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final url = Uri.https(_baseUrl, '/soldTickets/$ticketId.json');
      final response = await http.patch(url, body: json.encode(updatedData));
      if (response.statusCode == 200) {
        print('Sold ticket updated successfully');
        await fetchSoldTickets();
      } else {
        throw Exception('Failed to update sold ticket');
      }
    } catch (e) {
      print('ERROR updateSoldTicket: $e');
      rethrow;
    }
  }

  Future<SoldTicket?> fetchSoldTicketById(String ticketId) async {
    try {
      final url = Uri.https(_baseUrl, '/soldTickets/$ticketId.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> ticketMap = json.decode(response.body);
        return SoldTicket.fromJson(ticketMap);
      }
      return null;
    } catch (e) {
      print('ERROR fetchSoldTicketById: $e');
      rethrow;
    }
  }

  Future<List<SoldTicket>> fetchSoldTickets() async {
    try {
      soldTickets.clear();
      final url = Uri.https(_baseUrl, '/soldTickets.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        print('Response Body: ${response.body}');
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value == null) return;
            soldTickets.add(SoldTicket.fromJson(value));
          });
        } else if (decoded is List) {
          for (final value in decoded) {
            if (value == null) continue;
            if (value is Map<String, dynamic>) {
              soldTickets.add(SoldTicket.fromJson(value));
            }
          }
        }
      }

      await _scheduleRemindersForCurrentUserTickets();
      notifyListeners();
      return soldTickets;
    } catch (e) {
      print('ERROR fetchSoldTickets: $e');
      rethrow;
    }
  }

  //-----------------------------------------
  //-----------------------------------------

  Future<void> _scheduleRemindersForCurrentUserTickets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) return;

    for (final ticket in soldTickets) {
      if (ticket.buyerUserId.trim() != uid) continue;
      await _scheduleReminderForTicket(ticket);
    }
  }

  Future<void> _scheduleReminderForTicket(SoldTicket ticket) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) return;
    if (ticket.buyerUserId.trim() != uid) return;

    Event? event;
    final cached = events.where((e) => e.id == ticket.eventId).toList();
    if (cached.isNotEmpty) {
      event = cached.first;
    } else {
      event = await fetchEventById(ticket.eventId);
    }
    if (event == null) return;

    final reminderId = _buildReminderId(ticket);
    final dateLabel = _formatDateTime(event.date);
    await _notificationService.scheduleEventReminder(
      id: reminderId,
      title: 'Recordatorio de entrada',
      body: 'Tu evento "${event.title}" es mañana a las $dateLabel.',
      eventDate: event.date,
    );
  }

  int _buildReminderId(SoldTicket ticket) {
    final source = '${ticket.eventId}-${ticket.idTicket}-${ticket.buyerUserId}';
    return source.hashCode & 0x7fffffff;
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  //------------------------------------------
  //----------CREDENTIALS PAYPAL--------------
  //------------------------------------------
  Future<PaypalCredentials?> resolvePaypalCredentials({
    bool forceRefresh = false,
  }) async {
    if (PaymentConfig.paypalOverrideInsecureClientCredentials &&
        PaymentConfig.isPayPalConfigured) {
      final credentials = PaypalCredentials(
        clientId: PaymentConfig.paypalClientId,
        secretKey: PaymentConfig.paypalSecretKey,
      );
      credentials.validate();
      return credentials;
    }

    if (!forceRefresh) {
      final cached = await _paypalCredentialsCacheService.read();
      if (cached != null) return cached;
    }

    try {
      final remote = await fetchPaypalCredentials();
      await _paypalCredentialsCacheService.save(remote);
      return remote;
    } catch (_) {
      final cached = await _paypalCredentialsCacheService.read();
      if (cached != null) return cached;

      if (PaymentConfig.isPayPalConfigured) {
        final fallback = PaypalCredentials(
          clientId: PaymentConfig.paypalClientId,
          secretKey: PaymentConfig.paypalSecretKey,
        );
        fallback.validate();
        return fallback;
      }
      return null;
    }
  }

  Future<void> clearPaypalCredentialsCache() async {
    await _paypalCredentialsCacheService.clear();
  }

  Future<PaypalCredentials> fetchPaypalCredentials() async {
    try {
      final url = Uri.https(_baseUrl, '/paypalCredentials.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> credsMap = json.decode(response.body);
        final credentials = PaypalCredentials.fromJson(credsMap);
        credentials.validate();
        return credentials;
      }
      throw Exception('No se pudieron obtener las credenciales de PayPal');
    } catch (e) {
      print('ERROR fetchPaypalCredentials: $e');
      rethrow;
    }
  }
}

class TicketPurchaseException implements Exception {
  final String message;

  const TicketPurchaseException(this.message);

  @override
  String toString() => message;
}

class _EtaggedEvent {
  final Event? event;
  final String etag;

  const _EtaggedEvent({required this.event, required this.etag});
}
