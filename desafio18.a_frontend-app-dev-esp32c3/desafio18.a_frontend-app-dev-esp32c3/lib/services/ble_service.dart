import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults;

  Future<void> startScan() async {
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: true,
    );
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<BluetoothCharacteristic?> connectAndFindWritable(
    BluetoothDevice device,
  ) async {
    await device.connect();
    final services = await device.discoverServices();

    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) {
          return c;
        }
      }
    }
    return null;
  }

  Future<void> disconnect(BluetoothDevice device) => device.disconnect();
}
