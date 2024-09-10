import 'package:flutter/material.dart';

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
    if (data.length >= 4) {
      _temperature = double.tryParse(data[0]) ?? 0.0;
      _ethanol = double.tryParse(data[1]) ?? 0.0;
      _battery = double.tryParse(data[2]) ?? 0.0;
      _gasoline = 100 - _ethanol;
      _serialNumber = data.sublist(3).join();
      notifyListeners();
    } else if (data.length == 2) {
      _warningMessage = data.sublist(1).join();
    } else {
      _warningMessage = data.sublist(0).join();
    }
  }
}
