import '../models/technician_model.dart';

List<Technician> getMockTechnicians() {
  return [
    Technician(
      id: 'tech_001',
      name: 'Pak Budi',
      phone: '081234567890',
      address: 'Jl. Ahmad Yani No. 12, Indramayu',
      locationArea: 'Indramayu Kota',
      rating: 4.8,
      totalReviews: 127,
      priceEstimate: 75000,
      photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      specialties: ['Laptop', 'PC', 'Hardware Repair'],
      isPremiumListing: true,
      isAvailable: true,
      shopName: 'Budi Computer Service',
    ),
    Technician(
      id: 'tech_002',
      name: 'Pak Ahmad',
      phone: '081298765432',
      address: 'Jl. Veteran No. 45, Indramayu',
      locationArea: 'Indramayu Kota',
      rating: 4.5,
      totalReviews: 89,
      priceEstimate: 60000,
      photoUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
      specialties: ['Software Installation', 'Virus Removal'],
      isPremiumListing: false,
      isAvailable: true,
      shopName: 'Ahmad Solution',
    ),
    Technician(
      id: 'tech_003',
      name: 'Pak Surya',
      phone: '081345678901',
      address: 'Jl. Raya Jatibarang No. 23, Jatibarang',
      locationArea: 'Jatibarang',
      rating: 4.9,
      totalReviews: 203,
      priceEstimate: 100000,
      photoUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
      specialties: ['Laptop Service', 'Data Recovery', 'Upgrade'],
      isPremiumListing: true,
      isAvailable: false,
      shopName: 'Surya Computer',
    ),
  ];
}

List<String> getLocationAreas() {
  return ['Semua Lokasi', 'Indramayu Kota', 'Jatibarang', 'Losarang', 'Anjatan'];
}

List<String> getServiceTypes() {
  return ['Diagnostic', 'Virus Removal', 'Hardware Repair', 'Software Installation', 'Data Recovery', 'Upgrade RAM/SSD'];
}