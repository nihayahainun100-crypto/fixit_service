import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/technician_model.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];

  List<Booking> get bookings => _bookings;
  
  List<Booking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }
  
  List<Booking> getTechnicianBookings(String technicianId) {
    return _bookings.where((b) => b.technicianId == technicianId).toList();
  }

  Future<void> createBooking({
    required String userId,
    required Technician technician,
    required String serviceType,
    required int basePrice,
    required DateTime scheduledDate,
    required String customerName,
    required String customerPhone,
    required String notes,
  }) async {
    const double serviceFeePercentage = 0.05; // 5% service fee dari user
    int serviceFee = (basePrice * serviceFeePercentage).toInt();
    int totalPrice = basePrice + serviceFee;
    
    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      technicianId: technician.id,
      technicianName: technician.name,
      serviceType: serviceType,
      basePrice: basePrice,
      serviceFee: serviceFee,
      totalPrice: totalPrice,
      scheduledDate: scheduledDate,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
      status: BookingStatus.pending,
      isRated: false,
    );
    
    _bookings.add(booking);
    notifyListeners();
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus, {String? notes}) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = newStatus;
      if (notes != null) {
        _bookings[index].technicianNotes = notes;
      }
      if (newStatus == BookingStatus.completed) {
        _bookings[index].completedDate = DateTime.now();
      }
      notifyListeners();
    }
  }

  Future<void> markAsRated(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].isRated = true;
      notifyListeners();
    }
  }
}