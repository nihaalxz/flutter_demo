import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService.instance;

  final List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<NotificationModel>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _listenToRealtimeNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // ------------------------------
  // Data
  // ------------------------------
  Future<void> _fetchNotifications() async {
    if (_notifications.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _notificationService.getNotifications();
      setState(() {
        _notifications
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load notifications. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToRealtimeNotifications() {
    _notificationSubscription =
        _notificationService.notificationStream.listen((notification) {
      // Ensure newest on top
      setState(() {
        _notifications.insert(0, notification);
      });

      // Optional toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New: ${notification.title}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Future<void> _markAllAsRead() async {
    try {
      // Optimistic UI
      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          final n = _notifications[i];
          _notifications[i] = n.copyWith(isRead: true);
        }
      });

      await _notificationService.markAllAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark all as read.'),
          backgroundColor: Colors.red,
        ),
      );
      _fetchNotifications();
    }
  }

  Future<void> _markOneAsRead(int index) async {
    final orig = _notifications[index];
    if (orig.isRead) return;

    // Optimistic UI
    setState(() {
      _notifications[index] = orig.copyWith(isRead: true);
    });

    try {
      await _notificationService.markAsRead(orig.id);
    } catch (_) {
      // Revert on failure
      setState(() => _notifications[index] = orig);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update notification.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------------------
  // UI Helpers
  // ------------------------------
  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.Promotional:
        return Icons.campaign;
      case NotificationType.Transactional:
        return Icons.event_available;
      case NotificationType.Alert:
        return Icons.warning_amber_rounded;
      case NotificationType.Payments:
        return Icons.currency_rupee;
      case NotificationType.Message:
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }

  String _stripHtml(String? input) {
    if (input == null) return '';
    final noTags = input.replaceAll(RegExp(r'<[^>]*>'), '');
    return noTags.replaceAll('&nbsp;', ' ').trim();
  }

  // ------------------------------
  // Build
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return _buildShimmerList();

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _fetchNotifications,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(
            child: Text(
              "🎉 You're all caught up!\nNo new notifications.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final n = _notifications[index];
        final isUnread = !n.isRead;

        return InkWell(
          onTap: () => _markOneAsRead(index),
          child: Card(
            elevation: isUnread ? 2 : 0,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isUnread
                    ? (isDark ? Colors.blueGrey.shade900 : const Color(0xFFE8F1FF))
                    : (isDark ? Colors.grey.shade900 : Colors.white),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon + title + time + unread dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isUnread
                              ? (isDark ? Colors.blueGrey.shade800 : const Color(0xFFDBE7FF))
                              : (isDark ? Colors.grey.shade800 : const Color(0xFFF0F2F5)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForType(n.type),
                          size: 22,
                          color: isDark ? Colors.lightBlueAccent : const Color(0xFF2D5BFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeago.format(n.createdAt),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle,
                              size: 10,
                              color: isDark ? Colors.lightBlueAccent : const Color(0xFF2D5BFF)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Message
                  if ((_stripHtml(n.message)).isNotEmpty)
                    Text(
                      _stripHtml(n.message),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: isDark ? Colors.grey.shade200 : const Color(0xFF111827),
                      ),
                    ),

                  // Description
                  if ((n.description ?? '').isNotEmpty) ...[
                    if ((_stripHtml(n.message)).isNotEmpty) const SizedBox(height: 8),
                    Text(
                      n.description!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------
  // Shimmer skeleton
  // ------------------------------
  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color.fromARGB(125, 255, 255, 255),
          highlightColor: const Color.fromARGB(255, 214, 214, 214),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 14, width: 180, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(height: 12, width: 90, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 12, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 220, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on NotificationModel {
  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      description: description,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }
}
