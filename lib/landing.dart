import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:frontend/service/socket_service.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String status = "Waiting for connection....";
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool isError = false;
  IO.Socket? socket;
  Device device = Device();
  RtpCapabilities? routerRtpCapabilities;
  Transport? sendTransport;
  Transport? receiveTransport;
  Map<String, dynamic> sendTransportInfo = {};
  Map<String, dynamic> receiveTransportInfo = {};
  MediaStream? stream;
  MediaStreamTrack? _localTrack;

  @override
  void initState() {
    socket = SocketService().socket;
    listenToServer();
    Future.delayed(Duration.zero, () async {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      await render();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MEDIA-SOUP")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 45,
            width: MediaQuery.of(context).size.width,
            child: Text(
              "${status}",
              style: TextStyle(
                color: isError ? Colors.red : Colors.green,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 3,
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 1.5,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
                Container(
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 1.5,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RTCVideoView(
                      _remoteRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                ElevatedButton(
                  onPressed: () {
                    joinRoom();
                  },
                  child: Text("Join Room"),
                ),
                ElevatedButton(
                  onPressed: () {
                    getCapabilities();
                  },
                  child: Text("Get Capability"),
                ),
                ElevatedButton(
                    onPressed: () async {
                      await loadDevice();
                    },
                    child: Text("Load Device")),
                ElevatedButton(
                    onPressed: () {
                      createSendTransport();
                    },
                    child: Text("Create Send Transport")),
                ElevatedButton(
                    onPressed: () {
                      connectSendTransport();
                    },
                    child: Text("Connect Send Transport")),
                ElevatedButton(
                    onPressed: () {
                      produceMedia();
                    },
                    child: Text("Produce Media")),
                Divider(),
                ElevatedButton(
                  onPressed: () {
                    getCapabilities();
                  },
                  child: Text("Get Capability"),
                ),
                ElevatedButton(
                    onPressed: () async {
                      await loadDevice();
                    },
                    child: Text("Load Device")),
                ElevatedButton(
                    onPressed: () {
                      createConsumeTransport();
                    },
                    child: Text("Create Rcv Transport")),
                ElevatedButton(
                    onPressed: () {
                      connectRcvTransport();
                    },
                    child: Text("Connect Rcv Transport")),
                ElevatedButton(
                    onPressed: () {
                      consumeMedia();
                    },
                    child: Text("Receive Media")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void listenToServer() {
    socket?.onConnect((data) {
      setState(() {
        isError = false;
        status = "Connected!";
      });
    });
    socket?.onDisconnect((data) {
      setState(() {
        isError = true;
        status = "Not connected to the server";
      });
    });
    socket?.off("userJoined");
    socket?.on("userJoined", (data) {
      log(data.toString());
      setState(() {
        isError = false;
        status = "Joined room";
      });
    });
    socket?.off("routerRtpCapabilities");
    socket?.on("routerRtpCapabilities", (data) {
      try {
        routerRtpCapabilities = RtpCapabilities.fromMap(data);
        setState(() {
          isError = false;
          status = "Got Router RTP Capabilities";
        });
      } catch (e) {
        isError = true;
        status = e.toString();
        setState(() {});
      }
    });
    socket?.off("sendTransportCreated");
    socket?.on("sendTransportCreated", (data) {
      try {
        sendTransportInfo = data;
        setState(() {
          isError = false;
          status = "Transport created";
        });
      } catch (e) {
        isError = true;
        status = e.toString();
        setState(() {});
      }
    });

    socket?.off("consumerTransportCreated");
    socket?.on("consumerTransportCreated", (data) {
      try {
        setState(() {
          isError = false;
          status = "Consumer transport created";
        });
        receiveTransportInfo = data;
      } catch (e) {
        isError = true;
        status = e.toString();
        setState(() {});
      }
    });
  }

  void joinRoom() {
    if (socket == null) {
      setState(() {
        isError = true;
        status = "Not connected to the server";
      });
      return;
    }
    const roomId = "Test123";
    const user = "admin";
    socket?.emit("joinRoom", {"roomId": roomId, "user": user});
    listenToServer();
  }

  void getCapabilities() {
    socket?.emit("getRouterRtpCapabilities");
  }

  Future<void> loadDevice() async {
    try {
      if (!device.loaded) {
        await device.load(routerRtpCapabilities: routerRtpCapabilities!);
        log("${routerRtpCapabilities!.toMap()}");
        log("DEVICE");
        log("${device.rtpCapabilities.toMap()}");
        setState(() {
          status = "Device loaded";
        });
        if (!device.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo)) {
          setState(() {
            isError = true;
            status = "Device can't produce video";
          });
        }
        if (!device.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio)) {
          setState(() {
            isError = true;
            status = "Device can't produce audio";
          });
        }
      } else {
        log("${routerRtpCapabilities!.toMap()}");
        log("DEVICE");
        log("${device.rtpCapabilities.toMap()}");
        setState(() {
          status = "Device already loaded";
        });
      }
    } catch (e) {
      log("Error loading device ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }

  void createSendTransport() async {
    try {
      socket!.emit('createSendTransport');
    } catch (e) {
      log("Error creating transport ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }

  void connectSendTransport() async {
    try {
      sendTransport = device.createSendTransportFromMap(sendTransportInfo);
      sendTransport!.on("produce", (data) {
        socket!.emit(
          'produce',
          {
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
            setState(() {
              isError = false;
              status = "Produced";
            });
          } catch (e) {
            isError = true;
            status = e.toString();
            setState(() {});
          }
        });
      });
      setState(() {
        isError = false;
        status = "Producing Media";
      });

      sendTransport!.on("connect", (Map data) {
        socket!.emit('connectSendTransport', {
          'dtlsParameters': data['dtlsParameters'].toMap(),
        });
        socket?.off("sendTransportConnected");
        socket?.on("sendTransportConnected", (rrr) {
          try {
            data['callback']();

            setState(() {
              isError = false;
              status = "Transport connected";
            });
          } catch (e) {
            data['errback'](e);
            isError = true;
            status = e.toString();
            setState(() {});
          }
        });
      });
    } catch (e) {
      log("Error creating transport ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }

  Future<void> render() async {
    try {
      Map<String, dynamic> mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': {
          'width': {'ideal': 320},
          'height': {'ideal': 240},
        },
      };
      stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localTrack = stream!.getVideoTracks().first;
      _localRenderer.srcObject = stream;
      setState(() {});
    } catch (e) {
      log("Error rendering ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }

  Future<void> produceMedia() async {
    try {
      sendTransport!.produce(
        stream: stream!,
        track: _localTrack!,
        codecOptions: ProducerCodecOptions(videoGoogleStartBitrate: 1000),
        source: 'camera',
        appData: {
          'source': 'camera',
        },
      );
      setState(() {
        isError = false;
        status = "Rendered";
      });
    } catch (e) {
      log("Error rendering ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }

  Future<void> createConsumeTransport() async {
    try {
      socket!.emit("createConsumerTransport");
    } catch (e) {
      log("Error while consumming media ${e.toString()}");
    }
  }

  Future<void> connectRcvTransport() async {
    try {
      receiveTransport = device.createRecvTransportFromMap(
        receiveTransportInfo,
        consumerCallback: (Consumer consumer, dynamic _) async {
          if (consumer.track.kind == 'video') {
            final mediaStream = await createLocalMediaStream('remote');
            mediaStream.addTrack(consumer.track);
            _remoteRenderer.srcObject = mediaStream;

            socket!.emit("consumerResume", {
              'consumerId': consumer.id,
            });

            setState(() {});
          }
        },
      );

      receiveTransport!.on("connect", (Map data) {
        socket!.emit('receiveTransportConnect', {
          'dtlsParameters': data['dtlsParameters'].toMap(),
        });
        socket?.off("receiveTransportConnected");
        socket?.on("receiveTransportConnected", (rrr) {
          try {
            data['callback']();
            setState(() {
              isError = false;
              status = "Receive transport connected";
            });
          } catch (e) {
            data['errback'](e);
            isError = true;
            status = e.toString();
            setState(() {});
          }
        });
      });
    } catch (e) {
      log("Error connecting receive transport ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }

  Future<void> consumeMedia() async {
    try {
      socket!.emit("consume", {
        'rtpCapabilities': device.rtpCapabilities.toMap(),
      });

      socket!.off("consumed");
      socket!.on("consumed", (data) {
        log("Consuming media: ${data['id']}");
        receiveTransport!.consume(
          peerId: '',
          id: data['id'],
          producerId: data['producerId'],
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          rtpParameters: RtpParameters.fromMap(data['rtpParameters']),
        );
      });
      socket!.emit("consumerResume");

      isError = false;
      status = "Consuming media";
      setState(() {});
    } catch (e) {
      log("Error consuming media ${e.toString()}");
      setState(() {
        isError = true;
        status = e.toString();
      });
    }
  }
}
