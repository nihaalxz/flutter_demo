import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';
import 'package:myfirstflutterapp/widgets/booking_card.dart'; // Using the same card for consistency

class RentalHistoryPage extends StatefulWidget {
  const RentalHistoryPage({super.key});

  @override
  State<RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<RentalHistoryPage> {
  final BookingService _bookingService = BookingService();
  late Future<List<BookingResponseDTO>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _bookingService.getMyBookings(status: 'Completed');
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
      body: _buildBody(),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Rental History')),
      child: _buildBody(isCupertino: true),
    );
  }

  Widget _buildBody({bool isCupertino = false}) {
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

        final listview = ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: history.length,
          itemBuilder: (context, index) {
            // Here you would use a simplified version of your BookingCard,
            // or the same one if it handles the 'Completed' state well.
            return Text("Booking #${history[index].id}");
          },
        );

        return RefreshIndicator.adaptive(
          onRefresh: _refreshHistory,
          child: listview,
        );
      },
    );
  }
}
