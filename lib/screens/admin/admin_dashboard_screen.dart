import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'daftar_teknisi_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DaftarTeknisiScreen(),
    const KelolaCustomerScreen(),
    const LaporanScreen(),
  ];

  final List<String> _titles = [
    'Kelola Teknisi',
    'Kelola Customer',
    'Laporan',
  ];

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final adminName = user?.name ?? 'Admin';
    final displayName = adminName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'Admin: $displayName',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kelola Teknisi'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Kelola Customer'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}

// ==================== KELOLA CUSTOMER SCREEN ====================
class KelolaCustomerScreen extends StatefulWidget {
  const KelolaCustomerScreen({super.key});

  @override
  State<KelolaCustomerScreen> createState() => _KelolaCustomerScreenState();
}

class _KelolaCustomerScreenState extends State<KelolaCustomerScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _customers = [
          {'id': 1, 'name': 'Nisa Mahasiswa', 'email': 'nisa@example.com', 'phone': '08123456789', 'status': 'Aktif'},
          {'id': 2, 'name': 'Ahmad Pelajar', 'email': 'ahmad@example.com', 'phone': '081298765432', 'status': 'Aktif'},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(customer['name'][0], style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            ),
            title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['email']),
                Text(customer['phone']),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: customer['status'] == 'Aktif' ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                customer['status'],
                style: TextStyle(
                  fontSize: 12,
                  color: customer['status'] == 'Aktif' ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== LAPORAN SCREEN ====================
class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 20),
            const Text(
              'Laporan & Statistik',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Fitur laporan akan segera hadir', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatCard('Total Teknisi', '5', Colors.orange),
                    const SizedBox(height: 10),
                    _buildStatCard('Total Customer', '12', Colors.green),
                    const SizedBox(height: 10),
                    _buildStatCard('Total Booking', '48', Colors.blue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: color)),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}