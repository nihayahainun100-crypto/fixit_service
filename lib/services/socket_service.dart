import 'dart:ui';
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class SocketService {
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  io.Socket? _socket;
  String? _serverUrl;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Function(Map<String, dynamic>)? _onBookingReceived;
  Function(Map<String, dynamic>)? _onBookingUpdated;
  Function(Map<String, dynamic>)? _onAnnouncementReceived;

  void connect({
    Function(Map<String, dynamic>)? onBookingReceived,
    Function(Map<String, dynamic>)? onBookingUpdated,
    Function(Map<String, dynamic>)? onAnnouncementReceived,
    VoidCallback? onConnected,
    VoidCallback? onDisconnected,
  }) {
    if (onBookingReceived != null) _onBookingReceived = onBookingReceived;
    if (onBookingUpdated != null) _onBookingUpdated = onBookingUpdated;
    if (onAnnouncementReceived != null) _onAnnouncementReceived = onAnnouncementReceived;

    _serverUrl = 'ws://${ApiService.ipAddress}:3000';

    if (_socket != null && _socket!.connected) {
      onConnected?.call();
      return;
    }

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(100)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      log('Socket connected: ${_socket!.id} to $_serverUrl');
      _isConnected = true;
      onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      log('Socket disconnected');
      _isConnected = false;
      onDisconnected?.call();
    });

    _socket!.onConnectError((data) {
      log('Connect error: $data');
      _isConnected = false;
      onDisconnected?.call();
    });

    _socket!.on('booking:received', (data) {
      log('Socket booking:received $data');
      if (data is Map && _onBookingReceived != null) {
        _onBookingReceived!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('booking:updated', (data) {
      log('Socket booking:updated $data');
      if (data is Map && _onBookingUpdated != null) {
        _onBookingUpdated!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('announcement:received', (data) {
      log('Socket announcement:received $data');
      if (data is Map && _onAnnouncementReceived != null) {
        _onAnnouncementReceived!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void sendBookingNotification({
    required String technicianId,
    required String bookingId,
    required String customerName,
  }) {
    if (_socket == null || !_isConnected) {
      log('Socket not connected. Attempting to connect first...');
      
      connect();
      
    }

    final payload = {
      'type': 'booking:send',
      'technician_id': technicianId,
      'booking_id': bookingId,
      'customer_name': customerName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket?.emit('booking:send', payload);
    log('Emitted booking:send: $payload');
  }

  void sendBookingUpdateNotification({
    required String bookingId,
    required String userId,
    required String status,
    String? notes,
  }) {
    if (_socket == null || !_isConnected) {
      log('Socket not connected. Attempting to connect first...');
      connect();
    }

    final payload = {
      'type': 'booking:update',
      'booking_id': bookingId,
      'user_id': userId,
      'status': status,
      'notes': notes ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket?.emit('booking:update', payload);
    log('Emitted booking:update: $payload');
  }

  void sendAnnouncement({
    required String senderName,
    required String message,
  }) {
    if (_socket == null || !_isConnected) {
      log('Socket not connected');
      return;
    }

    final payload = {
      'senderName': senderName,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket!.emit('announcement:send', payload);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}