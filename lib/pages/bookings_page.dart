import 'dart:io';
import 'package:flutter/cupertino.dart';
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

  // State for Cupertino Segmented Control
  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    // Reset state before fetching, especially for pull-to-refresh
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

      // Filter bookings into separate lists
      final rentals = allBookings.where((b) => b.renterId == userId).toList();
      final itemBookings =
          allBookings.where((b) => b.ownerId == userId).toList();

      // Sort by creation date
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
        setState(() {
          _errorMessage =
              'No Internet Connection. Please check your network and try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load bookings: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check the platform to build the appropriate UI
    if (Platform.isIOS) {
      return _buildCupertinoPage();
    } else {
      return _buildMaterialPage();
    }
  }

  // --- Material Design UI (Android) ---
  Widget _buildMaterialPage() {
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

  // --- Cupertino Design UI (iOS) ---
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
                  1: Padding(padding: EdgeInsets.all(8.0), child: Text('My Items')),
                },
                onValueChanged: (int newValue) {
                  setState(() {
                    _selectedSegment = newValue;
                  });
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
      // Use an adaptive widget for the error state
      return _buildAdaptiveErrorState();
    }
    
    // Use an adaptive widget for the empty state
    if (bookings.isEmpty) {
      return _buildAdaptiveEmptyState(isRentalView);
    }
    
    // Use an adaptive widget for the refresh indicator
    return _buildAdaptiveRefreshIndicator(
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

  // --- Adaptive Helper Widgets ---

  Widget _buildAdaptiveRefreshIndicator({required Widget child}) {
    if (Platform.isIOS) {
      // For iOS, we need to wrap the list in a CustomScrollView to use the Cupertino refresh control
      return CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _fetchBookings,
          ),
          SliverToBoxAdapter(child: child),
        ],
      );
    } else {
      return RefreshIndicator(
        onRefresh: _fetchBookings,
        child: child,
      );
    }
  }

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
            height: 150, // Adjusted height to better match BookingCard
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

