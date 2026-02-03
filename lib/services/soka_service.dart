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
    //await fetchSoldTickets();
  }

  //-----------------------------------------
  //-----------------------------------------
  //CLIENTS
  void createClient(String name) {}

  void deleteClient(String userId) {}

  void updateClient(String userId, Map<String, dynamic> updatedData) {}

  Future<List<Client>> fetchClients() async {
    try {
      clients.clear();
      final url = Uri.https(_baseUrl, '/users/clients.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> clientsMap = json.decode(response.body);
        clientsMap.forEach((key, value) {
          clients.add(Client.fromJson(value));
        });
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
  void createCompany(String companyName) {}

  void deleteCompany(String companyId) {}

  void updateCompany(String companyId, Map<String, dynamic> updatedData) {}

  Future<List<Company>> fetchCompanies() async {
    try {
      companies.clear();
      final url = Uri.https(_baseUrl, '/users/companies.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> companiesMap = json.decode(response.body);
        companiesMap.forEach((key, value) {
          companies.add(Company.fromJson(value));
        });
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
  void createEvent(String title) {}

  void deleteEvent(String eventId) {}

  void updateEvent(String eventId, Map<String, dynamic> updatedData) {}

  Future<List<Event>> fetchEvents() async {
        try {
      events.clear();
      final url = Uri.https(_baseUrl, '/events.json');
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> eventsMap = json.decode(response.body);
        eventsMap.forEach((key, value) {
          events.add(Event.fromJson(value));
        });
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
  void createSoldTicket(String holderName) {}

  void updateSoldTicket(String ticketId, Map<String, dynamic> updatedData) {}
  //-----------------------------------------
  //-----------------------------------------

}
