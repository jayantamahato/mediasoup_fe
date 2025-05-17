import 'package:flutter/material.dart';
import 'package:frontend/socket_service.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ViewScreen extends StatefulWidget {
  final String astrologerId;
  final String roomId;
  const ViewScreen(
      {super.key, required this.astrologerId, required this.roomId});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Device device = Device();
  RtpCapabilities? routerRtpCapabilities;
  IO.Socket? socket;
  Transport? receiveTransport;
  Map<String, dynamic> receiveTransportInfo = {};
  MediaStream? stream;
  MediaStreamTrack? _remoteStream;
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      socket = SocketService().socket;
      socket!.emit("joinRoom", {
        'roomId': widget.roomId,
        'user': 'user',
      });
      await _remoteRenderer.initialize();
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomId),
      ),
    );
  }
}
