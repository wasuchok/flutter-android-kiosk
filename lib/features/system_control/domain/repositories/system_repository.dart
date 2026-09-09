abstract class SystemRepository {
  Future<bool> checkInitialConnectivity();
  Future<String> getAppVersion();
  Future<String> getHardwareSerial();
  Stream<bool> get internetConnectionStream;
  Future<bool> setKioskMode(bool enable);
  bool get isKioskActive;
  Future<void> rebootDevice();
  Future<void> checkForUpdate();
}
