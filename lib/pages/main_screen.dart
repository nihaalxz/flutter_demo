import 'package:flutter/material.dart';
// 1. Import all the pages you want to switch between
import 'package:myfirstflutterapp/pages/home_page.dart';
import 'package:myfirstflutterapp/pages/create_listing_page.dart'; // Assuming you have these
import 'package:myfirstflutterapp/pages/bookings_page.dart';
import 'package:myfirstflutterapp/pages/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Variable to keep track of the currently selected tab index
  int _selectedIndex = 0;

  // List of the widgets (pages) to display for each tab
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    CreateListingPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  // This function is called when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the state with the new index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will display the page from the list based on the selected index
      body: _pages.elementAt(_selectedIndex),

      // The main navigation bar
      bottomNavigationBar: BottomNavigationBar(
        // List of items (tabs) in the bar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Optional: different icon when active
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // Highlights the current tab
        onTap: _onItemTapped, // Sets the handler for tap events

        // --- Styling ---
        type: BottomNavigationBarType.fixed, // Keeps all labels visible
        selectedItemColor: Colors.amber[800], // Color for the selected tab
        unselectedItemColor: Colors.grey, // Color for inactive tabs
        showUnselectedLabels: true, // Ensures all labels are shown
      ),
    );
  }
}