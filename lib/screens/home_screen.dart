import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/screens/calendar_screen.dart';
import 'package:soka/screens/photos_screen.dart';
import 'package:soka/screens/settings_screen.dart';
import 'package:soka/services/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Client> clients = Provider.of<SokaService>(context).clients;
    clients.forEach((client) {
      print(client.name);
    });

    // Contenido según la página seleccionada
    final List<Widget> pages = [
      const Center(child: Text('SOKA Home')),
      const CalendarScreen(),
      const PhotosScreen(),
      const SettingsScreen()
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOKA Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthGate().signOut();
            },
          ),
        ],
      ),

      drawer: Drawer(child: ListView(padding: EdgeInsets.zero)),

      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Photos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
