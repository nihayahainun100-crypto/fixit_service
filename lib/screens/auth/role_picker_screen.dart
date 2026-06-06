import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_home_screen.dart';
import '../technician/technician_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class RolePickerScreen extends StatelessWidget {
  final String email;
  final String name;
  final String googleId;

  const RolePickerScreen({
    super.key,
    required this.email,
    required this.name,
    required this.googleId,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Future<void> _selectRole(String role) async {
      final success = await authProvider.saveUserAfterGoogleLogin(
        id: googleId,
        name: name,
        email: email,
        role: role,
      );

      if (success && context.mounted) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else if (role == 'technician') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TechnicianDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        }
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Halo, $name!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih role Anda untuk melanjutkan',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 🔥 TOMBOL ADMIN
                          _buildRoleButton(
                            icon: Icons.admin_panel_settings,
                            title: 'Admin',
                            subtitle: 'Kelola Teknisi & Customer',
                            color: Colors.red,
                            onTap: () => _selectRole('admin'),
                          ),
                          const SizedBox(height: 16),
                          // 🔥 TOMBOL TEKNISI
                          _buildRoleButton(
                            icon: Icons.handyman,
                            title: 'Teknisi',
                            subtitle: 'Kelola Order Service',
                            color: Colors.orange,
                            onTap: () => _selectRole('technician'),
                          ),
                          const SizedBox(height: 16),
                          // 🔥 TOMBOL CUSTOMER
                          _buildRoleButton(
                            icon: Icons.person,
                            title: 'Customer',
                            subtitle: 'Cari & Booking Service',
                            color: Colors.green,
                            onTap: () => _selectRole('customer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}