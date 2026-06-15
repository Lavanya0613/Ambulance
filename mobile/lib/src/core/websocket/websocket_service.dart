import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  void connect({required String url, required String token}) {
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setAuth({'token': token})
          .build(),
    );

    _socket?.on('connect', (_) {
      final socketId = _socket?.id ?? 'unknown';
      // ignore: avoid_print
      print('Socket connected: $socketId');
    });

    _socket?.on('disconnect', (_) {
      // ignore: avoid_print
      print('Socket disconnected');
    });

    _socket?.on('connect_error', (err) {
      // ignore: avoid_print
      print('Socket error: $err');
    });
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
