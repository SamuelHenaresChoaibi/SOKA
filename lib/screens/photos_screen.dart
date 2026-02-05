import 'package:flutter/material.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photos Page')),
      body: const Center(child: Text('This is the Photos Screen')),
    );
  }
}
