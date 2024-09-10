import 'dart:convert';
import 'dart:typed_data';

import 'package:esp32_bluetooth_app/model/message_model.dart';
import 'package:esp32_bluetooth_app/pages/analisysGraphPage_screen.dart';
import 'package:esp32_bluetooth_app/widget/animate.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

class ConnectingScreen extends StatefulWidget {
  final BluetoothDevice device;

  const ConnectingScreen({super.key, required this.device});

  @override
  // ignore: library_private_types_in_public_api
  _ConnectingScreenState createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  BluetoothConnection? _connection;
  bool isConnecting = true;

  @override
  void initState() {
    super.initState();
    _connectToDevice(widget.device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        isConnecting = false;
      });

      bool firstMessageReceived = false;

      _connection!.input!.listen((Uint8List data) {
        String message = ascii.decode(data);
        message = message.replaceAll(RegExp(r'[^\d,]'), '');

        if (message.isNotEmpty) {
          List<String> dataValues = message.split(',');
          print('Dados recebidos (Strings): $dataValues');
          Provider.of<MessageModel>(context, listen: false).updateValues(dataValues);

          if (!firstMessageReceived) {
            firstMessageReceived = true;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AnalisysGraphPage(),
              ),
            );
          }
        }
      }).onDone(() {
        setState(() {
          _connection = null;
        });
      });
    } catch (exception) {
      setState(() {
        isConnecting = false;
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedPulse(), // Agora o AnimatedPulse está definido
            SizedBox(height: 20),
            Text(
              'Conectando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
