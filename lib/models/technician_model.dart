class Technician {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String locationArea; // Indramayu, Jatibarang, etc.
  final double rating;
  final int totalReviews;
  final int priceEstimate; // harga estimasi per service
  final String photoUrl;
  final List<String> specialties;
  final bool isPremiumListing;
  final bool isAvailable;
  final String shopName;

  Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.locationArea,
    required this.rating,
    required this.totalReviews,
    required this.priceEstimate,
    required this.photoUrl,
    required this.specialties,
    this.isPremiumListing = false,
    this.isAvailable = true,
    required this.shopName,
  });

  factory Technician.fromMap(Map<String, dynamic> map) {
    return Technician(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      locationArea: map['locationArea'],
      rating: map['rating'],
      totalReviews: map['totalReviews'],
      priceEstimate: map['priceEstimate'],
      photoUrl: map['photoUrl'],
      specialties: List<String>.from(map['specialties']),
      isPremiumListing: map['isPremiumListing'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      shopName: map['shopName'],
    );
  }
}