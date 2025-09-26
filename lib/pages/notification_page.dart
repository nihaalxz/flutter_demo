import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

// --- Assumed Imports ---
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'bookings_page.dart';
import 'payments/payment_history_page.dart';

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

  StreamSubscription<UnreadUpdate>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _listenToRealtimeUpdates();
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  // --- Data Logic ---

  Future<void> _fetchNotifications() async {
    if (_notifications.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications
            ..clear()
            ..addAll(list);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Failed to load notifications. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToRealtimeUpdates() {
    _updateSubscription =
        _notificationService.unreadUpdateStream.listen((update) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, update.notification);
        });
      }
    });
  }

  Future<void> _handleNotificationTap(int index) async {
    final notification = _notifications[index];
    if (!notification.isRead) {
      await _markOneAsRead(index);
    }
    _navigateToDetails(notification);
  }

  Future<void> _markAllAsRead() async {
    final originalList = List<NotificationModel>.from(_notifications);
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });

    try {
      await _notificationService.markAllAsRead();
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications
            ..clear()
            ..addAll(originalList);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark all as read.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markOneAsRead(int index) async {
    final original = _notifications[index];
    if (original.isRead) return;

    setState(() {
      _notifications[index] = original.copyWith(isRead: true);
    });

    try {
      await _notificationService.markAsRead(original.id);
    } catch (_) {
      if (mounted) {
        setState(() => _notifications[index] = original);
      }
    }
  }

  // --- Navigation Logic ---

  int? _parseIdFromDescription(String? description, String key) {
    if (description == null || !description.contains(key)) return null;
    final pattern = RegExp('$key:(\\d+)');
    final match = pattern.firstMatch(description);
    if (match != null && match.group(1) != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void _navigateToDetails(NotificationModel notification) {
    final bookingId = _parseIdFromDescription(notification.description, "Booking Id");
    
    switch (notification.type) {
      case NotificationType.Transactional:
        if (bookingId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookingsPage()));
        }
        break;
      case NotificationType.Payments:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentHistoryPage()));
        break;
      default:
        break;
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }

  Widget _buildMaterialPage() {
    final hasUnread = _notifications.any((n) => !n.isRead);
    return Scaffold(
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
      body: _buildBody(),
    );
  }
  
  Widget _buildCupertinoPage() {
    final hasUnread = _notifications.any((n) => !n.isRead);
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Notifications'),
            trailing: hasUnread 
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Mark All Read'),
                  onPressed: _markAllAsRead,
                ) 
              : null,
          ),
          CupertinoSliverRefreshControl(
            onRefresh: _fetchNotifications,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildBody(isCupertino: true),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody({bool isCupertino = false}) {
    if (_isLoading) return _buildShimmerList();

    if (_errorMessage != null) {
      return _buildErrorState(isCupertino);
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState(isCupertino);
    }

    final listview = ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final n = _notifications[index];
        return InkWell(
          onTap: () => _handleNotificationTap(index),
          child: _buildNotificationCard(n, isCupertino: isCupertino),
        );
      },
    );

    return isCupertino ? listview : RefreshIndicator(onRefresh: _fetchNotifications, child: listview);
  }

  Widget _buildNotificationCard(NotificationModel n, {required bool isCupertino}) {
    final theme = Theme.of(context);
    final isUnread = !n.isRead;
    final isDark = theme.brightness == Brightness.dark;

    final cardContent = Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
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
              _iconForType(n.type, isCupertino: isCupertino),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stripHtml(n.message) ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.35),
                ),
                 const SizedBox(height: 4),
                 Text(
                  timeago.format(n.createdAt),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Icon(Icons.circle,
                  size: 10,
                  color: isCupertino ? CupertinoColors.activeBlue : theme.primaryColor),
            ),
        ],
      ),
    );

    if(isCupertino) {
      return Container(
        color: isUnread ? CupertinoColors.systemGroupedBackground : theme.scaffoldBackgroundColor,
        child: cardContent,
      );
    } else {
      return Card(
        elevation: isUnread ? 2 : 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isUnread ? const Color(0xFFE8F1FF) : Colors.white,
        child: cardContent,
      );
    }
  }

  // --- Other helper methods ---
   IconData _iconForType(NotificationType type, {required bool isCupertino}) {
    switch (type) {
      case NotificationType.Promotional:
        return isCupertino ? CupertinoIcons.speaker_2_fill : Icons.campaign;
      case NotificationType.Transactional:
        return isCupertino ? CupertinoIcons.arrow_2_circlepath : Icons.event_available;
      case NotificationType.Alert:
        return isCupertino ? CupertinoIcons.exclamationmark_triangle_fill : Icons.warning_amber_rounded;
      case NotificationType.Payments:
        return isCupertino ? CupertinoIcons.money_dollar_circle_fill : Icons.currency_rupee;
      case NotificationType.Message:
        return isCupertino ? CupertinoIcons.chat_bubble_2_fill : Icons.chat_bubble_outline;
      default:
        return isCupertino ? CupertinoIcons.bell_fill : Icons.notifications;
    }
  }

  String _stripHtml(String? input) {
    if (input == null) return '';
    return input.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListTile(
          leading: const CircleAvatar(radius: 20, backgroundColor: Colors.white),
          title: Container(height: 16, color: Colors.white),
          subtitle: Container(height: 14, width: 100, color: Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildErrorState(bool isCupertino) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage ?? 'An error occurred.'),
          const SizedBox(height: 16),
          isCupertino
              ? CupertinoButton.filled(onPressed: _fetchNotifications, child: const Text("Retry"))
              : ElevatedButton(onPressed: _fetchNotifications, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isCupertino) {
    final emptyView = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCupertino ? CupertinoIcons.bell_slash : Icons.notifications_off_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("You're all caught up!", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );

    return isCupertino
        ? CustomScrollView(slivers: [
            CupertinoSliverRefreshControl(onRefresh: _fetchNotifications),
            SliverFillRemaining(child: emptyView),
          ])
        : RefreshIndicator(
            onRefresh: _fetchNotifications,
            child: Stack(children: [ListView(), emptyView]),
          );
  }
}

extension on NotificationModel {
  NotificationModel copyWith({bool? isRead}) {
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

