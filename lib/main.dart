import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import necessário para inicializar o DateFormat

import 'dart:io';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Necessário para inicializar o Flutter
  await initializeDateFormatting(
      'pt_BR', null); // Inicialize a formatação de data para pt_BR
  runApp(
    ChangeNotifierProvider(
      create: (context) => MessageModel(),
      child: MyApp(),
    ),
  );
}

class MessageModel extends ChangeNotifier {
  double _ethanol = 0.0;
  double _gasoline = 0.0;
  double _temperature = 0.0;
  double _battery = 0.0;
  String _serialNumber = '';
  String _warningMessage = '';

  double get ethanol => _ethanol;
  double get gasoline => _gasoline;
  double get temperature => _temperature;
  double get battery => _battery;
  String get serialNumber => _serialNumber;
  String get warningMessage => _warningMessage;

  void updateValues(List<String> data) {
    // Verifica se o tamanho dos dados recebidos é pelo menos 4 para evitar erros de índice

    if (data.length >= 4) {
      // converter o primeiro valor para double (temperatura)
      _temperature = double.tryParse(data[0]) ?? 0.0;

      // converter o segundo valor para double (etanol)
      _ethanol = double.tryParse(data[1]) ?? 0.0;

      // converter o terceiro valor para double (bateria)
      _battery = double.tryParse(data[2]) ?? 0.0;

      // calcula o valor da gasolina subtraindo o etanol de 100
      _gasoline = 100 - _ethanol;

      // numero de serie
      _serialNumber = data.sublist(3).join();

      // Notifica os ouvintes que os dados foram atualizados
      notifyListeners();
    } else if (data.length == 2) {
      _warningMessage = data.sublist(1).join();
    } else {
      _warningMessage = data.sublist(0).join();
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste Facil Xerloq',
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
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
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

  @override
  Widget build(BuildContext context) {
    // Obtém as dimensões da tela
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      /*appBar: AppBar(
        title: Text("Teste Facil Xerloq"),
        backgroundColor: Colors.black,
      ),*/
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.8,
              margin: EdgeInsets.only(bottom: 10),
              child: Image.asset(
                'assets/logo-start.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 292,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF2B807),
                    Color(0xFFF2A007),
                    Color(0xFFD9601A),
                    Color(0xFFD94D1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (_bluetoothState == BluetoothState.STATE_ON) {
                    final BluetoothDevice? selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SelectBondedDevicePage(checkAvailability: false),
                      ),
                    );

                    print(selectedDevice);

                    if (selectedDevice != null) {
                      // Navegar diretamente para a ConnectingScreen após o dispositivo ser selecionado
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ConnectingScreen(device: selectedDevice),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.transparent, // Removendo a cor de fundo
                  shadowColor: Colors.transparent, // Removendo sombra padrão
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Conectar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
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
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ListView(
              children: snapshot.data!.map((device) {
                return ListTile(
                    title: Text(device.name ?? "Unknown"),
                    subtitle: Text(device.address),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ConnectingScreen(device: device),
                        ),
                      );
                    });
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

class AnalisysGraphPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obter a data e hora atuais no formato desejado
    String currentDate =
        DateFormat('dd MMMM yyyy - HH:mm', 'pt_BR').format(DateTime.now());

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
        body: Consumer<MessageModel>(
          builder: (context, messageModel, child) {
            String warningMessage = messageModel.warningMessage;
            double ethanolPercentage = messageModel.ethanol / 100;

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header com título e data
                Column(
                  children: [
                    const SizedBox(height: 20), // Espaçamento superior
                    Text(
                      "Auto Posto Atlantic Premium",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      currentDate, // Usando a data atual formatada
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Análise de gasolina",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // Círculo central
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 20.0,
                  animation: true,
                  percent: ethanolPercentage,
                  center: Text(
                    warningMessage.isNotEmpty
                        ? warningMessage // Exibe a mensagem de alerta se não estiver vazia
                        : "${messageModel.ethanol.toInt()}%", // Exibe a porcentagem se não houver alerta
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      color: Colors.white,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: (
                    messageModel.ethanol.toInt() <= 17) ? Colors.blue
                    : (messageModel.ethanol.toInt() <= 30) ? Colors.green
                    : Colors.red,
                  backgroundColor: Colors.grey.shade800,
                ),

                // Ícones e textos na parte inferior
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(
                          height: 20), // Espaçamento para elevar os ícones

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Image.asset('assets/combustivel.png', height: 40),
                              const SizedBox(height: 5),
                              Text('Etanol',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                  )),
                              Text('${messageModel.ethanol.toInt()}%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Image.asset('assets/combustivel.png', height: 40),
                              const SizedBox(height: 5),
                              Text('Gasolina',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15.0)),
                              Text('${messageModel.gasoline.toInt()}%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Image.asset('assets/temperature.png', height: 40),
                              const SizedBox(height: 5),
                              Text('Temperatura',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15.0)),
                              Text('${messageModel.temperature.toInt()}°',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0)),
                            ],
                          ),
                          Column(
                            children: [
                              Image.asset('assets/battery.png',
                                  height: 40), // Ícone da bateria
                              const SizedBox(height: 5),
                              Text('Bateria',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15.0)),
                              Text('${messageModel.battery.toInt()}%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),

                      // Adiciona um espaçamento entre os ícones e os botões
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Botões de ação na parte inferior
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão Compartilhar com gradiente
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF2B807),
                            Color(0xFFF2A007),
                            Color(0xFFD9601A),
                            Color(0xFFD94D1A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Chamar o método de captura diretamente
                          File? pdfFile;

                          try {
                            pdfFile = await PdfScreen(
                              ethanol: messageModel.ethanol,
                              gasoline: messageModel.gasoline,
                              temperature: messageModel.temperature,
                              serialNumber: messageModel.serialNumber,
                            ).captureAndGeneratePdf(context);
                          } catch (e) {
                            print("Erro ao gerar PDF: $e");
                          }

                          if (pdfFile != null && pdfFile.path.isNotEmpty) {
                            // Compartilhar o arquivo PDF usando shareXFiles
                            Share.shareXFiles([XFile(pdfFile.path)],
                                text: 'Relatório de Análise de Combustível');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // Removendo a cor de fundo
                          shadowColor:
                              Colors.transparent, // Removendo sombra padrão
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            'Compartilhar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botão Imprimir com gradiente
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF2B807),
                            Color(0xFFF2A007),
                            Color(0xFFD9601A),
                            Color(0xFFD94D1A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {}, // Adicione sua função aqui
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // Removendo a cor de fundo
                          shadowColor:
                              Colors.transparent, // Removendo sombra padrão
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            'Imprimir',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Espaçamento inferior
              ],
            );
          },
        ));
  }
}

class PdfScreen extends StatelessWidget {
  final double ethanol;
  final double gasoline;
  final double temperature;
  final String serialNumber;

  PdfScreen({
    required this.ethanol,
    required this.gasoline,
    required this.temperature,
    required this.serialNumber,
  });

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  Future<File> captureAndGeneratePdf(BuildContext context) async {
    // Completer para retornar o arquivo gerado
    Completer<File> completer = Completer();

    // Recupera o estado do Overlay
    OverlayState overlayState = Overlay.of(context)!;
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 10000, // Renderiza fora da área visível da tela
        left: 10000, // Renderiza fora da área visível da tela
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Material(
            color: Colors.transparent,
            child: buildPdfContent(),
          ),
        ),
      ),
    );

    // Insere o overlay
    overlayState.insert(overlayEntry);

    // Aguarda a renderização completa antes de capturar
    await Future.delayed(Duration(milliseconds: 100));

    try {
      RenderRepaintBoundary? boundary = _repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        // Captura a imagem do widget
        ui.Image image = await boundary.toImage();
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final buffer = byteData.buffer.asUint8List();

          // Cria o PDF com a imagem capturada
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(pw.MemoryImage(buffer)),
                );
              },
            ),
          );

          // Salva o PDF no diretório temporário
          final output = await getTemporaryDirectory();
          final file = File("${output.path}/relatorio.pdf");

          await file.writeAsBytes(await pdf.save());

          completer.complete(file); // Completa com o arquivo gerado
        }
      } else {
        print("Erro: boundary é null.");
      }
    } catch (e) {
      print("Erro ao capturar a tela: $e");
      completer.completeError(e); // Completa com erro, se necessário
    }

    // Remove o overlay após a captura
    overlayEntry.remove();

    return completer.future; // Retorna o arquivo gerado
  }

  // Construção da interface do PDF
  Widget buildPdfContent() {
    String currentDate =
        DateFormat('dd MMMM yyyy - HH:mm', 'pt_BR').format(DateTime.now());

    var progressColor = (ethanol.toInt() <= 17) ? Colors.blue
          : (ethanol.toInt() <= 30) ? Colors.green
          : Colors.red;

    var ethanolValue = (ethanol.toDouble() / 100);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
            FittedBox(
              child: Image.asset(
                'assets/xerloq.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            // Texto "Auto Posto Atlantic Premium"
            Text(
              "Auto Posto Atlantic Premium",
              style: TextStyle(
                  color: Colors.black, // Texto preto
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              currentDate,
              style: TextStyle(
                  color: Colors.black87, // Texto preto
                  fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Análise de gasolina",
              style: TextStyle(
                  color: Colors.black, // Texto preto
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 20), // Espaçamento abaixo do texto
        // Diminuir o tamanho do círculo
        CircularPercentIndicator(
          radius: 100.0, // Diminuir o tamanho do círculo
          lineWidth: 12.0,
          animation: false,
          percent: ethanolValue, // Percentual de etanol
          center: Text(
            "${ethanol.toInt()}%",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              color: Colors.black, // Texto preto
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: progressColor,
          backgroundColor: Colors.grey.shade300, // Fundo do gráfico
        ),
        const SizedBox(height: 20), // Espaçamento após o círculo

        // Ícones de informações na parte inferior
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Distribui os ícones
                children: [
                  Column(
                    children: [
                      Image.asset('assets/combustivel.png', height: 40),
                      const SizedBox(height: 8), // Espaçamento vertical
                      Text('Etanol',
                          style: TextStyle(
                            color: Colors.black, // Texto preto
                            fontSize: 15.0,
                          )),
                      Text('${ethanol.toInt()}%',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(width: 16), // Espaçamento horizontal entre os ícones
                  Column(
                    children: [
                      Image.asset('assets/combustivel.png', height: 40),
                      const SizedBox(height: 8),
                      Text('Gasolina',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontSize: 15.0)),
                      Text('${gasoline.toInt()}%',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(width: 16), // Espaçamento horizontal entre os ícones
                  Column(
                    children: [
                      Image.asset('assets/temperature.png', height: 40),
                      const SizedBox(height: 8),
                      Text('Temperatura',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontSize: 15.0)),
                      Text('${temperature.toInt()}°',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0)),
                    ],
                  ),
                  SizedBox(width: 16), // Espaçamento horizontal entre os ícones
                  Column(
                    children: [
                      Image.asset('assets/battery.png', height: 40),
                      const SizedBox(height: 8),
                      Text('Bateria',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontSize: 15.0)),
                      Text('100%',
                          style: TextStyle(
                              color: Colors.black, // Texto preto
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30), // Espaçamento final
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Não exibe nada na tela
  }
}

Future<void> sharePdf(double ethanol, double gasoline, double temperature,
    String serialNumber) async {
  try {
    // Formatar data e hora antes de chamar o método para criar o PDF
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String formattedTime = DateFormat('HH:mm').format(DateTime.now());

    // Gera o PDF com as informações
    final pdfFile = await PdfGenerator.createPdf(ethanol, gasoline, temperature,
        serialNumber, formattedDate, formattedTime);

    // Compartilha o arquivo PDF usando shareXFiles
    Share.shareXFiles([XFile(pdfFile.path)],
        text: 'Relatório de Análise de Combustível');
  } catch (e) {
    print("Erro ao compartilhar PDF: $e");
  }
}

class PdfGenerator {
  // Método para criar o PDF
  static Future<File> createPdf(
      double ethanol,
      double gasoline,
      double temperature,
      String serialNumber,
      String formattedDate,
      String formattedTime) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Teste Fácil Xerloq',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Auto Posto Premium Atlantic LTDA',
                style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.Text('Aparelho $serialNumber',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Registro No. 1 de 1', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Data: $formattedDate   Hora: $formattedTime',
                style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text(
                'Volume de Etanol ............: ${ethanol.toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text(
                'Volume de Gasolina ..........: ${gasoline.toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text(
                'Temperatura da amostra ......: ${temperature.toStringAsFixed(1)}°',
                style: pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/relatorio.pdf");

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

class ConnectingScreen extends StatefulWidget {
  final BluetoothDevice device;

  ConnectingScreen({required this.device});

  @override
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
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
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
          //List<String> dataValues = ['010203', 'Erro'];

          print('Dados recebidos (Strings): $dataValues');

          // Atualiza os valores no MessageModel
          Provider.of<MessageModel>(context, listen: false)
              .updateValues(dataValues);

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
      Navigator.of(context).pop(); // Voltar à tela anterior se falhar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedPulse(),
            const SizedBox(height: 20),
            const Text(
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

class AnimatedPulse extends StatefulWidget {
  @override
  _AnimatedPulseState createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF2B807),
              Color(0xFFF2A007),
              Color(0xFFD9601A),
              Color(0xFFD94D1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
