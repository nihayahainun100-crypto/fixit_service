// lib/providers/ui_state_provider.dart
import 'package:flutter/material.dart';

/// UIStateProvider manages UI-related state that spans multiple screens.
/// This includes things like the selected bottom navigation index
/// and dark mode preference. By keeping this in a separate provider we
/// ensure a clear separation between UI state and business logic.
class UIStateProvider extends ChangeNotifier {
  // ----- Navigation state -----
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (index != _selectedIndex) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // ----- Theme state -----
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
