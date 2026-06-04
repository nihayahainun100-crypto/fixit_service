import 'package:flutter/material.dart';
import '../../models/technician_model.dart';
import 'booking_screen.dart';

class TechnicianDetailScreen extends StatelessWidget {
  final Technician technician;
  
  const TechnicianDetailScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(technician.name),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.blue.shade100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(technician.photoUrl),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      technician.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(technician.shopName, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Info Toko',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Nama Toko'),
                    subtitle: Text(technician.shopName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Alamat'),
                    subtitle: Text(technician.address),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Telepon'),
                    subtitle: Text(technician.phone),
                  ),
                  const Divider(),
                  const Text(
                    'Rating & Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        '${technician.rating}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text('(${technician.totalReviews} review)', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Layanan & Estimasi Harga',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: technician.specialties.map((spec) {
                      return Chip(label: Text(spec));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimasi Harga Service', style: TextStyle(fontSize: 16)),
                        Text(
                          'Rp ${technician.priceEstimate}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: technician.isAvailable
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(technician: technician),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Booking Sekarang',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}