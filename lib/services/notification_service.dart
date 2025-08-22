import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

// --- Assumed Imports ---
import '../models/notification_model.dart'; 
import '../environment/env.dart';
import 'auth_service.dart';

class NotificationService {
  // ✅ FIX: Changed to the static getter pattern
  // 1. Private constructor
  NotificationService._internal();

  // 2. The single, static, public instance
  static final NotificationService instance = NotificationService._internal();

  // ❌ REMOVED: The factory constructor is no longer needed
  // factory NotificationService() => _instance;

  final String _baseUrl = AppConfig.ApibaseUrl; 
  final AuthService _authService = AuthService();

  // --- Real-time SignalR Hub Connection ---
  HubConnection? _hubConnection;
  
  final StreamController<NotificationModel> _notificationController = StreamController<NotificationModel>.broadcast();
  
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  /// Initializes and starts the connection to the SignalR hub.
  Future<void> connectToNotificationHub() async {
    final token = await _authService.getToken();
    
    if (token == null) {
      print("NotificationService: Authentication token not found. Cannot connect to hub.");
      return;
    }

    // ✅ FIX: Corrected the SignalR Hub URL to not include /api
    final hubUrl = _baseUrl.replaceAll("/api", ""); // Remove /api if it exists for SignalR
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '$hubUrl/notificationHub', // The URL of your SignalR hub
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token, // Provide the auth token
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Listen for the "ReceiveNotification" event from the server
    _hubConnection?.on('ReceiveNotification', (message) {
      if (message != null && message.isNotEmpty) {
        try {
          final data = message[0] as Map<String, dynamic>;
          final notification = NotificationModel.fromJson({
            'id': data['id'] ?? 0,
            'userId': data['userId'] ?? '',
            'title': data['title'],
            'message': data['message'],
            'description': data['description'],
            'createdAt': data['createdAt'],
            'isRead': data['isRead'],
            'type': data['type'] 
          });
          _notificationController.add(notification);
        } catch (e) {
          print("Error parsing received real-time notification: $e");
        }
      }
    });

    // Start the connection
    try {
      await _hubConnection?.start();
      print('Notification Hub connection established.');
    } catch (e) {
      print('Error starting Notification Hub connection: $e');
    }
  }

  /// Closes the SignalR hub connection and the stream controller.
  Future<void> disconnectFromNotificationHub() async {
    await _hubConnection?.stop();
    // Do not close the stream controller if the app might reconnect later.
    // Only close it if the user is permanently logging out.
    // _notificationController.close(); 
    print('Notification Hub connection closed.');
  }


  // --- REST API Methods ---

  /// Fetches a list of notifications for the authenticated user.
  Future<List<NotificationModel>> getNotifications({String? type}) async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    if (userId == null || token == null) throw Exception('User not authenticated.');
    
    // ✅ FIX: Removed hardcoded /api
    var uri = Uri.parse('$_baseUrl/Notifications/user/$userId');
    if (type != null) {
      uri = uri.replace(queryParameters: {'type': type});
    }

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => NotificationModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notifications. Status code: ${response.statusCode}');
    }
  }

  /// Fetches the count of unread notifications for the user.
  Future<int> getUnreadCount() async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    if (userId == null || token == null) throw Exception('User not authenticated.');

    final uri = Uri.parse('$_baseUrl/Notifications/user/$userId/unread-count');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unreadCount'];
    } else {
      throw Exception('Failed to get unread count. Status code: ${response.statusCode}');
    }
  }

  /// Marks a single notification as read by its ID.
  Future<void> markAsRead(int notificationId) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('$_baseUrl/Notifications/$notificationId/mark-read');
    
    final response = await http.put(uri, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read. Status code: ${response.statusCode}');
    }
  }

  /// Marks all unread notifications for the user as read.
  Future<void> markAllAsRead() async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    if (userId == null || token == null) throw Exception('User not authenticated.');

    final uri = Uri.parse('$_baseUrl/Notifications/mark-all-read/$userId');
    final response = await http.put(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all as read. Status code: ${response.statusCode}');
    }
  }
}
