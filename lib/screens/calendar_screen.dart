import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:table_calendar/table_calendar.dart';
=======
>>>>>>> UI

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Page')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'en_US',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
          ),
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Event Title'),
              subtitle: const Text('Event Description'),
              trailing: const Text('10:00 AM'),
            ),
          ),
        ],
      ),
    );
=======
    return const Placeholder();
>>>>>>> UI
  }
}
