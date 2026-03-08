import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/permissions_service.dart';

class InfusionController extends ChangeNotifier {
  final BleService ble;
  final PermissionsService permissions;

  InfusionController({required this.ble, required this.permissions});

  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writable;

  bool isScanning = false;
  String status = "Aguardando conexão...";

  double flowRate = 0; // 0..100
  bool isInfusing = false;

  final int minPWM = 210;
  final int maxPWM = 255;

  StreamSubscription? _adapterSub;
  StreamSubscription? _scanSub;

  void init() {
    _adapterSub = ble.adapterState.listen((s) {
      if (s == BluetoothAdapterState.off) {
        status = "Bluetooth desligado!";
        notifyListeners();
      }
    });

    _scanSub = ble.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  bool get isConnected => connectedDevice != null && writable != null;

  Future<void> startScan() async {
    final ok = await permissions.requestBlePermissions();
    if (!ok) {
      status = "Permissões negadas.";
      notifyListeners();
      return;
    }

    status = "Buscando equipamento...";
    isScanning = true;
    scanResults = [];
    notifyListeners();

    try {
      await ble.startScan();
    } catch (e) {
      status = "Erro: $e";
    }

    Future.delayed(const Duration(seconds: 10), () {
      isScanning = false;
      status = scanResults.isEmpty
          ? "Nenhum equipamento encontrado."
          : "Selecione o equipamento:";
      notifyListeners();
    });
  }

  Future<void> connect(BluetoothDevice device) async {
    await ble.stopScan();
    status = "Conectando...";
    notifyListeners();

    try {
      final c = await ble.connectAndFindWritable(device);
      if (c == null) {
        await ble.disconnect(device);
        status = "Falha de compatibilidade.";
        notifyListeners();
        return;
      }

      connectedDevice = device;
      writable = c;
      status = "Equipamento pronto";
      flowRate = 0;
      isInfusing = false;
      notifyListeners();
    } catch (_) {
      status = "Erro ao conectar.";
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await sendPWM(0);
    if (connectedDevice != null) await ble.disconnect(connectedDevice!);

    connectedDevice = null;
    writable = null;
    status = "Desconectado";
    isInfusing = false;
    flowRate = 0;
    notifyListeners();
  }

  void setFlow(double v) {
    flowRate = v.clamp(0, 100);
    applyMotorPower();
    notifyListeners();
  }

  void bumpFlow(double delta) {
    flowRate = (flowRate + delta).clamp(0, 100);
    applyMotorPower();
    notifyListeners();
  }

  void toggleInfusing() {
    isInfusing = !isInfusing;
    applyMotorPower();
    notifyListeners();
  }

  void applyMotorPower() {
    if (writable == null) return;

    int pwmValue = 0;
    if (isInfusing && flowRate > 0) {
      pwmValue = minPWM + ((flowRate / 100) * (maxPWM - minPWM)).round();
    }
    sendPWM(pwmValue);
  }

  Future<void> sendPWM(int value) async {
    final c = writable;
    if (c == null) return;

    try {
      await c.write([value], withoutResponse: true);
    } catch (_) {
      try {
        await c.write([value], withoutResponse: false);
      } catch (e2) {
        debugPrint("Erro: $e2");
      }
    }
  }
}
