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
}