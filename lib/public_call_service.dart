import 'package:socket_io_client/socket_io_client.dart' as IO;

class PublicCallService {
  final IO.Socket socket;
  PublicCallService({required this.socket});

  void joinRoom(
      {required String roomId,
      required String userName,
      required String userId}) {
    socket.emit("joinRoom", {
      'roomId': roomId,
      'user': {'name': userName, 'type': 'user', 'userId': userId},
    });
  }

  void getRouterCapabilities({required String roomId}) {
    socket.emit("getRouterRtpCapabilities", {"roomId": roomId});
  }

  void requestForPublicVoiceCall(
      {required String userId, required userName, required roomId}) {
    Map body = {
      'userId': userId,
      'userName': userName,
      'roomId': roomId,
    };
    socket.emit("requestForPublicVoiceCall", body);
  }
}
