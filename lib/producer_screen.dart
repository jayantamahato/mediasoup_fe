import 'dart:developer';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/widgets/filled_btn.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

import 'socket_service.dart';

class ProducerScreen extends StatefulWidget {
  const ProducerScreen({super.key});

  @override
  State<ProducerScreen> createState() => _ProducerScreenState();
}

class _ProducerScreenState extends State<ProducerScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final dio = Dio();
  Device device = Device();

  RtpCapabilities? routerRtpCapabilities;
  IO.Socket? socket;
  Transport? sendTransport;

  Map<String, dynamic> sendTransportInfo = {};

  MediaStream? stream;

  MediaStreamTrack? _audioTrack;
  MediaStreamTrack? _videoTrack;
  String roomID = "";
  bool isProducing = false;
  final TextEditingController userController = TextEditingController();

  bool isCameraOn = true;
  bool isMicOn = true;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      socket = SocketService().socket;
      await _localRenderer.initialize();
      Map<String, dynamic> mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': true,
      };
      stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _audioTrack = stream!.getAudioTracks().first;
      _videoTrack = stream!.getVideoTracks().first;
      _localRenderer.srcObject = stream;
      setState(() {});
      socketLister();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Host Screen"),
        actions: [
          IconButton(
            onPressed: () {
              log(roomID);

              leaveStream();
            },
            icon: Icon(
              Icons.power_settings_new_outlined,
              color: Colors.red,
            ),
          )
        ],
      ),
      body: Center(
        child: RTCVideoView(
          _localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
      bottomNavigationBar: isProducing
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        toggleCamera();
                      },
                      icon: Icon(
                          isCameraOn ? Icons.videocam : Icons.videocam_off),
                    ),
                    IconButton(
                      onPressed: () {
                        toggleMic();
                      },
                      icon: Icon(isMicOn ? Icons.mic : Icons.mic_off),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 50,
                      width: MediaQuery.of(context).size.width / 2,
                      child: TextField(
                        controller: userController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'User Id',
                            hintText: "host_123"),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      width: 180,
                      child: FilledBtn(
                        onClick: userController.text.isEmpty
                            ? () {
                                log("ID is empty");
                              }
                            : () async {
                                {
                                  try {
                                    Response response = await dio.post(
                                        'http://192.168.1.125:3000/live',
                                        data: {
                                          "astrologerId": userController.text,
                                        });
                                    log(response.data.toString());
                                    socket!.emit("joinRoom", {
                                      'roomId': response.data.toString(),
                                      'user': 'admin',
                                    });
                                  } on DioException catch (e) {
                                    if (e.response!.statusCode == 400) {
                                      await Fluttertoast.showToast(
                                          msg: 'Room already exists');
                                      socket!.emit("joinRoom", {
                                        'roomId': e.response!.data['message']
                                            .toString(),
                                        'user': 'admin',
                                      });
                                    }
                                  } catch (e) {
                                    log('$e');
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> toggleCamera() async {
    if (_videoTrack != null) {
      if (_videoTrack!.enabled) {
        _videoTrack!.enabled = false;
      } else {
        _videoTrack!.enabled = true;
      }
    }
    isCameraOn = !isCameraOn;
    setState(() {});
  }

  void socketLister() {
    socket?.off('userJoined');
    socket?.on('userJoined', (data) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: data['user'] + ' joined the room');
      socket?.emit("getRouterRtpCapabilities", {"roomId": data['roomId']});
      roomID = data['roomId'];
    });
    socket?.off("routerRtpCapabilities");
    socket?.on("routerRtpCapabilities", (data) async {
      try {
        routerRtpCapabilities = RtpCapabilities.fromMap(data);
        if (device.loaded) {
          await Fluttertoast.cancel();
          await Fluttertoast.showToast(msg: "Device already loaded");
          socket!.emit('createSendTransport', {"roomId": roomID});
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
        socket!.emit('createSendTransport', {"roomId": roomID});
      } catch (e) {
        log('ERROR:: $e');
      }
    });
    socket?.off('sendTransportCreated');
    socket?.on('sendTransportCreated', (data) async {
      sendTransportInfo = data;
      try {
        sendTransport = device.createSendTransportFromMap(sendTransportInfo);
        setState(() {});
        sendTransport!.on("produce", (data) {
          log("Producing ${data['kind']}");

          socket!.emit(
            'produce',
            {
              'roomId': roomID,
              'userId': userController.text,
              'transportId': sendTransport!.id,
              'kind': data['kind'],
              'rtpParameters': data['rtpParameters'].toMap(),
              if (data['appData'] != null)
                'appData': Map<String, dynamic>.from(data['appData'])
            },
          );
          socket?.off("produced");
          socket?.on("produced", (res) {
            try {
              log("Produced callback ${res['id']}");
              data['callback'](res['id']);
              isProducing = true;
              setState(() {});
            } catch (e) {
              log(e.toString());
            }
          });
        });
        sendTransport!.on("connect", (Map data) {
          log("Send transport connecting");

          socket!.emit('connectSendTransport', {
            'dtlsParameters': data['dtlsParameters'].toMap(),
          });
          socket?.off("sendTransportConnected");
          socket?.on("sendTransportConnected", (rrr) {
            try {
              log("Send transport connected");
              data['callback']();
            } catch (e) {
              data['errback'](e);
              log('$e');
            }
          });
        });

        Future.delayed(Duration(seconds: 1), () {
          sendTransport!.produce(
            stream: stream!,
            track: _videoTrack!,
            source: 'camera',
            appData: {
              'source': 'camera',
            },
          );
          sendTransport!.produce(
            stream: stream!,
            track: _audioTrack!,
            source: 'mic',
            appData: {
              'source': 'mic',
            },
          );

          setState(() {});
        });
      } catch (e) {
        log(e.toString());
      }
      // return;
    });
    socket?.off('error');
    socket?.on('error', (data) async {
      log('$data');
      await Fluttertoast.cancel();
      await Fluttertoast.showToast(msg: data['message'].toString());
    });
    socket?.off('leave');
    socket?.on('leave', (data) async {
      log('$data');
      await Fluttertoast.cancel();
      await Fluttertoast.showToast(msg: data['name'] + " left the room");
    });
    socket?.off('liveEnd');
    socket?.on('liveEnd', (data) async {
      _localRenderer.srcObject = null;
      stream?.dispose();
      sendTransport?.close();
      _localRenderer.srcObject = null;
      await Fluttertoast.cancel();
      await Fluttertoast.showToast(msg: "Live ended");
    });
  }

  Future<void> leaveStream() async {
    try {
      log('$roomID');
      socket?.emit('leaveStream', {
        'roomId': roomID,
        'user': {
          'type': 'admin',
          'name': 'Astrologer',
          'userId': userController.text
        },
      });
      _audioTrack?.stop();
      _videoTrack?.stop();
      sendTransport?.close();
      stream?.dispose();
      _localRenderer.srcObject = null;
      await Fluttertoast.cancel();
      await Fluttertoast.showToast(msg: "Left the room");
      // ignore: use_build_context_synchronously
      context.mounted ? Navigator.pop(context) : null;
    } catch (e) {
      log('$e');
    }
  }

  Future<void> toggleMic() async {
    if (_audioTrack != null) {
      if (_audioTrack!.enabled) {
        _audioTrack!.enabled = false;
      } else {
        _audioTrack!.enabled = true;
      }
    }
    setState(() {
      isMicOn = !isMicOn;
    });
  }
}
