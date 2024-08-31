import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Bluetooth Classic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? _connection;
  bool isConnecting = false;
  bool get isConnected => _connection != null && _connection!.isConnected;
  List<String> _messages = []; // Lista para armazenar as mensagens recebidas
  StreamSubscription<Uint8List>? _subscription; // Tipo corrigido para Uint8List

  @override
  void initState() {
    super.initState();
    requestPermissions();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  Future<void> requestPermissions() async {
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        isConnecting = false;
      });

      print('Connected to the device');

      // Ler dados da conexão
      _subscription = _connection!.input!.listen((Uint8List data) {
        String message = ascii.decode(data); // Decodifica Uint8List para String
        setState(() {
          _messages.add(message); // Armazena a mensagem recebida
        });
        print('Data incoming: $message');
      });

      // Configure o callback para quando a transmissão de dados é concluída
      _subscription!.onDone(() {
        print('Disconnected by remote request');
        setState(() {
          _connection = null;
        });
      });

    } catch (exception) {
      print('Cannot connect, exception occurred');
      setState(() {
        isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Classic"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Bluetooth status: ${_bluetoothState.toString()}'),
            ElevatedButton(
              onPressed: () async {
                if (_bluetoothState == BluetoothState.STATE_ON) {
                  final BluetoothDevice? selectedDevice = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SelectBondedDevicePage(checkAvailability: false),
                    ),
                  );

                  if (selectedDevice != null) {
                    _connectToDevice(selectedDevice);
                  }
                }
              },
              child: Text('Connect to Device'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_messages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }
}

class SelectBondedDevicePage extends StatelessWidget {
  final bool checkAvailability;

  SelectBondedDevicePage({required this.checkAvailability});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select device'),
      ),
      body: FutureBuilder<List<BluetoothDevice>>(
        future: FlutterBluetoothSerial.instance.getBondedDevices(),
        initialData: [],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return ListView(
              children: snapshot.data!.map((device) {
                return ListTile(
                  title: Text(device.name ?? "Unknown"),
                  subtitle: Text(device.address),
                  onTap: () {
                    Navigator.of(context).pop(device);
                  },
                );
              }).toList(),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
