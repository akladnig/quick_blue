import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/PeripheralDetailPage.dart';

// import 'PeripheralDetailPage.dart';

void main() {
  Logger.level = Level.info;
  runApp(const MyApp());
}

final List<BlueScanResult> _scanResults = <BlueScanResult>[];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<BlueScanResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = QuickBlue.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        if (result.name.contains('Progressor')) {
          QuickBlue.stopScan();
          setState(() => _scanResults.add(result));
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            FutureBuilder(
              future: QuickBlue.isBluetoothAvailable(),
              builder: (context, snapshot) {
                var available = snapshot.data?.toString() ?? '...';
                return Text('Bluetooth init: $available');
              },
            ),
            _buildButtons(),
            const Divider(
              color: Colors.blue,
            ),
            _buildListView(),
            _buildPermissionWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          child: const Text('startScan'),
          onPressed: () {
            QuickBlue.startScan();
          },
        ),
        ElevatedButton(
          child: const Text('stopScan'),
          onPressed: () {
            QuickBlue.stopScan();
          },
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title:
              Text('${_scanResults[index].name}(${_scanResults[index].rssi})'),
          subtitle: Text(_scanResults[index].deviceId),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PeripheralDetailPage(_scanResults[index].deviceId),
                ));
          },
        ),
        separatorBuilder: (context, index) => const Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }

  Widget _buildPermissionWarning() {
    if (Platform.isAndroid) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: const Text('BLUETOOTH_SCAN/ACCESS_FINE_LOCATION needed'),
      );
    }
    return Container();
  }
}
