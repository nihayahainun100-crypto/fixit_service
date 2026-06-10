import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/technician_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];

  Timer? _pollingTimer;
  Set<String> _knownBookingIds = {};
  void Function(Booking)? _onNewBookingCallback;
  
  List<Booking> get bookings => _bookings;
  
  List<Booking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }
  
  List<Booking> getTechnicianBookings(String technicianId) {
    print(' Mencari booking untuk teknisi: $technicianId');
    final result = _bookings.where((b) => b.technicianId == technicianId).toList();
    print(' Ditemukan ${result.length} booking');
    for (var b in result) {
      print('   - ${b.customerName} - ${b.technicianId}');
    }
    return result;
  }

  
  String? _latestUpdateMessage;
  String? get latestUpdateMessage => _latestUpdateMessage;
  
  void clearLatestUpdateMessage() {
    _latestUpdateMessage = null;
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
    
    final String technicianId = technician.email;
    
    print('  Membuat booking baru:');
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
    
    await _saveBookingToServer(booking);
    
    SocketService().sendBookingNotification(
      technicianId: technician.email,
      bookingId: booking.id,
      customerName: customerName,
    );
    
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

  /// Mulai polling setiap [intervalSeconds] detik untuk teknisi.
  /// [onNewBooking] dipanggil setiap ada booking baru yang terdeteksi.
  void startPolling(
    String technicianId, {
    required void Function(Booking) onNewBooking,
    int intervalSeconds = 10,
  }) {
    stopPolling(); 
    _onNewBookingCallback = onNewBooking;

    _pollBookings(technicianId, isInitialLoad: true);

    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _pollBookings(technicianId),
    );
    print('⏱️ Polling dimulai setiap $intervalSeconds detik untuk: $technicianId');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _onNewBookingCallback = null;
    print(' Polling dihentikan');
  }

  Future<void> _pollBookings(String technicianId,
      {bool isInitialLoad = false}) async {
    final result = await ApiService.getBookingsForTechnician(technicianId);

    if (result['success'] != true || result['bookings'] == null) return;

    final List<dynamic> bookingsData = result['bookings'];
    final List<Booking> fetched =
        bookingsData.map((d) => Booking.fromMap(d)).toList();

    if (isInitialLoad) {
      _bookings = fetched;
      _knownBookingIds = fetched.map((b) => b.id).toSet();
      notifyListeners();
      print(' Initial load: ${fetched.length} booking diketahui');
      return;
    }

    final List<Booking> newBookings = fetched
        .where((b) => !_knownBookingIds.contains(b.id))
        .toList();

    if (newBookings.isNotEmpty) {
      _bookings = fetched;
      _knownBookingIds = fetched.map((b) => b.id).toSet();
      notifyListeners();
      print('🔔 ${newBookings.length} booking baru ditemukan!');
      for (final booking in newBookings) {
        _onNewBookingCallback?.call(booking);
      }
    }
  }


  Future<void> loadBookingsForTechnician(String technicianId) async {
    print(' Loading bookings untuk teknisi: $technicianId');
    final result = await ApiService.getBookingsForTechnician(technicianId);
    
    if (result['success'] == true && result['bookings'] != null) {
      final List<dynamic> bookingsData = result['bookings'];
      _bookings = bookingsData.map((data) => Booking.fromMap(data)).toList();
      notifyListeners();
      print('Loaded ${_bookings.length} bookings for $technicianId');
    } else {
      print(' Gagal load bookings: ${result['message']}');
    }
  }
  
  Future<void> loadBookingsForCustomer(String userId) async {
    print(' Loading bookings untuk customer: $userId');
    final result = await ApiService.getBookingsForCustomer(userId);
    
    if (result['success'] == true && result['bookings'] != null) {
      final List<dynamic> bookingsData = result['bookings'];
      _bookings = bookingsData.map((data) => Booking.fromMap(data)).toList();
      notifyListeners();
      print(' Loaded ${_bookings.length} bookings for customer $userId');
    } else {
      print(' Gagal load bookings customer: ${result['message']}');
    }
  }
  
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus, {String? notes}) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final oldStatus = _bookings[index].status;
      _bookings[index].status = newStatus;
      if (notes != null) {
        _bookings[index].technicianNotes = notes;
      }
      if (newStatus == BookingStatus.completed) {
        _bookings[index].completedDate = DateTime.now();
      }
      notifyListeners();
      
      await ApiService.updateBookingStatus({
        'booking_id': bookingId,
        'status': newStatus.toString().split('.').last,
        'notes': notes,
      });
      
      print(' Booking $bookingId status diubah dari $oldStatus menjadi $newStatus');
      
      // Kirim notifikasi Socket.IO
      SocketService().sendBookingUpdateNotification(
        bookingId: bookingId,
        userId: _bookings[index].userId,
        status: newStatus.toString().split('.').last,
        notes: notes,
      );
    } else {
      print(' Booking dengan ID $bookingId tidak ditemukan');
    }
  }

  // Update status secara lokal untuk customer (dipanggil saat terima socket event)
  void updateBookingStatusLocal(String bookingId, String statusStr, String? notes) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      BookingStatus newStatus;
      switch (statusStr) {
        case 'confirmed':
          newStatus = BookingStatus.confirmed;
          break;
        case 'ongoing':
          newStatus = BookingStatus.ongoing;
          break;
        case 'completed':
          newStatus = BookingStatus.completed;
          break;
        case 'cancelled':
          newStatus = BookingStatus.cancelled;
          break;
        default:
          newStatus = BookingStatus.pending;
      }
      
      _bookings[index].status = newStatus;
      if (notes != null && notes.isNotEmpty) {
        _bookings[index].technicianNotes = notes;
      }
      notifyListeners();
      print(' Local update: Booking $bookingId status updated to $statusStr');
    }
  }
  
  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Dikonfirmasi';
      case BookingStatus.ongoing:
        return 'Sedang Dikerjakan';
      case BookingStatus.completed:
        return 'Selesai';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
      case BookingStatus.pending:
        return 'Menunggu Konfirmasi';
      default:
        return 'Menunggu';
    }
  }
  
  Future<void> markAsRated(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].isRated = true;
      notifyListeners();
      await ApiService.markBookingAsRated(bookingId);
      print(' Booking $bookingId marked as rated');
    }
  }

}