// A Dart enum to represent the different notification types from the backend.
enum NotificationType {
  Promotional,
  Alert,
  Message,
  Transactional,
  Payments,
  // Add other types as needed
  Unknown // A fallback for any unrecognized types
}

class NotificationModel {
  final int id;
  final String userId;
  final String title;
  final String? description;
  final String? message;
  final bool isRead;
  final NotificationType type;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.message,
    required this.isRead,
    required this.type,
    required this.createdAt,
  });

  /// Factory constructor to create a NotificationModel instance from a JSON map.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      message: json['message'],
      isRead: json['isRead'],
      type: _parseNotificationType(json['type']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// Helper function to safely parse the notification type string from JSON.
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.Unknown;
    // Match the string value from the API to the enum member.
    switch (typeString.toLowerCase()) {
      case 'promotional':
        return NotificationType.Promotional;
      case 'alert':
        return NotificationType.Alert;
      case 'message':
        return NotificationType.Message;
      case 'transactional':
        return NotificationType.Transactional;
      case 'payments':
        return NotificationType.Payments;
      // Add other cases as needed
      default:
        return NotificationType.Unknown;
    }
  }
}