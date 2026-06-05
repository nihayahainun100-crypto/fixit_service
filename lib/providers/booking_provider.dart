import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/technician_model.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];

  List<Booking> get bookings => _bookings;
  
  List<Booking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }
  
  List<Booking> getTechnicianBookings(String technicianId) {
    print('🔍 Mencari booking untuk teknisi: $technicianId');
    final result = _bookings.where((b) => b.technicianId == technicianId).toList();
    print('📋 Ditemukan ${result.length} booking');
    for (var b in result) {
      print('   - ${b.customerName} - ${b.technicianId}');
    }
    return result;
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
    const double serviceFeePercentage = 0.05;
    int serviceFee = (basePrice * serviceFeePercentage).toInt();
    int totalPrice = basePrice + serviceFee;
    
    // 🔥 PAKAI EMAIL TEKNISI, BUKAN ID
    final String technicianId = technician.email;
    
    print('📝 Membuat booking baru:');
    print('  Technician ID (email): $technicianId');
    print('  Technician Name: ${technician.name}');
    print('  Customer: $customerName');
    
    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      technicianId: technicianId,
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
    
    // Simpan ke database
    await _saveBookingToServer(booking);
    print(' Booking berhasil dibuat dengan ID: ${booking.id}');
  }
  
  Future<void> _saveBookingToServer(Booking booking) async {
    final data = {
      'booking_id': booking.id,
      'user_id': booking.userId,
      'technician_id': booking.technicianId,
      'technician_name': booking.technicianName,
      'service_type': booking.serviceType,
      'base_price': booking.basePrice,
      'service_fee': booking.serviceFee,
      'total_price': booking.totalPrice,
      'scheduled_date': booking.scheduledDate.toIso8601String(),
      'customer_name': booking.customerName,
      'customer_phone': booking.customerPhone,
      'notes': booking.notes,
      'status': 'pending',
    };
    
    print(' Sending booking data: $data');
    final result = await ApiService.saveBooking(data);
    print(' Save booking result: $result');
  }
  
  // Load booking dari server untuk teknisi
  Future<void> loadBookingsForTechnician(String technicianId) async {
    print(' Loading bookings untuk teknisi: $technicianId');
    final result = await ApiService.getBookingsForTechnician(technicianId);
    
    if (result['success'] == true && result['bookings'] != null) {
      final List<dynamic> bookingsData = result['bookings'];
      _bookings = bookingsData.map((data) => Booking.fromMap(data)).toList();
      notifyListeners();
      print(' Loaded ${_bookings.length} bookings for $technicianId');
    } else {
      print(' Gagal load bookings: ${result['message']}');
    }
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
      
      // Update status di database
      await ApiService.updateBookingStatus({
        'booking_id': bookingId,
        'status': newStatus.toString().split('.').last,
        'notes': notes,
      });
    }
  }

  Future<void> markAsRated(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].isRated = true;
      notifyListeners();
      await ApiService.markBookingAsRated(bookingId);
    }
  }
}