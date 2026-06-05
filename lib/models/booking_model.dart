enum BookingStatus {
  pending,
  confirmed,
  ongoing,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String userId;
  final String technicianId;
  final String technicianName;
  final String serviceType;
  final int basePrice;
  final int serviceFee;
  final int totalPrice;
  final DateTime scheduledDate;
  final String customerName;
  final String customerPhone;
  final String notes;
  BookingStatus status;
  String? technicianNotes;
  DateTime? completedDate;
  bool isRated;

  Booking({
    required this.id,
    required this.userId,
    required this.technicianId,
    required this.technicianName,
    required this.serviceType,
    required this.basePrice,
    required this.serviceFee,
    required this.totalPrice,
    required this.scheduledDate,
    required this.customerName,
    required this.customerPhone,
    required this.notes,
    required this.status,
    this.technicianNotes,
    this.completedDate,
    this.isRated = false,
  });

  // 🔥 TAMBAHKAN METHOD fromMap
  factory Booking.fromMap(Map<String, dynamic> map) {
    // Konversi string status ke enum BookingStatus
    BookingStatus statusEnum;
    switch (map['status']) {
      case 'confirmed':
        statusEnum = BookingStatus.confirmed;
        break;
      case 'ongoing':
        statusEnum = BookingStatus.ongoing;
        break;
      case 'completed':
        statusEnum = BookingStatus.completed;
        break;
      case 'cancelled':
        statusEnum = BookingStatus.cancelled;
        break;
      default:
        statusEnum = BookingStatus.pending;
    }
    
    return Booking(
      id: map['booking_id'] ?? map['id'],
      userId: map['user_id'] ?? '',
      technicianId: map['technician_id'] ?? '',
      technicianName: map['technician_name'] ?? '',
      serviceType: map['service_type'] ?? '',
      basePrice: map['base_price'] ?? 0,
      serviceFee: map['service_fee'] ?? 0,
      totalPrice: map['total_price'] ?? 0,
      scheduledDate: DateTime.parse(map['scheduled_date'] ?? DateTime.now().toIso8601String()),
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      notes: map['notes'] ?? '',
      status: statusEnum,
      technicianNotes: map['technician_notes'],
      isRated: map['is_rated'] == 1 || map['is_rated'] == true,
    );
  }
  
  // 🔥 TAMBAHKAN METHOD toMap (untuk kirim ke server)
  Map<String, dynamic> toMap() {
    return {
      'booking_id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'technician_name': technicianName,
      'service_type': serviceType,
      'base_price': basePrice,
      'service_fee': serviceFee,
      'total_price': totalPrice,
      'scheduled_date': scheduledDate.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'notes': notes,
      'status': status.toString().split('.').last,
      'is_rated': isRated ? 1 : 0,
      'technician_notes': technicianNotes,
    };
  }
}