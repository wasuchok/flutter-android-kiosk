import '../../domain/entities/wifi_network.dart';
import '../../domain/repositories/wifi_repository.dart';
import '../datasources/wifi_datasource.dart';

class WifiRepositoryImpl implements WifiRepository {
  final WifiDataSource dataSource;

  WifiRepositoryImpl({required this.dataSource});

  @override
  Future<bool> checkWifiConnection() => dataSource.isWifiConnected();

  @override
  Stream<bool> get wifiConnectionStream => dataSource.onWifiChanged;

  @override
  Future<bool> setWifiEnabled(bool enabled) =>
      dataSource.setWifiEnabled(enabled);

  @override
  Future<bool> isWifiEnabled() => dataSource.isWifiEnabled();

  @override
  Future<bool> connectWifi(WifiNetwork network) async {
    return await dataSource.connectToNativeWifi(
      network.ssid,
      network.password ?? '',
      network.username ?? '',
    );
  }
}
