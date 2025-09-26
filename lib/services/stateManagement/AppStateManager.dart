import 'package:flutter/material.dart';

// Import all the necessary services
import '../booking_service.dart';
import '../offers_service.dart';
import '../payment_services/payment_service.dart'; // Corrected import path
import '../notification_service.dart';

class AppStateManager with ChangeNotifier {
  // Instantiate all the required services.
  final BookingService _bookingService = BookingService();
  final OfferService _offerService = OfferService();
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService.instance;

  // --- State Properties for Notification Badges ---
  bool _hasUnreadBookings = false;
  bool _hasUnreadOffers = false;
  bool _hasUnreadPayments = false;
  int _unreadNotificationCount = 0;

  // --- Public Getters for the UI to listen to ---
  bool get hasUnreadBookings => _hasUnreadBookings;
  bool get hasUnreadOffers => _hasUnreadOffers;
  bool get hasUnreadPayments => _hasUnreadPayments;
  int get unreadNotificationCount => _unreadNotificationCount;

  AppStateManager() {
    // Fetch the initial counts when the app state is first initialized.
    fetchAllCounts();
  }

  /// Fetches all unread counts from the backend in parallel.
  Future<void> fetchAllCounts() async {
    try {
      // Use Future.wait to fetch all counts simultaneously for better performance.
      final results = await Future.wait([
        _bookingService.getUnreadBookingCount(),
        _offerService.getUnreadOfferCount(),
        _paymentService.getUnreadPaymentCount(),
        _notificationService.getUnreadCount(),
      ]);

      // Update the state based on the counts from the services.
      _hasUnreadBookings = results[0] > 0;
      _hasUnreadOffers = results[1] > 0;
      _hasUnreadPayments = results[2] > 0;
      _unreadNotificationCount = results[3];

      // Notify all listening widgets to rebuild if anything has changed.
      notifyListeners();
    } catch (e) {
      print("Error fetching unread counts: $e");
    }
  }

  /// This should be called from your MainScreen whenever a real-time notification arrives.
  void onNotificationReceived() {
    // A real-time event triggers a full refresh of all counts from the server.
    fetchAllCounts();
  }

  // --- Methods to Clear Badges (called from the UI) ---

  /// Called when the user visits the bookings page.
  Future<void> clearUnreadBookings() async {
    if (_hasUnreadBookings) {
      _hasUnreadBookings = false;
      notifyListeners();
      // Tell the backend to mark the items as "seen".
      await _bookingService.markBookingsAsSeen();
    }
  }

  /// Called when the user visits the offers page.
  Future<void> clearUnreadOffers() async {
    if (_hasUnreadOffers) {
      _hasUnreadOffers = false;
      notifyListeners();
      await _offerService.markOffersAsSeen();
    }
  }

  /// Called when the user visits the payment history page.
  Future<void> clearUnreadPayments() async {
    if (_hasUnreadPayments) {
      _hasUnreadPayments = false;
      notifyListeners();
      await _paymentService.markPaymentsAsSeen();
    }
  }
  
  /// Called when the user visits the notifications page.
  Future<void> clearUnreadNotifications() async {
    if (_unreadNotificationCount > 0) {
      _unreadNotificationCount = 0;
      notifyListeners();
      await _notificationService.markAllAsRead();
    }
  }
}
