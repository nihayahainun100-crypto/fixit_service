import '../services/api_service.dart';

class Technician {
  int? id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String shopName;
  final String address;
  final String locationArea;
  final List<String> specialties;
  final int priceEstimate;
  final bool isPremiumListing;
  final bool isAvailable;
  final String photoUrl;
  double rating;
  int totalReviews;

  Technician({
    this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.shopName,
    required this.address,
    required this.locationArea,
    required this.specialties,
    required this.priceEstimate,
    this.isPremiumListing = false,
    this.isAvailable = true,
    this.photoUrl = '',
    this.rating = 0,
    this.totalReviews = 0,
  });

  static String _sanitizePhotoUrl(String url) {
    if (url.isEmpty) return '';
    final regex = RegExp(r'http://([^/]+)/');
    final match = regex.firstMatch(url);
    if (match != null) {
      final host = match.group(1);
      if (host != null && (host.contains('.') || host.contains(':'))) {
        return url.replaceFirst(host, ApiService.ipAddress);
      }
    }
    return url;
  }

  factory Technician.fromJson(Map<String, dynamic> json) {
    print('🔧 Parsing JSON: $json');
    
    return Technician(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '0',
      name: json['name'] ?? 'Tidak ada nama',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      shopName: json['shop_name'] ?? '',
      address: json['address'] ?? '',
      locationArea: json['location_area'] ?? '',
      specialties: json['specialties'] is List 
          ? List<String>.from(json['specialties']) 
          : (json['specialties'] is String 
              ? [json['specialties'] as String] 
              : []),
      priceEstimate: json['price_estimate'] ?? 0,
      isPremiumListing: json['is_premium'] ?? false,
      isAvailable: json['is_available'] ?? true,
      photoUrl: _sanitizePhotoUrl(json['photo_url'] ?? ''),
      rating: json['rating']?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
    );
  }
}