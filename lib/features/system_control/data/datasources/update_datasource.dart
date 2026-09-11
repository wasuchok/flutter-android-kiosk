import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

abstract class UpdateDataSource {
  Future<void> checkForUpdate();
}

class UpdateRemoteDataSourceImpl implements UpdateDataSource {
  static const MethodChannel _platform = MethodChannel(
    'com.example.incube_dev_test/update',
  );

  static const String versionJsonUrl =
      'https://wlkhqniaipkzlvnguung.supabase.co/storage/v1/object/public/app-releases-incube-test/version.json';

  @override
  Future<void> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(versionJsonUrl));
      debugPrint("Status code : ${response.statusCode}");
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final int latestVersionCode =
          int.tryParse(data['versionCode']?.toString() ?? '') ?? 0;
      final String latestVersionName =
          data['versionName']?.toString() ?? '';
      final String downloadUrl = data['downloadUrl']?.toString() ?? '';

      final packageInfo = await PackageInfo.fromPlatform();
      final int currentVersionCode =
          int.tryParse(packageInfo.buildNumber) ?? 0;
      final String currentVersionName = packageInfo.version;

      debugPrint('Current App: $currentVersionName ($currentVersionCode)');
      debugPrint('Latest Server: $latestVersionName ($latestVersionCode)');

      if (latestVersionCode > currentVersionCode && downloadUrl.isNotEmpty) {
        debugPrint('New version detected! Starting download...');
        final apkPath = await _downloadApk(downloadUrl);
        if (apkPath != null) {
          await _installSilently(apkPath);
        }
      } else {
        debugPrint('App is up to date.');
      }
    } on SocketException {
      debugPrint('[Update] Cannot check for update: Device is offline');
    } catch (e) {
      debugPrint('Error Download and Install: $e');
    }
  }

  Future<String?> _downloadApk(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/update.apk');

      await file.writeAsBytes(res.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint('Download failed: $e');
      return null;
    }
  }

  Future<void> _installSilently(String apkPath) async {
    try {
      final bool? success = await _platform.invokeMethod<bool>('installApk', {
        'filePath': apkPath,
      });
      debugPrint('Install requested: $success');
    } on PlatformException catch (e) {
      debugPrint('Silent install failed: ${e.message}');
    }
  }
}
