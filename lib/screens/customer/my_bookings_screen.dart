import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import 'rating_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  final String userId;

  const MyBookingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    final userBookings = bookingProvider.getUserBookings(userId);

    if (userBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_online, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada booking', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: userBookings.length,
      itemBuilder: (context, index) {
        final booking = userBookings[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.technicianName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(booking.status),
                  ],
                ),

                const SizedBox(height: 8),

                Text('Layanan: ${booking.serviceType}'),
                Text(
                  'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(booking.scheduledDate)}',
                ),
                Text('Total: Rp ${booking.totalPrice}'),

                if (booking.technicianNotes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Catatan Teknisi: ${booking.technicianNotes}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.status == BookingStatus.completed &&
                        !booking.isRated)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatingScreen(booking: booking),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star),
                        label: const Text('Beri Rating'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                      ),

                    if (booking.status == BookingStatus.pending)
                      TextButton(
                        onPressed: () {
                          _cancelBooking(context, booking, bookingProvider);
                        },
                        child: const Text(
                          'Batalkan',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    String text;
    Color color;

    switch (status) {
      case BookingStatus.pending:
        text = 'Menunggu Konfirmasi';
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        text = 'Dikonfirmasi';
        color = Colors.blue;
        break;
      case BookingStatus.ongoing:
        text = 'Sedang Dikerjakan';
        color = Colors.purple;
        break;
      case BookingStatus.completed:
        text = 'Selesai';
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
        text = 'Dibatalkan';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  void _cancelBooking(
    BuildContext context,
    Booking booking,
    BookingProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: const Text('Apakah Anda yakin ingin membatalkan booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              provider.updateBookingStatus(
                booking.id,
                BookingStatus.cancelled,
              );

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking dibatalkan')),
              );
            },
            child: const Text(
              'Ya',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}