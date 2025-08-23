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
  final VoidCallback onAction;

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
    final subtitle = isRentalView
        ? "Rented from: ${booking.ownerName}"
        : "Request from: ${booking.renterName}";
    final dateFormat = DateFormat('MMM d, y');
    final dateRange =
        "${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}";
    final price = "${booking.totalPrice.toStringAsFixed(2)}";
    final imageUrl = "${AppConfig.imageBaseUrl}${booking.itemImage}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // ensures smooth rounded corners
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section: Image + details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 95,
                      height: 95,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image,
                            color: Colors.grey, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(subtitle,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black54),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(dateRange,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54,
                                  overflow: TextOverflow.ellipsis,
                                  
                                  )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            // Bottom row: Status + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: booking.status),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        size: 18, color: Colors.green),
                    Text(price,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
              ],
            ),

            // Conditional action buttons
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

/// Booking status chip
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
      label: Text(status.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// Approve/Reject or Cancel actions
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
        onAction();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Action successful!"),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Action failed: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: isOwnerView
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  onPressed: () =>
                      handleAction(bookingService.rejectBooking),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  onPressed: () =>
                      handleAction(bookingService.approveBooking),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Request'),
                  onPressed: () =>
                      handleAction(bookingService.cancelBooking),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
    );
  }
}
