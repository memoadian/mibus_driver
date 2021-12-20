import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum ServerStatus {
  online,
  offline,
  connecting,
}

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.connecting;
  io.Socket? _socket;

  ServerStatus get serverStatus => _serverStatus;
  io.Socket get socket => _socket!;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    /**
     * This only works in localhost if node dependency is 
     * socket io 2.3.0
     * in production works fine with version 3
     */
    _socket = io.io('https://trackingapi.memoadian.com', {
      //IO.Socket socket = IO.io('http://192.168.56.1:5002', {
      'transports': ['websocket'],
      'autoConnect': true
    });

    _socket?.onConnect((_) {
      _serverStatus = ServerStatus.online;
      notifyListeners();
    });

    _socket?.onDisconnect((_) {
      _serverStatus = ServerStatus.offline;
      notifyListeners();
    });
  }
}
