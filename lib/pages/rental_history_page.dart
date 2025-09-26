import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';
import 'package:myfirstflutterapp/widgets/booking_card.dart';
import 'package:myfirstflutterapp/pages/rental_handover_page.dart';

class RentalHistoryPage extends StatefulWidget {
  const RentalHistoryPage({super.key});

  @override
  State<RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<RentalHistoryPage> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  late Future<List<BookingResponseDTO>> _historyFuture;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = await _authService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _historyFuture = _bookingService.getMyBookings(status: 'Completed');
      });
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _bookingService.getMyBookings(status: 'Completed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }

  Widget _buildMaterialPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental History')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Rental History'),
      ),
      child: SafeArea(child: _buildBody(isCupertino: true)),
    );
  }
Widget _buildBody({bool isCupertino = false}) {
  if (_currentUserId == null) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }

  return FutureBuilder<List<BookingResponseDTO>>(
    future: _historyFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      final history = snapshot.data ?? [];
      if (history.isEmpty) {
        return const Center(child: Text('You have no completed rentals.'));
      }

      final bottomPadding = MediaQuery.of(context).padding.bottom;

      final listView = ListView.builder(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPadding),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final booking = history[index];
          final bool wasRenter = booking.renterId == _currentUserId;

          return BookingCard(
            booking: booking,
            isRentalView: wasRenter,
            currentUserId: _currentUserId!,
            onAction: () {},
            onNavigateToHandover: (id, action) async {},
          );
        },
      );

      return RefreshIndicator.adaptive(
        onRefresh: _refreshHistory,
        child: listView,
      );
    },
  );
}
}
