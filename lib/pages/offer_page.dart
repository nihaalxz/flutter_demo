import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    final pageContent = Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIOS ? CupertinoIcons.tag_solid : Icons.local_offer,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'My Offers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A feature to view and manage offers you\'ve made is coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('My Offers'),
        ),
        child: pageContent,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Offers'),
        ),
        body: pageContent,
      );
    }
  }
}
