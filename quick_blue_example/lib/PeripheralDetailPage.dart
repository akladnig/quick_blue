import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

const WOODEMI_SUFFIX = 'ba5e-f4ee-5ca1-eb1e5e4b1ce0';

const WOODEMI_SERV__COMMAND = '57444d01-$WOODEMI_SUFFIX';
const WOODEMI_CHAR__COMMAND_REQUEST = '57444e02-$WOODEMI_SUFFIX';
const WOODEMI_CHAR__COMMAND_RESPONSE = WOODEMI_CHAR__COMMAND_REQUEST;

const WOODEMI_MTU_WUART = 247;

class PeripheralDetailPage extends StatefulWidget {
  final String deviceId;

  PeripheralDetailPage(this.deviceId);

  @override
  State<StatefulWidget> createState() {
    return _PeripheralDetailPageState();
  }
}

class _PeripheralDetailPageState extends State<PeripheralDetailPage> {
  @override
  void initState() {
    super.initState();
    QuickBlue.setConnectionHandler(_handleConnectionChange);
    QuickBlue.setServiceHandler(_handleServiceDiscovery);
    QuickBlue.setValueHandler(_handleValueChange);
  }

  @override
  void dispose() {
    super.dispose();
    QuickBlue.setValueHandler(null);
    QuickBlue.setServiceHandler(null);
    QuickBlue.setConnectionHandler(null);
  }

  void _handleConnectionChange(String deviceId, BlueConnectionState state) {
    print('_handleConnectionChange $deviceId, $state');
  }

  void _handleServiceDiscovery(String deviceId, String serviceId) {
    print('_handleServiceDiscovery $deviceId, $serviceId');
  }

  void _handleValueChange(String deviceId, String characteristicId, Uint8List value) {
    print('_handleValueChange $deviceId, $characteristicId, ${hex.encode(value)}');
  }

  final serviceUUID = TextEditingController(text: WOODEMI_SERV__COMMAND);
  final characteristicUUID =
      TextEditingController(text: WOODEMI_CHAR__COMMAND_REQUEST);
  final binaryCode = TextEditingController(
      text: hex.encode([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PeripheralDetailPage'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('connect'),
                onPressed: () {
                  QuickBlue.connect(widget.deviceId);
                },
              ),
              RaisedButton(
                child: Text('disconnect'),
                onPressed: () {
                  QuickBlue.disconnect(widget.deviceId);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('discoverServices'),
                onPressed: () {
                  QuickBlue.discoverServices(widget.deviceId);
                },
              ),
            ],
          ),
          RaisedButton(
            child: Text('setNotifiable'),
            onPressed: () {
              QuickBlue.setNotifiable(
                  widget.deviceId, WOODEMI_SERV__COMMAND, WOODEMI_CHAR__COMMAND_RESPONSE,
                  BleInputProperty.indication);
            },
          ),
          TextField(
            controller: serviceUUID,
            decoration: InputDecoration(
              labelText: 'ServiceUUID',
            ),
          ),
          TextField(
            controller: characteristicUUID,
            decoration: InputDecoration(
              labelText: 'CharacteristicUUID',
            ),
          ),
          TextField(
            controller: binaryCode,
            decoration: InputDecoration(
              labelText: 'Binary code',
            ),
          ),
          RaisedButton(
            child: Text('send'),
            onPressed: () {
              var value = Uint8List.fromList(hex.decode(binaryCode.text));
              QuickBlue.writeValue(
                  widget.deviceId, serviceUUID.text, characteristicUUID.text,
                  value, BleOutputProperty.withResponse);
            },
          ),
          RaisedButton(
            child: Text('requestMtu'),
            onPressed: () {
              QuickBlue.requestMtu(widget.deviceId, WOODEMI_MTU_WUART);
            },
          ),
        ],
      ),
    );
  }
}