import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final Booking booking;
  
  const OrderDetailScreen({super.key, required this.booking});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _notesController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Order'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Nama: ${widget.booking.customerName}'),
                    Text('Telepon: ${widget.booking.customerPhone}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail Service', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Jenis Layanan: ${widget.booking.serviceType}'),
                    Text('Jadwal: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.booking.scheduledDate)}'),
                    Text('Catatan: ${widget.booking.notes.isEmpty ? '-' : widget.booking.notes}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga Service'),
                        Text('Rp ${widget.booking.basePrice}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biaya Layanan'),
                        Text('Rp ${widget.booking.serviceFee}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rp ${widget.booking.totalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.booking.status == BookingStatus.pending || 
                widget.booking.status == BookingStatus.confirmed ||
                widget.booking.status == BookingStatus.ongoing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan untuk pelanggan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (widget.booking.status == BookingStatus.pending)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  bookingProvider.updateBookingStatus(
                                    widget.booking.id,
                                    BookingStatus.confirmed,
                                    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Konfirmasi Order'),
                              ),
                            ),
                          if (widget.booking.status == BookingStatus.confirmed) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  bookingProvider.updateBookingStatus(
                                    widget.booking.id,
                                    BookingStatus.ongoing,
                                    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                child: const Text('Mulai Pengerjaan'),
                              ),
                            ),
                          ],
                          if (widget.booking.status == BookingStatus.ongoing) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  bookingProvider.updateBookingStatus(
                                    widget.booking.id,
                                    BookingStatus.completed,
                                    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Selesaikan Order'),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          if (widget.booking.status == BookingStatus.pending)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  bookingProvider.updateBookingStatus(
                                    widget.booking.id,
                                    BookingStatus.cancelled,
                                    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                                  );
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Tolak'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}