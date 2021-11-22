import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_serial_port/flutter_serial_port.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + serverName + '...')
              : isConnected
                  ? Text('Live chat with ' + serverName)
                  : Text('Chat log with ' + serverName))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                                ? 'Type your message...'
                                : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isConnected
                          ? () => _sendMessage(textEditingController.text)
                          : null),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
  int i = 1;
  String datas = "";
  Future<void> _onDataReceived(Uint8List data)  async {
    var byteArrayToHexString = await FlutterBluetoothSerial.byteArrayToHexString(data);
    if(++i == 2 ){
      datas+=byteArrayToHexString!;
    }else{
      datas+=byteArrayToHexString!;
      var s = await FlutterSerialPort.hexToInt(datas.substring(6,14));
      print('接收到消息$s');
      datas = "";
      i = 1;
    }
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  Future<String> printTrash() async {
    final hospital =
    await FlutterSerialPort.strToHexStr("南大一附院");
    final qrcode = await FlutterSerialPort.strToHexStr("360122110101");
    final deptName = await FlutterSerialPort.strToHexStr("科室：测试科室");
    final trashTypeAndWeight = await FlutterSerialPort.strToHexStr("感染性 : 0.1KG");
    final collct = await FlutterSerialPort.strToHexStr(
        "收集人：收集人");
    final date = await FlutterSerialPort.strToHexStr("21-11-19 14:45:00");
    /*String data = "1A5B01"
        "00001400"
        "FF01" //宽度
        "F000" //高度
        "00" //旋转角度
        "1A5401"
        "8000" //x轴
        "0500" //y轴
        "0060" // 字体高度
        "0011" // 文本字符特效
        "$hospital"//医院
        "00"//结尾
        "1A31000502000028000400$qrcode""00"
        "1A5401A000280000600011$deptName1""00"
        "1A5401A000460000600011$trashTypeAndWeight""00"
        "1A5401A000640000600011$collct""00"
        "1A5401A000820000600011$date""00"
        "1A5D001A4F00";*/
    String data = "1A5B01"
        "00001400"//x轴y轴偏移量
        "FF01" //宽度
        "F000" //高度
        "00" //旋转角度
        "1A5401"
        "8000" //x轴
        "0500" //y轴
        "0060" // 字体高度
        "0011" // 文本字符特效
        "$hospital"//医院
        "00"//结尾
        "1A31000502000028000400$qrcode""00"
        "1A5401A000280000600011$deptName""00"
        "1A5401A000460000600011$trashTypeAndWeight""00"
        "1A5401A000640000600011$collct""00"
        "1A5401A000820000600011$date""00"
        "1A5D001A4F00";

    // String data = "AA550300C61A5B010000000040027E01001A3100050272017800030031313233001A54018000200000600011D2BDD4BAA3BAB2E2CAD4D2BDD4BA001A54018000480000600011BFC6CAD2A3BAB2E2CAD4BFC6CAD2001A54018000700000600011D6D8C1BFA3BA302E3130001A54018000980000600011D6D6C0E0A3BA31001A54018000C00000600011CAD5BCAFC8CBA3BACAD5BCAFC8CB001A54018000C00000600011C8B7C8CFC8CBA3BAB2E2CAD4BBA4CABF001A54018000100100600011313233001A5D001A4F001B6916BB66";
    return data;
  }


  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();
    if (text.length > 0) {
      try {
        String printTrash1 = await printTrash();
        connection!.output.add(Uint8List.fromList(utf8.encode(printTrash1)));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
