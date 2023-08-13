// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/tindeq_characteristics.dart';

//TODO split out into separate file and class
enum PrinterDetail { low, high }

var printerDetail = PrinterDetail.low;
var logger = Logger(
  printer: printerDetail == PrinterDetail.high
      ? PrettyPrinter(
          methodCount: 0, // Number of method calls to be displayed
          errorMethodCount:
              5, // Number of method calls if stacktrace is provided
          lineLength: 80, // Width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          printTime: false // Should each log print contain a timestamp
          )
      : SimplePrinter(),
);

// TODO put into a separate file
bool connected = false;
Commands currentCommand = Commands.none;

// Parse the measurement data into time and weight
List<(int, double)> parseTindeqMeasurements(Uint8List data) {
  List<(int, double)> parsedData = [];
  for (var i = 0; i < data.length - 1; i = i + 8) {
    // debugPrint("$i ${data.sublist(i, i + 4)}");
    // debugPrint("$i ${data.sublist(i + 4, i + 8)}");

    var weight = ByteData.view(data.sublist(i, i + 4).buffer)
        .getFloat32(0, Endian.little);
    // get the elapsed time in microseconds and convert to milliseconds
    var time = (ByteData.view(data.sublist(i + 4, i + 8).buffer)
                .getUint32(0, Endian.little) /
            1000)
        .round();
    parsedData.add((time, weight));
  }
  return parsedData;
}

class PeripheralDetailPage extends StatefulWidget {
  final String deviceId;

  const PeripheralDetailPage(this.deviceId, {super.key});

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
    connected = (state == BlueConnectionState.connected) ? true : false;
    logger.i('_handleConnectionChange ${state.value}');
  }

  void _handleServiceDiscovery(
      String deviceId, String serviceId, List<String> characteristicIds) {
    logger.i('_handleServiceDiscovery $serviceId, $characteristicIds');
  }

  void _handleValueChange(
      String deviceId, String characteristicId, Uint8List value) {
    ResponseCodes? responseCode = ResponseCodes.getByCode(value[0].toInt());
    int length = value[1].toInt();

    switch (responseCode) {
      case ResponseCodes.cmd:
        switch (currentCommand) {
          case Commands.getBatteryVoltage:
            int batteryVoltage =
                ByteData.view(value.buffer).getUint32(2, Endian.little);
            logger.i(
                '_handleValueChange Battery voltage R-$responseCode L-$length V-$batteryVoltage');
          case Commands.getAppVersion:
            String appVersion = utf8.decode(value.sublist(2));

            logger.i(
                '_handleValueChange App Version  R-$responseCode L-$length V-$appVersion');
          case Commands.getErrInfo:
            logger.i(
                '_handleValueChange Error Info R-$responseCode L-$length V-$value');
            if (length > 0) {
              String getErrInfo =
                  utf8.decode(value.sublist(2), allowMalformed: true);
              logger.i(
                  '_handleValueChange Error Info R-$responseCode L-$length V-$getErrInfo');
            } else {}
          default:
        }
      case ResponseCodes.weightMeasure:
        List<(int, double)> weightList =
            parseTindeqMeasurements(value.sublist(2));
        logger.i(
            '_handleValueChange Weight Measure $responseCode $length $weightList');
      case ResponseCodes.rfdPeak:
      case ResponseCodes.rfdPeakSeries:
      case ResponseCodes.lowPowerWarning:
      default:
    }
  }

  final serviceUUID = TextEditingController(text: service_uuid);
  final characteristicUUID = TextEditingController(text: write_uuid);

  @override
  Widget build(BuildContext context) {
    // TODO await - isbluetooth avail, scan, connect, discover services, notify, get battery voltage.
    // TODO auto reconnect on disconnect
    QuickBlue.connect(widget.deviceId);

    QuickBlue.discoverServices(widget.deviceId);
    // QuickBlue.setNotifiable(widget.deviceId, service_uuid, progressorDataPoint,
    //     BleInputProperty.indication);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeripheralDetailPage'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: const Text('connect'),
                onPressed: () {
                  QuickBlue.connect(widget.deviceId);
                },
              ),
              ElevatedButton(
                child: const Text('disconnect'),
                onPressed: () {
                  QuickBlue.disconnect(widget.deviceId);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: const Text('discoverServices'),
                onPressed: () {
                  QuickBlue.discoverServices(widget.deviceId);
                },
              ),
            ],
          ),
          ElevatedButton(
            child: const Text('setNotifiable'),
            onPressed: () {
              QuickBlue.setNotifiable(widget.deviceId, service_uuid,
                  notify_uuid, BleInputProperty.indication);
            },
          ),
          TextField(
            controller: serviceUUID,
            decoration: const InputDecoration(
              labelText: 'ServiceUUID',
            ),
          ),
          TextField(
            controller: characteristicUUID,
            decoration: const InputDecoration(
              labelText: 'CharacteristicUUID',
            ),
          ),
          ElevatedButton(
            child: const Text('Start Weight Measurement'),
            onPressed: () {
              currentCommand = Commands.startWeightMeas;

              var value = Uint8List.fromList([Commands.startWeightMeas.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
          ElevatedButton(
            child: const Text('Stop Weight Measurement'),
            onPressed: () {
              currentCommand = Commands.none;
              var value = Uint8List.fromList([Commands.stopWeightMeas.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
          ElevatedButton(
            child: const Text('Tare Scale'),
            onPressed: () {
              currentCommand = Commands.tareScale;
              var value = Uint8List.fromList([Commands.tareScale.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
          ElevatedButton(
            child: const Text('Battery Voltage'),
            onPressed: () {
              currentCommand = Commands.getBatteryVoltage;
              var value = Uint8List.fromList([Commands.getBatteryVoltage.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
          ElevatedButton(
            child: const Text('App Version'),
            onPressed: () {
              currentCommand = Commands.getAppVersion;
              var value = Uint8List.fromList([Commands.getAppVersion.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
          ElevatedButton(
            child: const Text('Error Info'),
            onPressed: () {
              currentCommand = Commands.getErrInfo;
              var value = Uint8List.fromList([Commands.getErrInfo.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
          ElevatedButton(
            child: const Text('Clear Error Info'),
            onPressed: () {
              currentCommand = Commands.clrErrInfo;
              var value = Uint8List.fromList([Commands.clrErrInfo.code]);
              QuickBlue.writeValue(widget.deviceId, service_uuid, write_uuid,
                  value, BleOutputProperty.withResponse);
            },
          ),
        ],
      ),
    );
  }
}
