import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:syncfusion_flutter_gauges/gauges.dart';

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
      home: MyButtonPage(),
    );
  }
}

class MyButtonPage extends StatefulWidget {
  @override
  _MyButtonPageState createState() => _MyButtonPageState();
}

class _MyButtonPageState extends State<MyButtonPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? _connection;
  bool isConnecting = false;
  bool get isConnected => _connection != null && _connection!.isConnected;
  List<String> _messages = [];
  StreamSubscription<Uint8List>? _subscription;

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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        isConnecting = false;
      });

      _subscription = _connection!.input!.listen((Uint8List data) {
        String message = ascii.decode(data);
        setState(() {
          _messages.add(message);
        });
      });

      _subscription!.onDone(() {
        setState(() {
          _connection = null;
        });
      });

    } catch (exception) {
      setState(() {
        isConnecting = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Bluetooth Classic"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 254,
              height: 297,
              margin: EdgeInsets.only(bottom: 20),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const Text(
              'Teste Fácil Xerloq',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 292,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () async {
                  if (_bluetoothState == BluetoothState.STATE_ON) {
                    final BluetoothDevice? selectedDevice = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SelectBondedDevicePage(),
                      ),
                    );

                    if (selectedDevice != null) {
                      _connectToDevice(selectedDevice);
                    }
                  }
                },
                child: const Text(
                  'Conexão',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _messages[index],
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectBondedDevicePage extends StatelessWidget {
  final String shareText = '''
  Teste Fácil Xerloq
  Auto Posto Premium Atantic LTDA
  Aparelho 2400101
  Registro No. 7 de 7
  Data: 19/08/2023 Hora: 20:06
  Volume de Etanol: 27%
  Volume de Gasolina: 73%
  Temperatura da amostra: 27°
  ''';

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.whatshot, color: Colors.green, size: 40),
                onPressed: () => _shareToApp('whatsapp', shareText),
              ),
              IconButton(
                icon: Icon(Icons.facebook, color: Colors.blue, size: 40),
                onPressed: () => _shareToApp('facebook', shareText),
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.pink, size: 40),
                onPressed: () => _shareToApp('instagram', shareText),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareToApp(String app, String text) async {
    String url;

    switch (app) {
      case 'whatsapp':
        url = 'whatsapp://send?text=$text';
        break;
      case 'facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=$text';
        break;
      case 'instagram':
        // Instagram doesn't allow text sharing directly; you might open the app instead
        url = 'instagram://app';
        break;
      default:
        url = '';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // If the app is not installed or cannot be launched, fall back to normal sharing
      Share.share(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Image.asset('assets/ethanol.png', height: 40),
                    const Text('Etanol', style: TextStyle(color: Colors.white)),
                    const Text('25%', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  children: [
                    Image.asset('assets/gasoline.png', height: 40),
                    const Text('Gasolina', style: TextStyle(color: Colors.white)),
                    const Text('75%', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  children: [
                    Image.asset('assets/temperature.png', height: 40),
                    const Text('Temperatura', style: TextStyle(color: Colors.white)),
                    const Text('22°', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _showShareOptions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Compartilhar'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle print action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Imprimir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}