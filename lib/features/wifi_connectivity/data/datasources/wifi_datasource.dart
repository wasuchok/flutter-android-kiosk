import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

abstract class WifiDataSource {
  Future<bool> isWifiConnected();
  Stream<bool> get onWifiChanged;
  Future<bool> setWifiEnabled(bool enabled);
  Future<bool> isWifiEnabled();
}

class WifiDataSourceImpl implements WifiDataSource {
  final Connectivity _connectivity;

  static const MethodChannel _wifiPlatform =
      MethodChannel('com.example.incube_dev_test/wifi');

  WifiDataSourceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> isWifiConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  @override
  Stream<bool> get onWifiChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.contains(ConnectivityResult.wifi),
    );
  }

  @override
  Future<bool> setWifiEnabled(bool enabled) async {
    try {
      final result = await _wifiPlatform.invokeMethod<bool>(
        'setWifiEnabled',
        {'enable': enabled},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isWifiEnabled() async {
    try {
      final result = await _wifiPlatform.invokeMethod<bool>('isWifiEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
