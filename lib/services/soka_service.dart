import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class SokaService extends ChangeNotifier {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final String _baseUrl =
      "soka-1a9f3-default-rtdb.europe-west1.firebasedatabase.app";
  List<Company> companies = [];
  List<Event> events = [];
  List<Client> clients = [];
  List<SoldTicket> soldTickets = [];

  SokaService() {
    init();
  }

  Future<void> init() async {
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
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
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
        return Company.fromJson(companyMap);
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
            companies.add(Company.fromJson(value));
          });
        } else if (decoded is List) {
          for (final value in decoded) {
            if (value == null) continue;
            if (value is Map<String, dynamic>) {
              companies.add(Company.fromJson(value));
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
        final createdEventId =
            decoded is Map ? decoded['name']?.toString() : null;
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

  //-----------------------------------------
  //-----------------------------------------
  //SOLD TICKETS
  Future<int> createSoldTicket(SoldTicket newTicket) async {
    try {
      soldTickets.clear();
      final url = Uri.https(_baseUrl, '/soldTickets.json');
      final response = await http.post(
        url,
        body: json.encode(newTicket.toJson()),
      );
      if (response.statusCode == 200) {
        print('Sold ticket created successfully: ${response.body}');
        await fetchSoldTickets();
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

      notifyListeners();
      return soldTickets;
    } catch (e) {
      print('ERROR fetchSoldTickets: $e');
      rethrow;
    }
  }

  //-----------------------------------------
  //-----------------------------------------
}
