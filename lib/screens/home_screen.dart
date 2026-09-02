import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _deviceInfoPlugin = DeviceInfoPlugin();
  final _networkInfo = NetworkInfo();

  static const _hardwarePlatform = MethodChannel(
    'com.example.incube_dev_test/hardware',
  );
  static const _kioskPlatform = MethodChannel(
    'com.example.incube_dev_test/kiosk',
  );
  static const _powerPlatform = MethodChannel(
    'com.example.incube_dev_test/power',
  );

  final Map<String, dynamic> _deviceData = <String, dynamic>{};
  BaseDeviceInfo? _deviceInfo;
  bool _isLoading = true;
  bool _isKioskActive = false;
  String _serialNumber = '';

  bool _isConnectedToInternet = false;
  StreamSubscription<InternetStatus>? _internetSubscription;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  void _initInternetListener() {
    _internetSubscription = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      setState(() {
        _isConnectedToInternet = (status == InternetStatus.connected);
      });
    });
  }

  Future<void> _rebootDevice() async {
    try {
      await _powerPlatform.invokeMethod('rebootDevice');
    } on PlatformException catch (e) {
      debugPrint('Reboot error: ${e.message}');
    }
  }

  Future<void> _startKioskMode() async {
    try {
      final bool? success = await _kioskPlatform.invokeMethod('startKioskMode');
      if (success == true) {
        setState(() {
          _isKioskActive = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kiosk Mode เปิด ล็อกหน้าจอ')),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Kiosk error: ${e.message}');
    }
  }

  Future<void> _stopKioskMode() async {
    try {
      final bool? success = await _kioskPlatform.invokeMethod('stopKioskMode');
      if (success == true) {
        setState(() {
          _isKioskActive = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kiosk Mode ปิด ล็อกหน้าจอ')),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Kiosk error: ${e.message}');
    }
  }

  Future<void> _fetchHardwareSerial() async {
    setState(() {
      _isLoading = true;
    });

    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (!status.isGranted) {
      setState(() {
        _serialNumber = 'Failed: Permission READ_PHONE_STATE is denied';
        _isLoading = false;
      });
      return;
    }

    try {
      final String result = await _hardwarePlatform.invokeMethod(
        'getHardwareSerial',
      );
      setState(() {
        _serialNumber = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _serialNumber = 'Failed to get serial: ${e.message}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initData() async {
    _deviceInfo = await _deviceInfoPlugin.deviceInfo;

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isGranted) {
      try {
        final wifiName = await _networkInfo.getWifiName();
        final wifiBSSID = await _networkInfo.getWifiBSSID();
        final wifiIP = await _networkInfo.getWifiIP();
        final wifiIPv6 = await _networkInfo.getWifiIPv6();
        final wifiSubmask = await _networkInfo.getWifiSubmask();
        final wifiBroadcast = await _networkInfo.getWifiBroadcast();
        final wifiGateway = await _networkInfo.getWifiGatewayIP();

        _deviceData['Wi-Fi Name'] = wifiName;
        _deviceData['Wi-Fi BSSID'] = wifiBSSID;
        _deviceData['Wi-Fi IP'] = wifiIP;
        _deviceData['Wi-Fi IPv6'] = wifiIPv6;
        _deviceData['Wi-Fi Submask'] = wifiSubmask;
        _deviceData['Wi-Fi Broadcast'] = wifiBroadcast;
        _deviceData['Wi-Fi Gateway'] = wifiGateway;
        _startKioskMode();
        _fetchHardwareSerial();
        _initInternetListener();
      } catch (e) {
        _deviceData['Wi-Fi Name'] = 'Error: $e';
      }
    } else {
      _deviceData['Wi-Fi Name'] = 'Permission Denied';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device & Network Info')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deviceInfo == null
          ? const Center(child: Text('Fail'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    color: _isConnectedToInternet
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnectedToInternet
                              ? 'ONLINE (เชื่อมต่ออินเทอร์เน็ตแล้ว)'
                              : 'OFFLINE (ไม่มีสัญญาณอินเทอร์เน็ต)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: _rebootDevice,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('รีสตาร์ต'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SelectableText(
                    _serialNumber,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  Card(
                    margin: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.wifi),
                            title: const Text(
                              'Wi-Fi Name (SSID)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi Name']?.toString() ??
                                  'No Data',
                            ),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.router),
                            title: const Text(
                              'BSSID (MAC Address)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi BSSID']?.toString() ??
                                  'No Data',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.numbers),
                            title: const Text(
                              'IPv4 Address',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi IP']?.toString() ?? 'No Data',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text(
                              'IPv6 Address',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi IPv6']?.toString() ??
                                  'No Data',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.grid_4x4),
                            title: const Text(
                              'Subnet Mask',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi Submask']?.toString() ??
                                  'No Data',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.podcasts),
                            title: const Text(
                              'Broadcast Address',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi Broadcast']?.toString() ??
                                  'No Data',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.dns),
                            title: const Text(
                              'Gateway IP',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _deviceData['Wi-Fi Gateway']?.toString() ??
                                  'No Data',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: _isKioskActive
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: _isKioskActive ? Colors.red : Colors.green,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _isKioskActive
                                ? 'สถานะ: KIOSK MODE (ล็อก)'
                                : 'สถานะ: โหมดปกติ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isKioskActive ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _isKioskActive
                                    ? null
                                    : _startKioskMode,
                                child: Text('เปิด'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isKioskActive
                                    ? _stopKioskMode
                                    : null,
                                child: Text('ปิด'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _deviceInfo!.data.entries.map((entry) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(entry.value.toString()),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
