import 'package:intl/intl.dart';

import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';
import 'package:myfirstflutterapp/widgets/booking_card.dart'; // We will create this next
import 'package:flutter/material.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  // Services
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();

  // State
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  List<BookingResponseDTO> _myRentals = []; // Bookings where I am the renter
  List<BookingResponseDTO> _myItemsBookings = []; // Bookings where I am the owner

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    // Ensure the initial state is loading
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception("User not authenticated.");
      }

      final allBookings = await _bookingService.getMyBookings();

      // Filter bookings into two separate lists
      final rentals = allBookings.where((b) => b.renterId == userId).toList();
      final itemBookings = allBookings.where((b) => b.ownerId == userId).toList();
      
      // Sort bookings by creation date, newest first
      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      itemBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _myRentals = rentals;
          _myItemsBookings = itemBookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load bookings: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // The number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Rentals'),
              Tab(text: 'My Items'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // "My Rentals" Tab Content
            _buildBookingList(
              bookings: _myRentals,
              isRentalView: true,
            ),
            // "My Items" Tab Content
            _buildBookingList(
              bookings: _myItemsBookings,
              isRentalView: false,
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget to build the list view for each tab.
  Widget _buildBookingList({
    required List<BookingResponseDTO> bookings,
    required bool isRentalView,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchBookings,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Text(
          isRentalView ? "You haven't rented any items yet." : "You have no booking requests for your items.",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Use RefreshIndicator for pull-to-refresh
    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            isRentalView: isRentalView,
            currentUserId: _currentUserId!,
            onAction: _fetchBookings, // Pass a callback to refresh the list after an action
          );
        },
      ),
    );
  }
}
