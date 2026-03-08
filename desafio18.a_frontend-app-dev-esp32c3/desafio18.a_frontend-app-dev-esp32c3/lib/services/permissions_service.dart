import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final denied =
        statuses[Permission.bluetoothScan]!.isDenied ||
        statuses[Permission.bluetoothConnect]!.isDenied ||
        statuses[Permission.location]!.isDenied;

    return !denied;
  }
}
