// lib/providers/ui_state_provider.dart
import 'package:flutter/material.dart';

class UIStateProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (index != _selectedIndex) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
