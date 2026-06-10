import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../models/technician_model.dart';
import '../../widgets/announcement_banner.dart';
import 'technician_detail_screen.dart';
import 'my_bookings_screen.dart';
import '../auth/login_screen.dart';
import '../../providers/booking_provider.dart';
import '../../services/socket_service.dart';
import '../../services/notification_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  List<Technician> _teknisi = [];
  bool _isLoading = true;
  String _errorMessage = '';

  void _onBookingProviderChange() {
    if (!mounted) return;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    if (bookingProvider.latestUpdateMessage != null) {
      final msg = bookingProvider.latestUpdateMessage!;
      bookingProvider.clearLatestUpdateMessage();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade900,
          duration: const Duration(seconds: 7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  bool _wsInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadTeknisi();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _wsInitialized) return;
      _wsInitialized = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        final email = user.email;
        bookingProvider.loadBookingsForCustomer(email);
        SocketService().connect(
          onBookingUpdated: (data) async {
            print('🔔 Socket: Booking updated $data');
            
            if (data['user_id'] != email) return;
            
            final bookingId = data['booking_id'].toString();
            final statusStr = data['status'];
            final notes = data['notes'] ?? '';
            
            bookingProvider.updateBookingStatusLocal(bookingId, statusStr, notes);
            
            bookingProvider.loadBookingsForCustomer(email);
            
            if (mounted) {
              String statusStrIndonesian = 'Diperbarui';
              if (statusStr == 'confirmed') statusStrIndonesian = 'Dikonfirmasi';
              if (statusStr == 'ongoing') statusStrIndonesian = 'Sedang Dikerjakan';
              if (statusStr == 'completed') statusStrIndonesian = 'Selesai';
              if (statusStr == 'cancelled') statusStrIndonesian = 'Dibatalkan';
              
              final message = 'Status booking: $statusStrIndonesian' + 
                  (notes.isNotEmpty ? '\nCatatan: $notes' : '');
                  
              NotificationService().showNotification(
                title: 'Status Pesanan Diperbarui',
                body: message,
              );
                  
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.blue.shade800,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          onAnnouncementReceived: (data) {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            final message = data['message'] ?? '';
            appProvider.updateAnnouncement(message);
          },
        );
        bookingProvider.addListener(_onBookingProviderChange);
      }
    });
  }

  @override
  void dispose() {
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.removeListener(_onBookingProviderChange);
      SocketService().disconnect();
    } catch (e) {
      // ignore
    }
    super.dispose();
  }

  Future<void> _loadTeknisi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getAllTeknisi();
      print('📡 Customer load result: $result');
      
      if (result['success'] == true && result['teknisi'] != null) {
        final List data = result['teknisi'];
        print('📡 Jumlah teknisi dari server: ${data.length}');
        
        setState(() {
          _teknisi = data.map((json) => Technician.fromJson(json)).toList();
          _isLoading = false;
        });
        
        for (var t in _teknisi) {
          print(' Teknisi tampil: ${t.name}');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      print(' Load teknisi error: $e');
      setState(() {
        _errorMessage = 'Gagal koneksi ke server';
        _isLoading = false;
      });
    }
  }

  List<Technician> get _filteredTeknisi {
    return _teknisi.where((tech) => tech.isAvailable).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final screens = [
      _buildTechnicianList(),
      MyBookingsScreen(userId: user?.email ?? 'customer'),
      _buildProfileScreen(authProvider, user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FixIT Service'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTeknisi),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _showLogoutDialog(context, authProvider)),
        ],
      ),
      body: Column(
        children: [
          AnnouncementBanner(defaultColor: Colors.blue.shade700),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Booking Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildTechnicianList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTeknisi, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final filtered = _filteredTeknisi;

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada teknisi tersedia'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeknisi,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final tech = filtered[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: tech.isPremiumListing ? 4 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TechnicianDetailScreen(technician: tech),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                        image: tech.photoUrl != null && tech.photoUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(tech.photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: tech.photoUrl == null || tech.photoUrl!.isEmpty
                          ? Icon(Icons.handyman, size: 40, color: Colors.blue.shade900)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tech.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (tech.isPremiumListing) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (tech.shopName.isNotEmpty)
                            Text(tech.shopName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${tech.rating} (${tech.totalReviews} review)'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(tech.locationArea, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${tech.priceEstimate}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen(AuthProvider authProvider, dynamic user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Customer', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user?.email ?? 'customer@demo.com', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.blue),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? 'customer@demo.com'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.blue),
                      title: const Text('No. Telepon'),
                      subtitle: Text(user?.phone ?? '08123456789'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context, authProvider),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}