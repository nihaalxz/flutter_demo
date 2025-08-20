class BookingResponseDTO {
  final int id;
  final String status;
  final String itemName;
  final String? itemImage; // 👈 FIX: Item image can be null
  final String ownerName;
  final String renterName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final bool isPaid;
  final String? ownerProfileImage; // 👈 FIX: Owner profile image can be null
  final String? renterProfileImage; // 👈 FIX: Renter profile image can be null
  final DateTime createdAt;
  final String ownerId;
  final String renterId;
  final String ownerEmail;
  final String renterEmail;
  final String? ownerPhoneNumber; // 👈 FIX: Phone number can be null
  final String? renterPhoneNumber; // 👈 FIX: Phone number can be null

  BookingResponseDTO({
    required this.id,
    required this.status,
    required this.itemName,
    this.itemImage, // 👈 No 'required' needed
    required this.ownerName,
    required this.renterName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.isPaid,
    this.ownerProfileImage, // 👈 No 'required' needed
    this.renterProfileImage, // 👈 No 'required' needed
    required this.createdAt,
    required this.ownerId,
    required this.renterId,
    required this.ownerEmail,
    required this.renterEmail,
    this.ownerPhoneNumber, // 👈 No 'required' needed
    this.renterPhoneNumber, // 👈 No 'required' needed
  });

  factory BookingResponseDTO.fromJson(Map<String, dynamic> json) {
    return BookingResponseDTO(
      id: json['id'],
      status: json['status'],
      itemName: json['itemName'],
      itemImage: json['itemImage'], // ✅ This now correctly handles null
      ownerName: json['ownerName'],
      renterName: json['renterName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      isPaid: json['isPaid'],
      ownerProfileImage: json['ownerProfileImage'], // ✅ This now correctly handles null
      renterProfileImage: json['renterProfileImage'], // ✅ This now correctly handles null
      createdAt: DateTime.parse(json['createdAt']),
      ownerId: json['ownerId'],
      renterId: json['renterId'],
      ownerEmail: json['ownerEmail'],
      renterEmail: json['renterEmail'],
      ownerPhoneNumber: json['ownerPhoneNumber'], // ✅ This now correctly handles null
      renterPhoneNumber: json['renterPhoneNumber'], // ✅ This now correctly handles null
    );
  }
}