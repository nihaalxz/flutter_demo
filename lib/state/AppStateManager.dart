import 'package:flutter/material.dart';

// --- Assumed Imports ---
import '../services/booking_service.dart';
import '../services/offers_service.dart';
import '../services/payment_services/payment_service.dart';
import '../services/notification_service.dart';

class AppStateManager with ChangeNotifier {
  // --- Services ---
  final BookingService _bookingService = BookingService();
  final OfferService _offerService = OfferService();
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService.instance;

  // --- State Properties ---
  bool _isLoggedIn = false;
  bool _hasUnreadBookings = false;
  bool _hasUnreadOffers = false;
  bool _hasUnreadPayments = false;
  int _unreadNotificationCount = 0;

  // ✅ 1. A unique key for each user session. This is the core of the fix.
  Key _sessionKey = UniqueKey();

  // --- Public Getters for the UI ---
  bool get isLoggedIn => _isLoggedIn;
  Key get sessionKey => _sessionKey;
  bool get hasUnreadBookings => _hasUnreadBookings;
  bool get hasUnreadOffers => _hasUnreadOffers;
  bool get hasUnreadPayments => _hasUnreadPayments;
  int get unreadNotificationCount => _unreadNotificationCount;
  
  // ✅ ADD: Missing getter that HomePage is trying to access
  bool get hasUnreadNotifications => _unreadNotificationCount > 0;

  /// Called by AuthCheckScreen to set the initial login state.
  void initializeLoginStatus(bool loggedIn) {
    _isLoggedIn = loggedIn;
    if (_isLoggedIn) {
      // Generate a new key for the new session and fetch initial data.
      _sessionKey = UniqueKey();
      fetchAllCounts();
    }
  }

  /// The central logout method. This clears all user-specific state.
  void logout() {
    // Clear all user-specific state flags.
    _isLoggedIn = false;
    _hasUnreadBookings = false;
    _hasUnreadOffers = false;
    _hasUnreadPayments = false;
    _unreadNotificationCount = 0;

    // ✅ 2. Generate a new, different key to ensure the old MainScreen is destroyed.
    _sessionKey = UniqueKey();
    
    // Notify all listeners that the user has logged out.
    // This will trigger the navigation in AuthCheckScreen.
    notifyListeners();
  }

  /// Fetches all unread counts from the backend.
  Future<void> fetchAllCounts() async {
    try {
      final results = await Future.wait([
        _bookingService.getUnreadBookingCount(),
        _offerService.getUnreadOfferCount(),
        _paymentService.getUnreadPaymentCount(),
        _notificationService.getUnreadCount(),
      ]);

      _hasUnreadBookings = results[0] > 0;
      _hasUnreadOffers = results[1] > 0;
      _hasUnreadPayments = results[2] > 0;
      _unreadNotificationCount = results[3];

      notifyListeners();
    } catch (e) {
      print("Error fetching unread counts: $e");
    }
  }

  void updateCountsFromPush(Map<String, dynamic> counts) {
    _hasUnreadBookings = (counts['bookings'] ?? 0) > 0;
    _hasUnreadOffers = (counts['offers'] ?? 0) > 0;
    _hasUnreadPayments = (counts['payments'] ?? 0) > 0;
    _unreadNotificationCount = counts['notifications'] ?? 0;
    notifyListeners();
  }

  // --- Methods to Clear Badges (called from the UI) ---
  
  Future<void> clearUnreadBookings() async {
    if (_hasUnreadBookings) {
      _hasUnreadBookings = false;
      notifyListeners();
      await _bookingService.markBookingsAsSeen();
    }
  }

  Future<void> clearUnreadOffers() async {
    if (_hasUnreadOffers) {
      _hasUnreadOffers = false;
      notifyListeners();
      await _offerService.markOffersAsSeen();
    }
  }

  Future<void> clearUnreadPayments() async {
    if (_hasUnreadPayments) {
      _hasUnreadPayments = false;
      notifyListeners();
      await _paymentService.markPaymentsAsSeen();
    }
  }
  
  Future<void> clearUnreadNotifications() async {
    if (_unreadNotificationCount > 0) {
      _unreadNotificationCount = 0;
      notifyListeners();
      await _notificationService.markAllAsRead();
    }
  }

  void onNotificationReceived() {}
}