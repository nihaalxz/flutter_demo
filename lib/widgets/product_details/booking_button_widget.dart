import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/Offer_DTO/OfferResponse_DTO.dart';
import 'package:myfirstflutterapp/models/product_model.dart';

class BookingButtonWidget extends StatelessWidget {
  final Product product;
  final String? currentUserId;
  final DateTime? endDate;
  final OfferResponseDTO? offer;
  final VoidCallback onRequestBooking;
  final VoidCallback onBookAtOriginalPrice;

  const BookingButtonWidget({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.endDate,
    required this.offer,
    required this.onRequestBooking,
    required this.onBookAtOriginalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = product.availability == true &&
        endDate != null &&
        currentUserId != product.ownerId.toString();

    if (offer != null) {
      switch (offer!.status) {
        case "Accepted":
          return _buildAcceptedOfferButton(isButtonEnabled);
        case "Pending":
          return _buildPendingOfferButtons(isButtonEnabled, context);
        case "Rejected":
          return _buildRejectedOfferButton(isButtonEnabled);
        default:
          return _buildDefaultButton(isButtonEnabled);
      }
    } else {
      return _buildDefaultButton(isButtonEnabled);
    }
  }

  Widget _buildAcceptedOfferButton(bool isEnabled) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? onRequestBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Book at Offered Price ₹${offer!.offeredPrice}/day"),
          ),
        ),
        const SizedBox(height: 12),
        _buildOriginalPriceOption(isEnabled),
      ],
    );
  }

  Widget _buildPendingOfferButtons(bool isEnabled, BuildContext context) {
    final savings = product.price - offer!.offeredPrice;
    
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    "Offer Pending",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "You've offered ₹${offer!.offeredPrice}/day (Original: ₹${product.price}/day)",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Option 1: Wait for response (informational)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text(
                    "Option 1: Wait for Response",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "The owner will respond to your offer soon. If accepted, you'll save ₹${savings.toStringAsFixed(2)} per day.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Option 2: Book immediately
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text(
                    "Option 2: Book Immediately",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isEnabled ? onBookAtOriginalPrice : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Book Now at Original Price"),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Don't wait for the offer response. Book immediately at the regular price.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedOfferButton(bool isEnabled) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Your offer was declined",
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildDefaultButton(isEnabled),
      ],
    );
  }

  Widget _buildDefaultButton(bool isEnabled) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onRequestBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("Request Rental"),
      ),
    );
  }

  Widget _buildOriginalPriceOption(bool isEnabled) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isEnabled ? onBookAtOriginalPrice : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[400]!),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text("Book at Original Price ₹${product.price}/day"),
      ),
    );
  }
}