import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Instantiate the service to use its methods.
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Subscription to listen for real-time notifications from the service stream.
  StreamSubscription<NotificationModel>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Fetch initial data when the widget is first created.
    _fetchNotifications();
    // Start listening for real-time updates.
    _listenToRealtimeNotifications();
  }

  @override
  void dispose() {
    // IMPORTANT: Cancel the stream subscription to prevent memory leaks.
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Fetches notifications from the API and updates the UI state.
  Future<void> _fetchNotifications() async {
    // Set loading state only if it's the initial load.
    if (_notifications.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load notifications. Please try again.";
      });
      print(e); // For debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Subscribes to the notification stream from the service.
  void _listenToRealtimeNotifications() {
    _notificationSubscription = _notificationService.notificationStream.listen((notification) {
      // When a new notification arrives, add it to the top of the list.
      setState(() {
        _notifications.insert(0, notification);
      });
      // Optionally, show a snackbar or some other UI feedback.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New notification: ${notification.title}"),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  /// Marks all notifications as read and refreshes the list.
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      // Optimistically update the UI for a faster user experience.
      setState(() {
        // ignore: unused_local_variable
        for (var n in _notifications) {
          // This requires the 'isRead' property in NotificationModel to be mutable.
          // If it's final, you'd need to recreate the list with updated items.
          // For simplicity, let's assume it's mutable or we refetch.
        }
      });
      // Refresh the list from the server to ensure consistency.
      await _fetchNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All notifications marked as read.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not mark all as read."), backgroundColor: Colors.red),
      );
    }
  }

  /// Helper to return an icon based on notification type.
  Icon _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.Promotional:
        return const Icon(Icons.campaign, color: Colors.blue);
      case NotificationType.Alert:
        return const Icon(Icons.warning, color: Colors.orange);
      case NotificationType.Message:
        return const Icon(Icons.message, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          // Show the "Mark all as read" button only if there are unread notifications.
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: "Mark all as read",
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _buildBody(),
      ),
    );
  }

  /// Builds the main body content based on the current state.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNotifications,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          "You have no notifications.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final bool isUnread = !notification.isRead;
        
        return InkWell(
          onTap: () async {
            if (isUnread) {
              try {
                // Optimistically update UI
                setState(() {
                  // To update a final property, replace the object in the list
                  _notifications[index] = NotificationModel(
                      id: notification.id,
                      userId: notification.userId,
                      title: notification.title,
                      description: notification.description,
                      message: notification.message,
                      isRead: true, // Mark as read
                      type: notification.type,
                      createdAt: notification.createdAt);
                });
                await _notificationService.markAsRead(notification.id);
              } catch (e) {
                // If API call fails, revert the change and show an error
                setState(() {
                   _notifications[index] = notification; // Revert to original
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update notification."), backgroundColor: Colors.red),
                );
              }
            }
          },
          child: Container(
            color: isUnread ? Colors.blue.withOpacity(0.05) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListTile(
              leading: _getNotificationIcon(notification.type),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                "${notification.description ?? notification.message ?? ''}\n${timeago.format(notification.createdAt)}",
              ),
              trailing: isUnread
                  ? const Icon(Icons.circle, color: Colors.blue, size: 12)
                  : null,
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
}