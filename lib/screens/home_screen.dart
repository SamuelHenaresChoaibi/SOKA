import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soka/models/models.dart';
import 'package:soka/services/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Client> clients = Provider.of<SokaService>(context).clients; 
    clients.forEach((client) {
      print(client.name);
    });
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
      
      
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
        ),
      ),
      
      body: const Center(child: Text('SOKA')),

      bottomNavigationBar: BottomNavigationBar(items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera), 
          label: 'Photos'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings', backgroundColor: Colors.red,
        ),
      ]),
      
    );
    
  }
}
