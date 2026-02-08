import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';


class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 72),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Calendar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'View and manage your events',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      )
    );
  }
}
