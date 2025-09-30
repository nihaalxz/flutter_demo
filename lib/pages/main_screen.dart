import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
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
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  StreamSubscription<UnreadUpdate>? _updateSubscription;
  
  // ✅ Add a controller for CupertinoTabScaffold
  late CupertinoTabController _cupertinoTabController;

  // Your list of pages
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
    
    _selectedIndex = widget.initialIndex;
    // ✅ Initialize the controller with the initial index
    _cupertinoTabController = CupertinoTabController(initialIndex: widget.initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      appState.fetchAllCounts();

      _updateSubscription = NotificationService.instance.unreadUpdateStream.listen((update) {
        showSimpleNotification(
            Text(update.notification.title),
            subtitle: Text(update.notification.message ?? ''),
            background: Theme.of(context).primaryColor,
        );
        appState.updateCountsFromPush(update.unreadCounts);
      });
    });

    NotificationService.instance.connectToNotificationHub();
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _cupertinoTabController.dispose(); // ✅ Dispose the controller
    NotificationService.instance.disconnectFromNotificationHub();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    
    if (index == 3) { 
      appState.clearUnreadBookings();
    }
    
    setState(() {
      _selectedIndex = index;
      // ✅ Update the iOS controller as well
      if (Platform.isIOS) {
        _cupertinoTabController.index = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        if (!appState.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false
            );
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
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
              showBadge: appState.hasUnreadBookings,
            ),
            label: 'Bookings',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildCupertinoScaffold(AppStateManager appState) {
    return CupertinoTabScaffold(
      controller: _cupertinoTabController, // ✅ Use the controller
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart), label: 'Wishlist'),
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.add_circled), label: 'Create'),
           BottomNavigationBarItem(
            icon: _buildIconWithBadge(
              icon: CupertinoIcons.calendar,
              showBadge: appState.hasUnreadBookings,
              isCupertino: true, // ✅ Pass flag for iOS styling
            ),
            label: 'Bookings',
          ),
           const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
        ],
        onTap: _onItemTapped,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => _pages.elementAt(index),
        );
      },
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon, 
    required bool showBadge,
    bool isCupertino = false,
  }) {
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
              decoration: BoxDecoration(
                color: isCupertino ? CupertinoColors.systemRed : Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            ),
          )
      ],
    );
  }
}