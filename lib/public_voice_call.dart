import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/socket_service.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'widgets/calling_sheet.dart';

class PublicVoiceCallConsumer extends StatefulWidget {
  final String astrologerId;
  final String roomId;
  const PublicVoiceCallConsumer(
      {super.key, required this.astrologerId, required this.roomId});

  @override
  State<PublicVoiceCallConsumer> createState() => _ConsumerScreenState();
}

class _ConsumerScreenState extends State<PublicVoiceCallConsumer> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Device device = Device();
  RtpCapabilities? routerRtpCapabilities;
  IO.Socket? socket;
  Transport? receiveTransport;
  Map<String, dynamic> receiveTransportInfo = {};
  MediaStream? _remoteStream;
  String userId = 'consumer_123';
  bool isMicOn = true;
  bool isSpeakerOn = true;
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
    _remoteStream?.dispose();

    socket!.emit("leaveRoom", {
      'roomId': widget.roomId,
      'user': 'user',
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: RTCVideoView(
                        _remoteRenderer,
                        mirror: false,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.blue,
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: CircleAvatar(
                            child: Text(
                              "J",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text("Connecting...")
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                margin: EdgeInsets.only(left: 16, right: 16),
                height: 60,
                width: MediaQuery.of(context).size.width - 32,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      child:
                          IconButton(onPressed: () {}, icon: Icon(Icons.mic)),
                    ),
                    CircleAvatar(
                      child: IconButton(
                          onPressed: () {}, icon: Icon(Icons.volume_up)),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.call_end,
                            color: Colors.white,
                          )),
                    )
                  ],
                ),
              ),
            )
          ],
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

  Future<void> micToggle() async {}
  Future<void> speakerToggle() async {}
}
