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
  final String? startCode;
  final String? returnCode;
  final bool hasBeenReviewed;
  final String locationName;
  final double latitude;
  final double longitude;

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
    this.startCode,
    this.returnCode,
   required this.hasBeenReviewed,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

   factory BookingResponseDTO.fromJson(Map<String, dynamic> json) {
    return BookingResponseDTO(
      id: json['id'] ?? 0,
      itemName: json['itemName'] ?? 'Unknown Item',
      itemImage: json['itemImage'],
      ownerName: json['ownerName'] ?? 'Unknown Owner',
      renterName: json['renterName'] ?? 'Unknown Renter',
      ownerEmail: json['ownerEmail'] ?? '',
      renterEmail: json['renterEmail'] ?? '',
      ownerPhoneNumber: json['ownerPhoneNumber'],
      renterPhoneNumber: json['renterPhoneNumber'],
      ownerProfileImage: json['ownerProfileImage'],
      renterProfileImage: json['renterProfileImage'],
      ownerId: json['ownerId'] ?? '',
      renterId: json['renterId'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      isPaid: json['isPaid'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      startCode: json['startCode'],
      returnCode: json['returnCode'],
      hasBeenReviewed: json['hasBeenReviewed'] ?? false,
      locationName: json['locationName'] ?? 'No location provided',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}