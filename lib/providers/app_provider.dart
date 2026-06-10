import 'package:flutter/foundation.dart';

class AppProvider extends ChangeNotifier {
  String _announcement = "Promo Spesial Juni: Diskon Service Laptop 10%!";
  bool _isMaintenanceMode = false;
  int _activeNotificationCount = 3;

  String get announcement => _announcement;
  bool get isMaintenanceMode => _isMaintenanceMode;
  int get activeNotificationCount => _activeNotificationCount;

  void updateAnnouncement(String newAnnouncement) {
    if (_announcement != newAnnouncement) {
      _announcement = newAnnouncement;
      notifyListeners();
    }
  }

  void toggleMaintenanceMode() {
    _isMaintenanceMode = !_isMaintenanceMode;
    notifyListeners();
  }

  void clearNotifications() {
    if (_activeNotificationCount != 0) {
      _activeNotificationCount = 0;
      notifyListeners();
    }
  }
}