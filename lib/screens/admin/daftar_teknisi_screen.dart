import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/technician_model.dart';
import 'tambah_teknisi_screen.dart';

class DaftarTeknisiScreen extends StatefulWidget {
  const DaftarTeknisiScreen({super.key});

  @override
  State<DaftarTeknisiScreen> createState() => _DaftarTeknisiScreenState();
}

class _DaftarTeknisiScreenState extends State<DaftarTeknisiScreen> {
  List<Technician> _teknisi = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTeknisi();
  }

  Future<void> _loadTeknisi() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getAllTeknisi();
      print('📡 Result: $result');
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        setState(() {
          _teknisi = (result['teknisi'] as List)
              .map((json) => Technician.fromJson(json))
              .toList();
          _isLoading = false;
        });
        print('✅ Loaded ${_teknisi.length} teknisi');
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Get teknisi error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi gagal: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTeknisi(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Teknisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus:'),
            const SizedBox(height: 8),
            Text('"$name"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      setState(() => _isLoading = true);

      try {
        final result = await ApiService.deleteTeknisi(id);

        if (!mounted) return;

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Teknisi berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadTeknisi();
        } else {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Gagal Menghapus'),
                ],
              ),
              content: Text(result['message'] ?? 'Terjadi kesalahan yang tidak diketahui'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tombol Tambah
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TambahTeknisiScreen()),
              );
              if (result == true) {
                _loadTeknisi();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Teknisi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        // Daftar Teknisi
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
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

    if (_teknisi.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada teknisi'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeknisi,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _teknisi.length,
        itemBuilder: (context, index) {
          final tech = _teknisi[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  tech.name.isNotEmpty ? tech.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      tech.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (tech.isPremiumListing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PREMIUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (tech.shopName.isNotEmpty)
                    Text('🏪 ${tech.shopName}', style: const TextStyle(fontSize: 12)),
                  Text('📍 ${tech.locationArea} - Rp ${tech.priceEstimate}', 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (tech.specialties.isNotEmpty)
                    Text('🔧 Spesialisasi: ${tech.specialties.join(", ")}', 
                         style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TambahTeknisiScreen(teknisi: tech)),
                      );
                      if (result == true) _loadTeknisi();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTeknisi(tech.id!, tech.name),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}