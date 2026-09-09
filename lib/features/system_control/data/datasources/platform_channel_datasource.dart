import 'package:flutter/services.dart';

abstract class PlatformChannelDataSource {
  Future<String> getHardwareSerial();
  Future<bool> setKioskMode(bool enable);
  Future<void> reboot();
}

class PlatformChannelDataSourceImpl implements PlatformChannelDataSource {
  static const _hardwarePlatform = MethodChannel(
    'com.example.incube_dev_test/hardware',
  );
  static const _kioskPlatform = MethodChannel(
    'com.example.incube_dev_test/kiosk',
  );
  static const _powerPlatform = MethodChannel(
    'com.example.incube_dev_test/power',
  );

  @override
  Future<String> getHardwareSerial() async {
    return await _hardwarePlatform.invokeMethod<String>('getHardwareSerial') ??
        '-';
  }

  @override
  Future<bool> setKioskMode(bool enable) async {
    final method = enable ? 'startKioskMode' : 'stopKioskMode';
    return await _kioskPlatform.invokeMethod<bool>(method) ?? false;
  }

  @override
  Future<void> reboot() async {
    await _powerPlatform.invokeMethod('rebootDevice');
  }
}
