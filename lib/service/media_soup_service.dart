import 'dart:developer';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class MediaSoupService {
  final String _tag = "MediaSoupService";
  final Device _device = Device();
  Future<Device?> loadDevice(
      {required RtpCapabilities routerRtpCapabilities}) async {
    try {
      if (!_device.loaded) {
        await _device.load(routerRtpCapabilities: routerRtpCapabilities);
        log("_tag device loaded");
        return _device;
      }
      log("_tag device already loaded");
      return _device;
    } catch (e) {
      log("$_tag - loadDevice error: ${e.toString()}");
    }
    return null;
  }

  Future<bool> canProduceAudio() async {
    return _device.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio);
  }

  Future<bool> canProduceVideo() async {
    return _device.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo);
  }

  Future<Transport?> createSendTransport({required Map transportInfo}) async {
    try {
      Transport transport = _device.createSendTransportFromMap(transportInfo);
      return transport;
    } catch (e) {
      log("$_tag - createProducerTransport error: ${e.toString()}");
    }
    return null;
  }

  Future<Transport?> createReceiveTransport(
      {required Map transportInfo, required Function callback}) async {
    try {
      Transport transport = _device.createRecvTransportFromMap(transportInfo,
          consumerCallback: callback);
      return transport;
    } catch (e) {
      log("$_tag - createConsumerTransport error: ${e.toString()}");
    }
    return null;
  }
}
