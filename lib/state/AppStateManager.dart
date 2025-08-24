// ignore: file_names
import 'package:flutter/foundation.dart';
import 'package:myfirstflutterapp/services/notification_service.dart';

/// A global state manager for app-wide data like notification counts.
/// It uses the ChangeNotifier pattern to notify widgets of updates.
class AppStateManager with ChangeNotifier {
  final NotificationService _notificationService = NotificationService.instance;

  int _unreadNotificationCount = 0;
  final int _pendingBookingCount = 0;

  int get unreadNotificationCount => _unreadNotificationCount;
  int get pendingBookingCount => _pendingBookingCount;

  AppStateManager() {
    // When the app starts, listen for incoming real-time notifications
    _notificationService.notificationStream.listen((_) {
      // When a new notification arrives, increment the count and refresh from server
      // to ensure the data is perfectly in sync.
      fetchNotificationCount();
    });
  }

  /// Fetches the latest unread notification count from the server.
  Future<void> fetchNotificationCount() async {
    try {
      _unreadNotificationCount = await _notificationService.getUnreadCount();
      notifyListeners(); // This tells the UI to update
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching notification count: $e");
      }
    }
  }

  /// Fetches the latest pending booking count from the server.
  Future<void> fetchPendingBookingCount() async {
    try {
      // NOTE: You will need to create this method in your BookingService
      // and a corresponding endpoint in your backend.
      // _pendingBookingCount = await _bookingService.getPendingBookingCount();
      notifyListeners(); // This tells the UI to update
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching pending booking count: $e");
      }
    }
  }
}
