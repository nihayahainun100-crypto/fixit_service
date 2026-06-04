import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_home_screen.dart';
import '../technician/technician_dashboard_screen.dart';
import 'register_screen.dart';
import 'role_picker_screen.dart'; // Import ini

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user != null && user.role == 'technician') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TechnicianDashboardScreen()),
          );
        } else if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau password salah!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    setState(() => _isLoading = true);

    final result = await authProvider.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (result != null && mounted) {
      if (result['success'] == true) {
        if (result['isNewUser'] == true) {
          // USER BARU, TAMPILKAN ROLE PICKER
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RolePickerScreen(
                email: result['email'],
                name: result['name'],
                googleId: result['id'],
              ),
            ),
          );
        } else {
          // USER LAMA, LANGSUNG KE DASHBOARD
          final user = result['user'];
          if (user != null && user.role == 'technician') {
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal login dengan Google'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.computer,
                        size: 60,
                        color: Color(0xFF1A237E),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'FixIT Service',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login untuk melanjutkan',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan email';
                          }
                          if (!value.contains('@')) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Login Button
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _handleLogin(authProvider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1A237E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Divider
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('atau'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Google Sign-In Button
                      if (!_isLoading)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleGoogleSignIn(authProvider),
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              size: 24,
                              color: Color(0xFFDB4437),
                            ),
                            label: const Text(
                              'Login dengan Google',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Belum punya akun? "),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Daftar Sekarang'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}