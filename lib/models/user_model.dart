class AppUser {
  final String id;
  final String name;
  final String email;
  final String? pictureUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.pictureUrl,
  });

  factory AppUser.fromToken(Map<String, dynamic> decodedToken) {
    return AppUser(
      // The key names here now match your backend's JWT claims
      id: decodedToken['nameid'],
      name: decodedToken['unique_name'],
      email: decodedToken['email'],
      pictureUrl: decodedToken['picture'],
    );
  }
}
