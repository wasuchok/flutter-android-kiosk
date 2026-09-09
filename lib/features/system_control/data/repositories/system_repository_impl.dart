import 'package:permission_handler/permission_handler.dart';

import '../../domain/repositories/system_repository.dart';
import '../datasources/connectivity_datasource.dart';
import '../datasources/device_local_datasource.dart';
import '../datasources/platform_channel_datasource.dart';
import '../datasources/update_datasource.dart';

class SystemRepositoryImpl implements SystemRepository {
  final DeviceLocalDataSource localDataSource;
  final PlatformChannelDataSource platformSource;
  final ConnectivityDataSource connectivityDataSource;
  final UpdateDataSource updateDataSource;

  bool _isKioskActive = false;

  SystemRepositoryImpl({
    required this.localDataSource,
    required this.platformSource,
    required this.connectivityDataSource,
    required this.updateDataSource,
  });

  @override
  bool get isKioskActive => _isKioskActive;

  @override
  Future<bool> checkInitialConnectivity() =>
      connectivityDataSource.checkConnectivity();

  @override
  Stream<bool> get internetConnectionStream =>
      connectivityDataSource.onConnectivityChanged;

  @override
  Future<String> getAppVersion() => localDataSource.getAppVersion();

  @override
  Future<String> getHardwareSerial() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) return 'Permission Denied';
    try {
      return await platformSource.getHardwareSerial();
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Future<bool> setKioskMode(bool enable) async {
    final success = await platformSource.setKioskMode(enable);
    if (success) {
      _isKioskActive = enable;
    }
    return success;
  }

  @override
  Future<void> rebootDevice() => platformSource.reboot();

  @override
  Future<void> checkForUpdate() => updateDataSource.checkForUpdate();
}
