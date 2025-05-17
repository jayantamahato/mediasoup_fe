import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/socket_service.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConsumerScreen extends StatefulWidget {
  final String astrologerId;
  final String roomId;
  const ConsumerScreen(
      {super.key, required this.astrologerId, required this.roomId});

  @override
  State<ConsumerScreen> createState() => _ConsumerScreenState();
}

class _ConsumerScreenState extends State<ConsumerScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Device device = Device();
  RtpCapabilities? routerRtpCapabilities;
  IO.Socket? socket;
  Transport? receiveTransport;
  Map<String, dynamic> receiveTransportInfo = {};
  MediaStream? _remoteStream;
  MediaStreamTrack? _remoteTrack;
  String userId = 'consumer_123';
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      await _remoteRenderer.initialize();
      socket = SocketService().socket;
      socket!.emit("joinRoom", {
        'roomId': widget.roomId,
        'user': 'user',
      });
      socket!.off('userJoined');
      socket!.on('userJoined', (data) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(msg: data['user'] + ' joined the room');
        socket?.emit("getRouterRtpCapabilities", {"roomId": data['roomId']});
      });
      socket?.off("routerRtpCapabilities");
      socket?.on("routerRtpCapabilities", (data) async {
        try {
          routerRtpCapabilities = RtpCapabilities.fromMap(data);
          if (device.loaded) {
            await Fluttertoast.cancel();
            await Fluttertoast.showToast(msg: "Device already loaded");
            socket!.emit('createConsumerTransport', {"roomId": widget.roomId});
            return;
          }
          await device.load(routerRtpCapabilities: routerRtpCapabilities!);
          setState(() {});
          if (!device.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo)) {
            await Fluttertoast.cancel();
            await Fluttertoast.showToast(msg: "Device can't produce video");
            return;
          }
          if (!device.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio)) {
            await Fluttertoast.cancel();
            await Fluttertoast.showToast(msg: "Device can't produce audio");
            return;
          }
          socket!.emit('createConsumerTransport', {"roomId": widget.roomId});
        } catch (e) {
          log('ERROR:: $e');
        }
      });
      socket?.off("consumerTransportCreated");
      socket?.on("consumerTransportCreated", (data) async {
        try {
          receiveTransportInfo = data;
          await connectRcvTransport();
          setState(() {});
          Future.delayed(Duration(seconds: 2), () async {
            await consumeMedia();
          });
        } catch (e) {
          log('ERROR:: $e');
        }
      });
    });
    
    super.initState();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    socket!.emit("leaveRoom", {
      'roomId': widget.roomId,
      'user': 'user',
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomId),
      ),
      body: RotatedBox(
        quarterTurns: 3,
        child: RTCVideoView(
          _remoteRenderer,
          mirror: false,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }

  Future<void> connectRcvTransport() async {
    try {
      _remoteStream ??= await createLocalMediaStream('remote');
      receiveTransport = device.createRecvTransportFromMap(
        receiveTransportInfo,
        consumerCallback: (Consumer consumer, dynamic _) async {
          log("Received ${consumer.track.kind} track with ID: ${consumer.track.id}");

          _remoteStream!.addTrack(consumer.track);
          if (consumer.track.kind == 'video') {
            _remoteRenderer.srcObject = _remoteStream;
          }
          _remoteRenderer.srcObject ??= _remoteStream;
          log('Audio track enabled: ${consumer.track.kind == "audio" ? consumer.track.enabled : "N/A"}');
          log('Video track enabled: ${consumer.track.kind == "video" ? consumer.track.enabled : "N/A"}');

          socket!.emit("consumerResume", {
            'consumerId': consumer.id,
          });
          setState(() {});
        },
      );
      setState(() {});

      receiveTransport!.on("connect", (Map data) {
        socket!.emit('receiveTransportConnect', {
          'dtlsParameters': data['dtlsParameters'].toMap(),
        });
        socket?.off("receiveTransportConnected");
        socket?.on("receiveTransportConnected", (rrr) {
          try {
            data['callback']();
          } catch (e) {
            data['errback'](e);
            log("Error connecting receive transport ${e.toString()}");
          }
        });
      });
    } catch (e) {
      log("Error connecting receive transport ${e.toString()}");
    }
  }

  Future<void> consumeMedia() async {
    try {
      socket!.emit("consume", {
        'rtpCapabilities': device.rtpCapabilities.toMap(),
        'roomId': widget.roomId,
        'userId': userId,
      });

      socket!.off("audio-consumed");
      socket!.on("audio-consumed", (data) {
        log("Consuming audio: ${data['id']}");

        receiveTransport!.consume(
          peerId: '',
          id: data['id'],
          producerId: data['producerId'],
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          rtpParameters: RtpParameters.fromMap(data['rtpParameters']),
        );
        socket!.emit("consumerResume");
      });
      socket!.off("video-consumed");
      socket!.on("video-consumed", (data) {
        log("Consuming video: ${data['id']}");
        receiveTransport!.consume(
          peerId: '',
          id: data['id'],
          producerId: data['producerId'],
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          rtpParameters: RtpParameters.fromMap(data['rtpParameters']),
        );
        socket!.emit("consumerResume");
      });

      setState(() {});
    } catch (e) {
      log("Error consuming media ${e.toString()}");
    }
  }
}
