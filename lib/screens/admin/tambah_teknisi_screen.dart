import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/technician_model.dart';

class TambahTeknisiScreen extends StatefulWidget {
  final Technician? teknisi;
  
  const TambahTeknisiScreen({super.key, this.teknisi});

  @override
  State<TambahTeknisiScreen> createState() => _TambahTeknisiScreenState();
}

class _TambahTeknisiScreenState extends State<TambahTeknisiScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  
  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isUploading = false;
  
  String _selectedLocation = 'Indramayu Kota';
  String _selectedSpecialty = 'Laptop';
  bool _isPremium = false;
  bool _isAvailable = true;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _locations = [
    'Indramayu Kota', 'Jatibarang', 'Losarang', 'Anjatan', 'Kertosemaya'
  ];
  
  final List<String> _specialtiesList = [
    'Laptop', 'PC', 'Smartphone', 'Tablet', 'Printer', 'Laptop & PC'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.teknisi != null) {
      _nameController.text = widget.teknisi!.name;
      _emailController.text = widget.teknisi!.email;
      _phoneController.text = widget.teknisi!.phone;
      _shopNameController.text = widget.teknisi!.shopName;
      _addressController.text = widget.teknisi!.address;
      _priceController.text = widget.teknisi!.priceEstimate.toString();
      _selectedLocation = widget.teknisi!.locationArea;
      _selectedSpecialty = widget.teknisi!.specialties.isNotEmpty ? widget.teknisi!.specialties.first : 'Laptop';
      _isPremium = widget.teknisi!.isPremiumListing;
      _isAvailable = widget.teknisi!.isAvailable;
      _existingPhotoUrl = widget.teknisi!.photoUrl;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() => _selectedImage = File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() => _selectedImage = File(image.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _existingPhotoUrl;
    
    setState(() => _isUploading = true);
    
    try {
      final result = await ApiService.uploadTechnicianPhoto(_selectedImage!);
      if (result['success'] == true) {
        return result['photo_url'];
      }
      return _existingPhotoUrl;
    } catch (e) {
      return _existingPhotoUrl;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveTeknisi() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? photoUrl = await _uploadImage();

      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'specialties': _selectedSpecialty,
        'location_area': _selectedLocation,
        'price_estimate': int.parse(_priceController.text),
        'is_premium': _isPremium,
        'is_available': _isAvailable,
        'shop_name': _shopNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'experience': _experienceController.text,
        'photo_url': photoUrl ?? '',
      };

      Map<String, dynamic> result;
      if (widget.teknisi?.id != null) {
        data['id'] = widget.teknisi!.id!;
        result = await ApiService.updateTeknisi(data);
      } else {
        result = await ApiService.createTeknisi(data);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teknisi == null ? 'Tambah Teknisi' : 'Edit Teknisi'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveTeknisi),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔥 FOTO TEKNISI
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.orange.shade800, width: 2),
                  ),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover, width: 120, height: 120)
                        : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                            ? Image.network(
                                _existingPhotoUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, size: 60, color: Colors.grey.shade400);
                                },
                              )
                            : Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade400)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, size: 16),
                    SizedBox(width: 8),
                    Text('Upload Foto'),
                  ],
                ),
              ),
              if (_isUploading) 
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 20),
              
              // Form lainnya
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Teknisi', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Masukkan nama' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'No Telepon', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'Deskripsi / Nama Toko', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Pengalaman (contoh: 8 Tahun)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
                decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder()),
                items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                onChanged: (v) => setState(() => _selectedLocation = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialty,
                decoration: const InputDecoration(labelText: 'Spesialisasi / Kategori', border: OutlineInputBorder()),
                items: _specialtiesList.map((spec) => DropdownMenuItem(value: spec, child: Text(spec))).toList(),
                onChanged: (v) => setState(() => _selectedSpecialty = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Estimasi Harga', border: OutlineInputBorder(), prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Masukkan harga' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Teknisi Premium'),
                subtitle: const Text('Teknisi akan tampil di atas'),
                value: _isPremium,
                onChanged: (v) => setState(() => _isPremium = v),
                tileColor: Colors.grey.shade100,
              ),
              SwitchListTile(
                title: const Text('Tersedia'),
                subtitle: const Text('Teknisi aktif menerima order'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                tileColor: Colors.grey.shade100,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTeknisi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan Teknisi', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}