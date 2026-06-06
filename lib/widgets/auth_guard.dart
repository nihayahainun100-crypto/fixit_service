import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

/// AuthGuard adalah widget penjaga rute.
///
/// Gunakan sebagai wrapper di sekeliling halaman yang membutuhkan login.
/// Jika user belum login, otomatis diarahkan ke [LoginScreen].
/// Jika sudah login, tampilkan [child].
///
/// Contoh penggunaan:
/// ```dart
/// MaterialPageRoute(
///   builder: (_) => AuthGuard(
///     requiredRole: 'technician',    // opsional
///     child: const TechnicianDashboardScreen(),
///   ),
/// )
/// ```
class AuthGuard extends StatelessWidget {
  /// Widget yang ditampilkan jika user sudah login (dan role sesuai).
  final Widget child;

  /// Role yang dibutuhkan untuk mengakses halaman ini.
  /// Kosongkan jika semua role bisa mengakses.
  final String? requiredRole;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // ── Belum login → redirect ke LoginScreen ──
        if (!auth.isLoggedIn) {
          // Gunakan SchedulerBinding agar tidak build di tengah frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          });

          // Tampilkan loading sementara menunggu navigasi
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ── Login tapi role tidak sesuai → tampilkan pesan unauthorized ──
        if (requiredRole != null &&
            auth.currentUser?.role != requiredRole) {
          return _UnauthorizedScreen(
            userRole: auth.currentUser?.role ?? '',
            requiredRole: requiredRole!,
          );
        }

        // ── Login dan role sesuai → tampilkan halaman ──
        return child;
      },
    );
  }
}

/// Widget yang ditampilkan jika user login tapi role tidak punya akses.
class _UnauthorizedScreen extends StatelessWidget {
  final String userRole;
  final String requiredRole;

  const _UnauthorizedScreen({
    required this.userRole,
    required this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 24),
              const Text(
                'Akses Ditolak',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Halaman ini hanya untuk role "$requiredRole".\n'
                'Akun Anda memiliki role "$userRole".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
