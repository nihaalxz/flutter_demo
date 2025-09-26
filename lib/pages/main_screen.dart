import 'dart:async';
import 'dart:io'; // 👈 1. Import for platform detection
import 'package:flutter/cupertino.dart'; // 👈 2. Import for iOS widgets
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/notification_model.dart';
import 'package:myfirstflutterapp/pages/Auth/login_page.dart';
import 'package:myfirstflutterapp/pages/wishlist_page.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

// --- Assumed Imports ---
import 'package:myfirstflutterapp/pages/home_page.dart';
import 'package:myfirstflutterapp/pages/product/create_listing_page.dart';
import 'package:myfirstflutterapp/pages/bookings_page.dart';
import 'package:myfirstflutterapp/pages/Auth/profile_page.dart';
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

  // ✅ FIX: The list of pages now correctly includes all 5 tabs.
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    WishlistPage(),
    CreateListingPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Use addPostFrameCallback to safely access the Provider after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      
      // ✅ FIX: Call the single, correct method to fetch all counts.
      appState.fetchAllCounts();

      // Listen for real-time notifications to trigger count updates
      _notificationSubscription = NotificationService.instance.notificationStream.listen((notification) {
        // When any real-time notification arrives, tell the state manager to refresh all counts.
        appState.onNotificationReceived();
        
        // Show the pop-up banner for the new notification.
        showSimpleNotification(
            Text(notification.title),
            subtitle: Text(notification.message ?? ''),
            background: Colors.blue.shade700,
        );
      });
    });

    NotificationService.instance.connectToNotificationHub();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    NotificationService.instance.disconnectFromNotificationHub();
    super.dispose();
  }

  /// ✅ FIX: This method now correctly clears the badge when a tab is visited.
  void _onItemTapped(int index) {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    
    // Index 3 corresponds to the BookingsPage in the _pages list.
    if (index == 3) { 
      appState.clearUnreadBookings();
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

 @override
  Widget build(BuildContext context) {
    // ✅ --- THIS IS THE KEY FIX ---
    // The Consumer now also checks the login status.
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        // If the state manager reports the user is logged out,
        // immediately navigate to the LoginPage.
        if (!appState.isLoggedIn) {
          // Use a post-frame callback to ensure we don't try to navigate
          // while the widget tree is still building.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false
            );
          });
          // Return a temporary empty container while the navigation happens.
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // If the user is logged in, build the normal UI.
        return Platform.isIOS
            ? _buildCupertinoScaffold(appState)
            : _buildMaterialScaffold(appState);
      },
    );
  }
  // --- Adaptive UI Builders ---

  Widget _buildMaterialScaffold(AppStateManager appState) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(
            icon: _buildIconWithBadge(
              icon: Icons.calendar_today_outlined,
              // ✅ FIX: Use the correct boolean flag from the AppStateManager.
              showBadge: appState.hasUnreadBookings, 
            ),
            label: 'Bookings',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        // Example styling, adjust as needed
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildCupertinoScaffold(AppStateManager appState) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart), label: 'Wishlist'),
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.add_circled), label: 'Create'),
           BottomNavigationBarItem(
            icon: _buildIconWithBadge(
              icon: CupertinoIcons.calendar,
              // ✅ FIX: Use the correct boolean flag from the AppStateManager.
              showBadge: appState.hasUnreadBookings, 
            ),
            label: 'Bookings',
          ),
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => _pages.elementAt(index),
        );
      },
    );
  }

  /// ✅ UPDATED: A helper widget that builds an icon with a simple red dot.
  Widget _buildIconWithBadge({required IconData icon, required bool showBadge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              // A simple dot without a number for a cleaner look.
              constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            ),
          )
      ],
    );
  }
}
