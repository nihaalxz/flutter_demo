import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

// --- Assumed Imports ---
import '../models/notification_model.dart';
import '../environment/env.dart';
import 'auth_service.dart';

/// A model to represent the full real-time payload from the backend,
/// containing both the notification and the latest unread counts.
class UnreadUpdate {
  final NotificationModel notification;
  final Map<String, dynamic> unreadCounts;

  UnreadUpdate({required this.notification, required this.unreadCounts});
}

/// A service to handle fetching historical notifications and managing a
/// real-time SignalR connection for live updates.
class NotificationService {
  // --- Singleton Setup ---
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  // --- Dependencies & Configuration ---
  final String _baseUrl = AppConfig.ApibaseUrl;
  final AuthService _authService = AuthService();
  HubConnection? _hubConnection;

  // --- Real-time Update Stream ---
  // This stream broadcasts the full UnreadUpdate object to its listeners.
  final StreamController<UnreadUpdate> _updateController =
      StreamController<UnreadUpdate>.broadcast();
  Stream<UnreadUpdate> get unreadUpdateStream => _updateController.stream;

  get notificationStream => null;

  /// Establishes a connection to the real-time NotificationHub.
  Future<void> connectToNotificationHub() async {
    final token = await _authService.getToken();
    if (token == null) {
      debugPrint("NotificationService: Auth token not found. Cannot connect.");
      return;
    }

    final hubUrl = _baseUrl.replaceAll("/api", "");
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '$hubUrl/notificationHub',
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .withAutomaticReconnect()
        .build();

    // Listen for the new, smarter "ReceiveUnreadUpdate" event from the backend.
    _hubConnection?.on('ReceiveUnreadUpdate', (payload) {
      if (payload != null && payload.isNotEmpty) {
        try {
          final data = payload[0] as Map<String, dynamic>;
          
          final notificationData = data['notification'] as Map<String, dynamic>;
          final notification = NotificationModel.fromJson(notificationData);

          final counts = data['unreadCounts'] as Map<String, dynamic>;

          // Broadcast the full update object containing both the notification and the counts.
          _updateController.add(UnreadUpdate(notification: notification, unreadCounts: counts));

        } catch (e) {
          debugPrint("Error parsing unread update from SignalR: $e");
        }
      }
    });

    try {
      await _hubConnection?.start();
      debugPrint('Notification Hub connection established.');
    } catch (e) {
      debugPrint('Error starting Notification Hub connection: $e');
    }
  }

  /// Closes the SignalR hub connection.
  Future<void> disconnectFromNotificationHub() async {
    await _hubConnection?.stop();
    debugPrint('Notification Hub connection closed.');
  }

  // --- REST API Methods for Historical Data ---

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

   Future<void> markAsRead(int notificationId) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/Notifications/$notificationId/mark-read');
    final response = await http.put(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to mark notification as read. Status: ${response.statusCode}');
    }
  }

  /// Fetches a list of all notifications for the authenticated user.
  Future<List<NotificationModel>> getNotifications({String? type}) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not authenticated.');

    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/Notifications/user/$userId').replace(
      queryParameters: type != null ? {'type': type} : null,
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => NotificationModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notifications. Status: ${response.statusCode}');
    }
  }

  /// Fetches the count of unread notifications for the user.
  Future<int> getUnreadCount() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not authenticated.');
    
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/Notifications/user/$userId/unread-count');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unreadCount'] ?? 0;
    } else {
      debugPrint('Failed to get unread notification count.');
      return 0;
    }
  }

  /// Marks all unread notifications for the user as read.
  Future<void> markAllAsRead() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not authenticated.');

    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/Notifications/mark-all-read/$userId');
    final response = await http.put(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all as read. Status: ${response.statusCode}');
    }
  }
}

