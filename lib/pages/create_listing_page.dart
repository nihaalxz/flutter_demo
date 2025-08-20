import 'package:flutter/material.dart';

class CreateListingPage extends StatelessWidget {
  const CreateListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // A Scaffold provides the basic page structure (app bar, body, etc.)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Listing'),
      ),
      body: const Center(
        child: Text(
          'Create Listing Page - Coming Soon!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}