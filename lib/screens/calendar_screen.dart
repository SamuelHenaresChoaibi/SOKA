import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calendar Page')),
      body: const Center(
        child: Text(
          'Calendar',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
