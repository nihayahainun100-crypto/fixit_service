import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  // Hapus UserRole enum dan ganti role, karena role sudah ditentukan dari login
  
  // Cukup simpan info user dari AuthProvider
  bool _isTechnician = false;
  
  bool get isTechnician => _isTechnician;

  String? get currentUserName => null;

  get currentUserId => null;
  
  void setTechnicianMode(bool isTech) {
    _isTechnician = isTech;
    notifyListeners();
  }
}