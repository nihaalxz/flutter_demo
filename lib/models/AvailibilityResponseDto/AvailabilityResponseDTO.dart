class AvailabilityResponseDTO {
  final bool isAvailable;
  final int itemId;
  final DateTime startDate;
  final DateTime endDate;
  final List<dynamic> conflictingBookings;
  final String message;

  AvailabilityResponseDTO({
    required this.isAvailable,
    required this.itemId,
    required this.startDate,
    required this.endDate,
    required this.conflictingBookings,
    required this.message,
  });

  factory AvailabilityResponseDTO.fromJson(Map<String, dynamic> json) {
    return AvailabilityResponseDTO(
      isAvailable: json['isAvailable'],
      itemId: json['itemId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      conflictingBookings: json['conflictingBookings'] ?? [],
      message: json['message'],
    );
  }
}