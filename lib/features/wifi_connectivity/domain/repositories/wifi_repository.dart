abstract class WifiRepository {
  Future<bool> checkWifiConnection();
  Stream<bool> get wifiConnectionStream;
  Future<bool> setWifiEnabled(bool enabled);
  Future<bool> isWifiEnabled();
}
