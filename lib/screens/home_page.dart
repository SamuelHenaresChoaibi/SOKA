import 'package:flutter/material.dart';
import 'package:soka/services/auth_gate.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
