import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/Offer_DTO/OfferResponse_DTO.dart';
import '../services/offers_service.dart';

class OfferCard extends StatelessWidget {
  final OfferResponseDTO offer;
  final bool isMyOffer; // True if the current user MADE the offer
  final VoidCallback onAction; // Callback to refresh the list

  const OfferCard({
    super.key,
    required this.offer,
    required this.isMyOffer,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offer.itemName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Original Price: ${currencyFormat.format(offer.originalPrice)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                _StatusChip(status: offer.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMyOffer ? 'Your Offer:' : 'Offer from ${offer.renterName}:',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  currencyFormat.format(offer.offeredPrice),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Show action buttons for received, pending offers
            if (!isMyOffer && offer.status.toLowerCase() == 'pending')
              _ActionButtons(offerId: offer.id, onAction: onAction),
              
            // ✅ --- NEW: Show "Book Now" button for the renter if their offer was accepted ---
            if (isMyOffer && offer.status.toLowerCase() == 'accepted')
              _BookNowButton(offer: offer),
            // --------------------------------------------------------------------------------
          ],
        ),
      ),
    );
  }
}

// Helper widget for status chip
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_top;
        break;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

// Helper widget for Accept/Reject buttons
class _ActionButtons extends StatelessWidget {
  final int offerId;
  final VoidCallback onAction;
  const _ActionButtons({required this.offerId, required this.onAction});

  void _handleAction(BuildContext context, String status) async {
    final offerService = OfferService();
    try {
      await offerService.updateOfferStatus(offerId, status);
      onAction(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer ${status.toLowerCase()}ed!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update offer: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _handleAction(context, 'Rejected'),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _handleAction(context, 'Accepted'),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

// ✅ --- NEW: Helper widget for the "Book Now" button ---
class _BookNowButton extends StatelessWidget {
  final OfferResponseDTO offer;

  const _BookNowButton({required this.offer});

  void _navigateToBooking(BuildContext context) {
    // Here you would navigate to your booking or payment page.
    // You would pass the item ID and the accepted offer price to that page.
    
    // Example of what the navigation might look like:
    /*
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookingPage(
        itemId: offer.itemId,
        acceptedPrice: offer.offeredPrice,
      ),
    ));
    */

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proceeding to book ${offer.itemName} at ₹${offer.offeredPrice.toStringAsFixed(2)}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Book at this Price'),
            onPressed: () => _navigateToBooking(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

