import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';
import 'package:myfirstflutterapp/widgets/booking_card.dart';
import 'package:shimmer/shimmer.dart';

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
  List<BookingResponseDTO> _myRentals = [];
  List<BookingResponseDTO> _myItemsBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception("User not authenticated.");

      final allBookings = await _bookingService.getMyBookings();

      final rentals = allBookings.where((b) => b.renterId == userId).toList();
      final itemBookings = allBookings.where((b) => b.ownerId == userId).toList();

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
      length: 2,
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
            _buildBookingList(bookings: _myRentals, isRentalView: true),
            _buildBookingList(bookings: _myItemsBookings, isRentalView: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList({
    required List<BookingResponseDTO> bookings,
    required bool isRentalView,
  }) {
    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 8),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isRentalView
                  ? "You haven't rented any items yet."
                  : "No one has booked your items yet.",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
            onAction: _fetchBookings,
          );
        },
      ),
    );
  }

  /// Shimmer loading placeholder
  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 4,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color.fromARGB(110, 224, 224, 224),
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}