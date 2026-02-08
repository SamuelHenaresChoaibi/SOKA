import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Photos Page')),
      body: const Center(
        child: Text(
          'This is the Photos Screen',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
