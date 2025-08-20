import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';

class BookingCard extends StatelessWidget {
  final BookingResponseDTO booking;
  final bool isRentalView;
  final String currentUserId;
  final VoidCallback onAction; // Callback to refresh the list

  const BookingCard({
    super.key,
    required this.booking,
    required this.isRentalView,
    required this.currentUserId,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = booking.itemName;
    final subtitle = isRentalView ? "Rented from: ${booking.ownerName}" : "Rented by: ${booking.renterName}";
    final dateFormat = DateFormat('MMM d, y');
    final dateRange = "${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}";
    final price = "${booking.totalPrice.toStringAsFixed(2)}";
    final imageUrl = "${AppConfig.imageBaseUrl}${booking.itemImage}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4, // Increased elevation for more depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Slightly more rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Increased padding for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Slightly more rounded image
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 90, // Slightly larger image
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), // Larger title font
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis), // Allow 2 lines for subtitle
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(dateRange, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: booking.status),
                Row(
                  children: [
                    Icon(Icons.currency_rupee, size: 18, color: Colors.green),
                    Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
            // Show action buttons if the booking is in a 'Pending' state
            if (booking.status.toLowerCase() == 'pending')
              _ActionButtons(
                bookingId: booking.id,
                isOwnerView: !isRentalView,
                onAction: onAction,
              ),
          ],
        ),
      ),
    );
  }
}

/// A chip to display the booking status with appropriate colors.
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case 'cancelled':
        color = Colors.grey;
        icon = Icons.do_not_disturb_alt;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded chip
    );
  }
}

/// A widget to show contextual action buttons (Approve/Reject or Cancel).
class _ActionButtons extends StatelessWidget {
  final int bookingId;
  final bool isOwnerView;
  final VoidCallback onAction;

  const _ActionButtons({
    required this.bookingId,
    required this.isOwnerView,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();

    void handleAction(Future<void> Function(int) action) async {
      try {
        await action(bookingId);
        onAction(); // Trigger the refresh callback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action successful!"), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0), // Increased top padding
      child: isOwnerView
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  onPressed: () => handleAction(bookingService.rejectBooking),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  onPressed: () => handleAction(bookingService.approveBooking),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Request'),
                  onPressed: () => handleAction(bookingService.cancelBooking),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
    );
  }
}