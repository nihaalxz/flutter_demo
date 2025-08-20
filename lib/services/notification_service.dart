import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

// --- Assumed Imports ---
// You will need to replace these with your actual files for configuration and authentication.
import '../models/notification_model.dart'; 
import '../environment/env.dart'; // A file containing your base API URL, e.g., final String baseUrl = "https://yourapi.com";
import 'auth_service.dart'; // A service to get the current user's ID and JWT token.

class NotificationService {
  final String _baseUrl = AppConfig.ApibaseUrl; 
  final AuthService _authService = AuthService(); // Your auth service instance.

  // --- Real-time SignalR Hub Connection ---

  HubConnection? _hubConnection;
  
  // A StreamController to broadcast incoming real-time notifications to the app UI.
  final StreamController<NotificationModel> _notificationController = StreamController<NotificationModel>.broadcast();
  
  // Expose the stream for UI widgets to listen to.
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  /// Initializes and starts the connection to the SignalR hub.
  Future<void> connectToNotificationHub() async {
    final token = await _authService.getToken();
    if (token == null) {
      print("NotificationService: Authentication token not found. Cannot connect to hub.");
      return;
    }

    // Configure the hub connection
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '$_baseUrl/notificationHub', // The URL of your SignalR hub
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
          // Manually construct a NotificationModel from the SignalR payload
          // The payload from the C# code might be slightly different than the REST API response
          final notification = NotificationModel.fromJson({
            'id': data['id'] ?? 0, // ID might not be sent in real-time push, handle gracefully
            'userId': data['userId'] ?? '',
            'title': data['title'],
            'message': data['message'],
            'description': data['description'],
            'createdAt': data['createdAt'],
            'isRead': data['isRead'],
            'type': data['type'] 
          });
          _notificationController.add(notification); // Add the new notification to the stream
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
    _notificationController.close();
    print('Notification Hub connection closed.');
  }


  // --- REST API Methods ---

  /// Fetches a list of notifications for the authenticated user.
  /// Corresponds to: [GET api/Notifications/user/{userId}]
  Future<List<NotificationModel>> getNotifications({String? type}) async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    if (userId == null || token == null) throw Exception('User not authenticated.');
    
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
  /// Corresponds to: [GET api/Notifications/user/{userId}/unread-count]
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
  /// Corresponds to: [PUT api/Notifications/{id}/mark-read]
  Future<void> markAsRead(int notificationId) async {
    // Note: The provided C# endpoint is not decorated with [Authorize].
    // It's a good practice to send the token anyway in case the backend changes.
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
  /// Corresponds to: [PUT api/Notifications/mark-all-read/{userId}]
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