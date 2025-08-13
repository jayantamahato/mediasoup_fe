import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  void connect() {
    socket = IO.io(
      'http://192.168.1.125:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    if (socket == null || socket!.connected == false) {
      socket?.connect();
    }
  }

  SocketService() {
    connect();
    socket?.onConnect((_) {
      log('::connected with socket::');
    });
    socket?.onDisconnect((_) {
      log('::disconnected with socket::');
    });
  }
  IO.Socket get socketInstance => socket!;
}
