import 'dart:async';
import 'dart:io'; // 👈 1. Import for platform detection
import 'package:flutter/cupertino.dart'; // 👈 2. Import for iOS widgets
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

  // The list of pages is shared between both platforms
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    CreateListingPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      appState.fetchNotificationCount();
      appState.fetchPendingBookingCount();
    });
    
    NotificationService.instance.connectToNotificationHub();

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
    // ✅ 3. Use a Consumer to get the latest state for badges
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        // ✅ 4. Check the platform and build the appropriate UI
        if (Platform.isIOS) {
          return _buildCupertinoScaffold(appState);
        } else {
          return _buildMaterialScaffold(appState);
        }
      },
    );
  }

  /// Builds the Material Design scaffold for Android.
  Widget _buildMaterialScaffold(AppStateManager appState) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  /// Builds the Cupertino Design scaffold for iOS.
  Widget _buildCupertinoScaffold(AppStateManager appState) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: _buildIconWithBadge(
              icon: CupertinoIcons.calendar,
              count: appState.pendingBookingCount,
            ),
            label: 'Bookings',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        // The tabBuilder handles displaying the correct page automatically.
        return CupertinoTabView(
          builder: (BuildContext context) {
            return _pages[index];
          },
        );
      },
    );
  }

  /// A helper widget that builds an icon with a notification badge.
  /// This works for both Material and Cupertino icons.
  Widget _buildIconWithBadge({required IconData icon, required int count}) {
    return Stack(
      clipBehavior: Clip.none,
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
