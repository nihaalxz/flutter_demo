import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/Offer_DTO/OfferResponse_DTO.dart';
import 'package:myfirstflutterapp/services/offers_service.dart';
import 'package:myfirstflutterapp/widgets/Offer_card.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final OfferService _offerService = OfferService();
  Future<Map<String, List<OfferResponseDTO>>>? _offersFuture;
  int _selectedSegment = 0; // For Cupertino

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchOffers();
  }

  Future<Map<String, List<OfferResponseDTO>>> _fetchOffers() async {
    try {
      final results = await Future.wait([
        _offerService.getMyOffers(),
        _offerService.getReceivedOffers(),
      ]);
      return {
        'myOffers': results[0],
        'receivedOffers': results[1],
      };
    } catch (e) {
      rethrow;
    }
  }

  void _refreshOffers() {
    setState(() {
      _offersFuture = _fetchOffers();
    });
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
          title: const Text('My Offers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Made by Me'),
              Tab(text: 'Received Offers'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('My Offers'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(padding: EdgeInsets.all(8.0), child: Text('Made by Me')),
                  1: Padding(padding: EdgeInsets.all(8.0), child: Text('Received')),
                },
                onValueChanged: (int newValue) {
                  setState(() => _selectedSegment = newValue);
                },
                groupValue: _selectedSegment,
              ),
            ),
            Expanded(child: _buildBody(isCupertino: true)),
          ],
        ),
      ),
    );
  }

  // --- Shared Body Logic ---

  Widget _buildBody({bool isCupertino = false}) {
    return FutureBuilder<Map<String, List<OfferResponseDTO>>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final myOffers = snapshot.data?['myOffers'] ?? [];
        final receivedOffers = snapshot.data?['receivedOffers'] ?? [];
        
        if (isCupertino) {
           return _buildOfferList(
              _selectedSegment == 0 ? myOffers : receivedOffers,
              isMyOffers: _selectedSegment == 0,
            );
        } else {
          return TabBarView(
            children: [
              _buildOfferList(myOffers, isMyOffers: true),
              _buildOfferList(receivedOffers, isMyOffers: false),
            ],
          );
        }
      },
    );
  }

  Widget _buildOfferList(List<OfferResponseDTO> offers, {required bool isMyOffers}) {
    if (offers.isEmpty) {
      return Center(
        child: Text(isMyOffers ? 'You have not made any offers.' : 'You have not received any offers.'),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: () async => _refreshOffers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return OfferCard(
            offer: offer,
            isMyOffer: isMyOffers,
            onAction: _refreshOffers,
          );
        },
      ),
    );
  }
}
