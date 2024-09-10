import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:esp32_bluetooth_app/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class AnalisysGraphPage extends StatelessWidget {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
              // Usando RepaintBoundary para capturar o conteúdo sem os botões
              RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Auto Posto Atlantic Premium",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Análise de gasolina",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CircularPercentIndicator(
                      radius: 120.0,
                      lineWidth: 20.0,
                      animation: true,
                      percent: ethanolPercentage,
                      center: Text(
                        warningMessage.isNotEmpty
                            ? warningMessage
                            : "${messageModel.ethanol.toInt()}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: Colors.white,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.green,
                      backgroundColor: Colors.grey.shade800,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const Text('Etanol',
                                      style: TextStyle(color: Colors.white)),
                                  Text('${messageModel.ethanol.toInt()}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Gasolina',
                                      style: TextStyle(color: Colors.white)),
                                  Text('${messageModel.gasoline.toInt()}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Botões de ação
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão Compartilhar no WhatsApp
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                          await _sharePdfOnWhatsApp(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'WhatsApp',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Botão Compartilhar no Facebook
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                          await _sharePdfOnFacebook(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'Facebook',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Botão Compartilhar no Instagram
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                          await _sharePdfOnInstagram(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'Instagram',
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
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context, String appPackageName) async {
    try {
      // Captura o conteúdo da RepaintBoundary
      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Criar o documento PDF usando a imagem capturada
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pdfImage));
          },
        ),
      );

      // Salvar o PDF em um diretório temporário
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio.pdf");
      await file.writeAsBytes(await pdf.save());

      // Compartilhar o arquivo PDF com o aplicativo específico
      await Share.shareXFiles([XFile(file.path)],
          text: 'Relatório de Análise de Combustível',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
          subject: 'Relatório de Análise de Combustível');

    } catch (e) {
      print("Erro ao gerar PDF: $e");
    }
  }

  Future<void> _sharePdfOnWhatsApp(BuildContext context) async {
    // Lógica para compartilhar no WhatsApp
    await _sharePdf(context, 'com.whatsapp');
  }

  Future<void> _sharePdfOnFacebook(BuildContext context) async {
    // Lógica para compartilhar no Facebook
    await _sharePdf(context, 'com.facebook.katana');
  }

  Future<void> _sharePdfOnInstagram(BuildContext context) async {
    // Lógica para compartilhar no Instagram
    await _sharePdf(context, 'com.instagram.android');
  }
}
