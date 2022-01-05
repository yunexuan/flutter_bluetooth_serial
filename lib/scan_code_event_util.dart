
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanCodeEventUtil {
  ScanCodeEventUtil._();

  static final ScanCodeEventUtil _instance = ScanCodeEventUtil._();

  static ScanCodeEventUtil get instance => _instance;

  EventChannel eventChannel = const EventChannel('newBland_scan');

  StreamSubscription? streamSubscription;
  Stream? stream;

  Stream start() {
    stream = eventChannel.receiveBroadcastStream();
    return stream!;
  }

  /// 监听扫码数据
  void listen(ValueChanged<String> codeHandle) {
    streamSubscription = start().listen((event) {
      if (event != null) {
        codeHandle.call(event.toString());
      }
    });
  }

  /// 关闭监听
  void cancel() {
    streamSubscription?.cancel();
  }

}