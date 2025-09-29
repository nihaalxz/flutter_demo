import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/Offer_DTO/OfferResponse_DTO.dart';
import 'package:myfirstflutterapp/models/product_model.dart';

class BookingButtonWidget extends StatelessWidget {
  final Product product;
  final String? currentUserId;
  final DateTime? endDate;
  final OfferResponseDTO? offer;
  final VoidCallback onRequestBooking;

  const BookingButtonWidget({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.endDate,
    required this.offer,
    required this.onRequestBooking,
  });

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = product.availability == true &&
        endDate != null &&
        currentUserId != product.ownerId.toString();

    if (offer != null) {
      switch (offer!.status) {
        case "Accepted":
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isButtonEnabled ? onRequestBooking : null,
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
          );
        case "Pending":
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Offer Pending - Waiting for Owner Response"),
            ),
          );
        case "Rejected":
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isButtonEnabled ? onRequestBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Request Rental at Original Price"),
            ),
          );
        default:
          return _buildDefaultButton(isButtonEnabled);
      }
    } else {
      return _buildDefaultButton(isButtonEnabled);
    }
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
}