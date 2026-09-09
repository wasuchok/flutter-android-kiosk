import 'package:package_info_plus/package_info_plus.dart';

abstract class DeviceLocalDataSource {
  Future<String> getAppVersion();
}

class DeviceLocalDataSourceImpl implements DeviceLocalDataSource {
  DeviceLocalDataSourceImpl();

  @override
  Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version} (${info.buildNumber})";
  }
}
