import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import 'token_manager.dart';
import '../core/globals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Streams / Listeners could be added here or we can just pass callbacks.
  // We'll expose simple callback setters for UI to refresh.

  Function()? onDashboardRefresh;
  Function(dynamic order)? onOrderNew;
  Function(dynamic order, String? message)? onOrderStatusUpdated;
  Function(dynamic booking)? onBookingNew;
  Function(dynamic booking)? onBookingStatusUpdated;
  Function(dynamic table)? onTableStatusUpdated;
  Function(dynamic session)? onDiningSessionStarted;
  Function(dynamic session)? onDiningSessionClosed;
  Function(dynamic order)? onDiningOrderNew;
  Function(dynamic order, String? message)? onDiningOrderStatusUpdated;
  
  Function(dynamic item)? onMenuCreated;
  Function(dynamic item)? onMenuUpdated;
  Function(dynamic menuId)? onMenuDeleted;

  void connect() async {
    if (_socket != null && _socket!.connected) return;

    // Connect to the base host matching API service, but without /api/v1
    final serverUrl = ApiService.imgHost; 

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 99999,
    });

    _socket!.onConnect((_) async {
      _isConnected = true;
      debugPrint('⚡ Socket connected: ${_socket!.id}');

      // Join respective rooms based on role
      final userStr = await TokenManager.getUserId();

      // Super simple logic to join admin or user room
      // If we're on the admin app / logged in as admin, join admin
      // The app will call joinAdmin() specifically, but we can do it here if needed.
      if (userStr != null && userStr.isNotEmpty) {
        _socket!.emit('join:user', userStr);
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('❌ Socket disconnected');
    });

    // ── Admin Specific Events ──
    _socket!.on('dashboard:refresh', (_) {
      if (onDashboardRefresh != null) onDashboardRefresh!();
    });

    _socket!.on('order:new', (data) {
      if (onOrderNew != null) onOrderNew!(data['order']);
    });

    _socket!.on('order:statusUpdated', (data) {
      if (onOrderStatusUpdated != null) onOrderStatusUpdated!(data['order'], data['message']);
    });

    _socket!.on('booking:new', (data) {
      if (onBookingNew != null) onBookingNew!(data['booking']);
    });

    _socket!.on('booking:statusUpdated', (data) {
      if (onBookingStatusUpdated != null) onBookingStatusUpdated!(data['booking']);
    });

    _socket!.on('table:statusUpdated', (data) {
      if (onTableStatusUpdated != null) onTableStatusUpdated!(data['table']);
    });

    _socket!.on('dining:sessionStarted', (data) {
      if (onDiningSessionStarted != null) onDiningSessionStarted!(data['session']);
    });

    _socket!.on('dining:sessionClosed', (data) {
      if (onDiningSessionClosed != null) onDiningSessionClosed!(data['session']);
    });

    _socket!.on('dining:orderNew', (data) {
      if (onDiningOrderNew != null) onDiningOrderNew!(data['order']);
    });

    _socket!.on('dining:orderStatusUpdated', (data) {
      if (onDiningOrderStatusUpdated != null) onDiningOrderStatusUpdated!(data['order'], data['message']);
    });

    // ── Shared Events ──
    _socket!.on('menu:created', (data) {
      if (onMenuCreated != null) onMenuCreated!(data['item']);
    });

    _socket!.on('menu:updated', (data) {
      if (onMenuUpdated != null) onMenuUpdated!(data['item']);
    });

    _socket!.on('menu:deleted', (data) {
      if (onMenuDeleted != null) onMenuDeleted!(data['menuId']);
    });

    _socket!.on('notification:new', (data) {
      final notif = data['notification'];
      if (notif != null) {
        final title = notif['title'] ?? 'Notification';
        final message = notif['message'] ?? '';
        
        // Show Global SnackBar
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(message, style: GoogleFonts.poppins(fontSize: 11)),
              ],
            ),
            backgroundColor: const Color(0xFFFF6A00),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(15),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  void joinAdminRoom() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join:admin');
    } else {
      // Retry once socket connects
      Future.delayed(const Duration(seconds: 1), joinAdminRoom);
    }
  }

  void joinUserRoom(String userId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join:user', userId);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
