import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';
import 'package:myfirstflutterapp/widgets/booking_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myfirstflutterapp/pages/rental_handover_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  List<BookingResponseDTO> _myRentals = [];
  List<BookingResponseDTO> _myItemsBookings = [];
  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (_myItemsBookings.isEmpty && _myRentals.isEmpty) {
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
        });
      }
    } on SocketException {
        if (mounted) {
            setState(() => _errorMessage = 'No Internet Connection. Please check your network and try again.');
        }
    }
     catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load bookings: ${e.toString()}";
        });
      }
    } finally {
        if(mounted) {
            setState(() => _isLoading = false);
        }
    }
  }

  /// Handles navigation to the code entry page and refreshes the list upon return.
  Future<void> _navigateToHandover(int bookingId, HandoverAction action) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RentalHandoverPage(
          bookingId: bookingId,
          action: action,
        ),
      ),
    );

    // If the handover was successful (returned true), refresh the bookings list
    if (result == true && mounted) {
      _fetchBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }

  // --- Platform-Specific Scaffolding ---
  Widget _buildMaterialPage() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Rentals'),
              Tab(text: 'Received Requests'),
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

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('My Bookings'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(padding: EdgeInsets.all(8.0), child: Text('My Rentals')),
                  1: Padding(padding: EdgeInsets.all(8.0), child: Text('Received')),
                },
                onValueChanged: (int newValue) {
                  setState(() => _selectedSegment = newValue);
                },
                groupValue: _selectedSegment,
              ),
            ),
            Expanded(
              child: _selectedSegment == 0
                  ? _buildBookingList(bookings: _myRentals, isRentalView: true)
                  : _buildBookingList(bookings: _myItemsBookings, isRentalView: false),
            ),
          ],
        ),
      ),
    );
  }

  // --- Shared List Building Logic ---
  Widget _buildBookingList({
    required List<BookingResponseDTO> bookings,
    required bool isRentalView,
  }) {
    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_errorMessage != null) {
      return _buildAdaptiveErrorState();
    }
    
    if (bookings.isEmpty) {
      return _buildAdaptiveEmptyState(isRentalView);
    }
    
    return RefreshIndicator.adaptive(
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
            onNavigateToHandover: _navigateToHandover,
          );
        },
      ),
    );
  }

  // --- Adaptive Helper Widgets ---
  Widget _buildAdaptiveErrorState() {
    final isNetworkError = _errorMessage?.contains('No Internet Connection') ?? false;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNetworkError ? Icons.wifi_off : Icons.error_outline, 
            color: Colors.redAccent, 
            size: 48
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Platform.isIOS
            ? CupertinoButton.filled(onPressed: _fetchBookings, child: const Text("Retry"))
            : ElevatedButton(onPressed: _fetchBookings, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildAdaptiveEmptyState(bool isRentalView) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
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

