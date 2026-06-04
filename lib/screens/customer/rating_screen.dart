import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';

class RatingScreen extends StatefulWidget {
  final Booking booking;
  
  const RatingScreen({super.key, required this.booking});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 5;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beri Rating & Review'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              widget.booking.technicianName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Layanan: ${widget.booking.serviceType}'),
            const SizedBox(height: 30),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Tulis review Anda',
                border: OutlineInputBorder(),
                hintText: 'Bagaimana pengalaman Anda?',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await reviewProvider.addReview(
                    bookingId: widget.booking.id,
                    technicianId: widget.booking.technicianId,
                    userId: user?.email ?? 'user',
                    userName: user?.name ?? 'Customer',
                    rating: _rating,
                    comment: _commentController.text.isEmpty ? 'Bagus!' : _commentController.text,
                  );
                  await bookingProvider.markAsRated(widget.booking.id);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terima kasih atas review Anda!')),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kirim Review', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}