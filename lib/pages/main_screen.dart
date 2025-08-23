import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/notification_model.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

// --- Assumed Imports ---
import 'package:myfirstflutterapp/pages/home_page.dart';
import 'package:myfirstflutterapp/pages/create_listing_page.dart';
import 'package:myfirstflutterapp/pages/bookings_page.dart';
import 'package:myfirstflutterapp/pages/profile_page.dart';
import 'package:myfirstflutterapp/services/notification_service.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription<NotificationModel>? _notificationSubscription;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    CreateListingPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Use addPostFrameCallback to ensure the context is available for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      appState.fetchNotificationCount();
      appState.fetchPendingBookingCount();
    });
    
    // Start the real-time connection
    NotificationService.instance.connectToNotificationHub();

    // Listen for incoming notifications to show the pop-up banner
    _notificationSubscription =
        NotificationService.instance.notificationStream.listen((notification) {
      showSimpleNotification(
        Text(notification.title),
        subtitle: Text(notification.message ?? ''),
        background: Colors.blue.shade700,
        duration: const Duration(seconds: 5),
      );
    });
  }

  @override
  void dispose() {
    // Stop the connection and cancel the listener when the user logs out
    _notificationSubscription?.cancel();
    NotificationService.instance.disconnectFromNotificationHub();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      // Use a Consumer to listen for count changes and rebuild the navigation bar
      bottomNavigationBar: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          return BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Create',
              ),
              BottomNavigationBarItem(
                // Use a helper to build the icon with a badge for bookings
                icon: _buildIconWithBadge(
                  icon: Icons.calendar_today_outlined,
                  count: appState.pendingBookingCount,
                ),
                activeIcon: _buildIconWithBadge(
                  icon: Icons.calendar_today,
                  count: appState.pendingBookingCount,
                ),
                label: 'Bookings',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromARGB(255, 255, 0, 0),
            unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
            showUnselectedLabels: true,
          );
        },
      ),
    );
  }

  /// A helper widget that builds an icon with a notification badge.
  Widget _buildIconWithBadge({required IconData icon, required int count}) {
    return Stack(
      clipBehavior: Clip.none, // Allows the badge to render outside the icon's bounds
      children: <Widget>[
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}
