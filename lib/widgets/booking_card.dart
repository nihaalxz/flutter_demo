import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../environment/env.dart';
import '../models/BookingResponseDTO.dart';
import '../pages/payments/checkout_page.dart';
import '../pages/rental_handover_page.dart';
import '../services/booking_service.dart';
import 'package:flutter/cupertino.dart';

class BookingCard extends StatelessWidget {
  final BookingResponseDTO booking;
  final bool isRentalView;
  final String currentUserId;
  final Future<void> Function(int bookingId, HandoverAction action)
      onNavigateToHandover;
  final VoidCallback onAction;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isRentalView,
    required this.currentUserId,
    required this.onAction,
    required this.onNavigateToHandover,
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
    final price = booking.totalPrice.toStringAsFixed(2);
    final imageUrl = "${AppConfig.imageBaseUrl}${booking.itemImage}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40),
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
                          Icon(Icons.person_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(subtitle,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                              child: Text(dateRange,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700],
                                      overflow: TextOverflow.ellipsis))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
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
            // ✅ --- ACTION BUTTONS & CODES ---
            _buildActionSection(context),
          ],
        ),
      ),
    );
  }

  /// Builds the dynamic action section based on the user's role and booking status.
  Widget _buildActionSection(BuildContext context) {
    final status = booking.status.toLowerCase();

    // --- Renter's View ---
    if (isRentalView) {
      switch (status) {
        case 'pending':
          return _ActionButtons(
              bookingId: booking.id, isOwnerView: false, onAction: onAction);
        case 'approved':
          return _PayNowButton(booking: booking);
        case 'confirmed':
          return _HandoverButton(
            label: 'Start Rental',
            icon: Icons.qr_code_scanner,
            onPressed: () => onNavigateToHandover(booking.id, HandoverAction.start),
          );
        case 'inprogress':
          return _CodeDisplay(
              code: booking.returnCode, label: 'Your Return Code:');
      }
    }
    // --- Owner's View ---
    else {
      switch (status) {
        case 'pending':
          return _ActionButtons(
              bookingId: booking.id, isOwnerView: true, onAction: onAction);
        case 'confirmed':
          return _CodeDisplay(
              code: booking.startCode, label: 'Renter\'s Start Code:');
        case 'inprogress':
          return _HandoverButton(
            label: 'Confirm Return',
            icon: Icons.key,
            onPressed: () => onNavigateToHandover(booking.id, HandoverAction.complete),
          );
      }
    }

    // Return an empty container if no action is needed
    return const SizedBox.shrink();
  }
}

// --- Helper Widgets for Actions and Status ---

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        break;
      case 'inprogress':
        color = Colors.deepPurple;
        icon = Icons.sync_alt;
        break;
      case 'completed':
        color = Colors.teal;
        icon = Icons.verified_outlined;
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
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

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
                  onPressed: () => handleAction(bookingService.rejectBooking),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  onPressed: () => handleAction(bookingService.approveBooking),
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
                  onPressed: () => handleAction(bookingService.cancelBooking),
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


class _PayNowButton extends StatelessWidget {
  final BookingResponseDTO booking;
  const _PayNowButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment),
        label: const Text("Pay now to confirm"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutPage(booking: booking),
            ),
          );
        },
      ),
    );
  }
}

class _HandoverButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _HandoverButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  final String? code;
  final String label;
  const _CodeDisplay({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code ?? '------',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8),
            ),
          ),
        ],
      ),
    );
  }
}

