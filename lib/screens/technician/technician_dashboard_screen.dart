import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import '../../models/technician_model.dart';
import '../../models/booking_model.dart';
import '../auth/login_screen.dart'; 
import 'order_detail_screen.dart';

class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  int _selectedIndex = 0;
  Technician? _technicianData;
  bool _isLoadingProfile = true;
  
  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadTechnicianProfile();
  }
  
  Future<void> _loadTechnicianProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?.email ?? '';
    
    final result = await ApiService.getTechnicianByEmail(email);
    if (result['success'] == true) {
      setState(() {
        _technicianData = Technician.fromJson(result['technician']);
        _isLoadingProfile = false;
      });
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }
  
  Future<void> _loadBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    final technicianId = authProvider.currentUser?.email ?? '';
    print('📋 Loading bookings untuk teknisi: $technicianId');
    
    await bookingProvider.loadBookingsForTechnician(technicianId);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    final technicianId = authProvider.currentUser?.email ?? 'teknisi@demo.com';
    final technicianName = authProvider.currentUser?.name ?? 'Teknisi';
    
    final technicianBookings = bookingProvider.getTechnicianBookings(technicianId);
    
    final pendingBookings = technicianBookings.where((b) => b.status == BookingStatus.pending).toList();
    final confirmedBookings = technicianBookings.where((b) => b.status == BookingStatus.confirmed).toList();
    final ongoingBookings = technicianBookings.where((b) => b.status == BookingStatus.ongoing).toList();
    final completedBookings = technicianBookings.where((b) => b.status == BookingStatus.completed).toList();
    
    final screens = [
      _buildOrdersTab(pendingBookings, confirmedBookings, ongoingBookings, completedBookings),
      _buildEarningsScreen(technicianBookings),
      _buildTechnicianProfileScreen(authProvider, technicianName),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Teknisi'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBookings();
              _loadTechnicianProfile();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, authProvider),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Pendapatan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
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
  
  Widget _buildOrdersTab(
    List<Booking> pending,
    List<Booking> confirmed,
    List<Booking> ongoing,
    List<Booking> completed,
  ) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Menunggu'),
              Tab(text: 'Dikonfirmasi'),
              Tab(text: 'Dikerjakan'),
              Tab(text: 'Selesai'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrderList(pending),
                _buildOrderList(confirmed),
                _buildOrderList(ongoing),
                _buildOrderList(completed),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada order', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(booking.status),
              child: Icon(_getStatusIcon(booking.status), color: Colors.white),
            ),
            title: Text(
              booking.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${booking.serviceType}\n${_formatDate(booking.scheduledDate)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Rp ${booking.totalPrice}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(booking.status),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(booking: booking),
                ),
              );
            },
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
        text = 'Menunggu';
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        text = 'Dikonfirmasi';
        color = Colors.blue;
        break;
      case BookingStatus.ongoing:
        text = 'Dikerjakan';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }
  
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.confirmed: return Colors.blue;
      case BookingStatus.ongoing: return Colors.purple;
      case BookingStatus.completed: return Colors.green;
      case BookingStatus.cancelled: return Colors.red;
    }
  }
  
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return Icons.pending;
      case BookingStatus.confirmed: return Icons.check_circle;
      case BookingStatus.ongoing: return Icons.build;
      case BookingStatus.completed: return Icons.done_all;
      case BookingStatus.cancelled: return Icons.cancel;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildEarningsScreen(List<Booking> bookings) {
    final completedBookings = bookings.where((b) => b.status == BookingStatus.completed).toList();
    final totalEarnings = completedBookings.fold<int>(0, (sum, b) => sum + b.basePrice);
    final totalCommission = completedBookings.fold<int>(0, (sum, b) => (b.basePrice * 0.15).toInt());
    final netEarnings = totalEarnings - totalCommission;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Total Pendapatan Kotor', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_formatNumber(totalEarnings)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Divider(),
                    const Text('Komisi Platform (15%)', style: TextStyle(color: Colors.grey)),
                    Text('Rp ${_formatNumber(totalCommission)}', style: const TextStyle(color: Colors.red)),
                    const Divider(),
                    const Text('Pendapatan Bersih', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${_formatNumber(netEarnings)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Total Order Selesai', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${completedBookings.length}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
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
  
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
  
  // ==================== PROFIL SCREEN DENGAN FOTO ====================
  
  Widget _buildTechnicianProfileScreen(AuthProvider authProvider, String technicianName) {
    final user = authProvider.currentUser;
    
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Ambil photo_url dari database
    String photoUrl = _technicianData?.photoUrl ?? '';
    bool hasPhoto = photoUrl.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 🔥 FOTO PROFIL
          GestureDetector(
            onTap: () {
              if (hasPhoto) {
                _showFullImage(context, photoUrl);
              }
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade800, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: hasPhoto && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.orange.shade100,
                            child: Icon(Icons.handyman, size: 60, color: Colors.orange.shade800),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.orange.shade100,
                        child: Icon(Icons.handyman, size: 60, color: Colors.orange.shade800),
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nama Teknisi
          Text(
            _technicianData?.name ?? user?.name ?? technicianName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            user?.email ?? 'teknisi@demo.com',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${_technicianData?.rating ?? 0} (${_technicianData?.totalReviews ?? 0} review)'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info Toko Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileItem(Icons.store, 'Nama Toko', _technicianData?.shopName ?? '-'),
                  const Divider(),
                  _buildProfileItem(Icons.location_on, 'Alamat', _technicianData?.address ?? '-'),
                  const Divider(),
                  _buildProfileItem(Icons.phone, 'Telepon', _technicianData?.phone ?? '-'),
                  const Divider(),
                  _buildProfileItem(Icons.attach_money, 'Estimasi Harga', 'Rp ${_technicianData?.priceEstimate ?? 0}'),
                  const Divider(),
                  _buildProfileItem(Icons.build, 'Spesialisasi', _technicianData?.specialties.join(', ') ?? '-'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tombol Logout
          ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context, authProvider),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
  
  // Preview foto fullscreen
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.orange),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}