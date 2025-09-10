class Participant {
  final String id;
  final String fullName;
  final String? profilePictureUrl;

  Participant({
    required this.id,
    required this.fullName,
    this.profilePictureUrl,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      fullName: json['fullName'],
      profilePictureUrl: json['profilePictureUrl'],
    );
  }
}

/// Represents a single chat conversation thread.
class Conversation {
  final int id;
  final DateTime lastMessageAt;
  final Participant otherParticipant;

  Conversation({
    required this.id,
    required this.lastMessageAt,
    required this.otherParticipant,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      otherParticipant: Participant.fromJson(json['otherParticipant']),
    );
  }
}