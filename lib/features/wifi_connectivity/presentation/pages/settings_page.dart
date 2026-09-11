import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/retry_policy.dart';
import '../../domain/entities/wifi_network.dart';
import '../../domain/usecases/connect_wifi_usecase.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.currentPolicy,
    this.connectWifiUseCase,
  });

  final RetryPolicy currentPolicy;
  final ConnectWifiUseCase? connectWifiUseCase;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late RetryMode _retryMode;
  final _minutesController = TextEditingController(text: '10');
  final _ssidController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _retryMode = widget.currentPolicy.mode;
    if (widget.currentPolicy.maxDuration != null) {
      _minutesController.text =
          widget.currentPolicy.maxDuration!.inMinutes.toString();
    }
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ssid = prefs.getString('wifi_ssid');
      final username = prefs.getString('wifi_username');
      final password = prefs.getString('wifi_password');

      if (!mounted) return;
      setState(() {
        if (ssid != null) _ssidController.text = ssid;
        if (username != null) _usernameController.text = username;
        if (password != null) _passwordController.text = password;
      });
    } catch (_) {}
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ssid = _ssidController.text.trim();
      if (ssid.isEmpty) {
        await prefs.remove('wifi_ssid');
        await prefs.remove('wifi_username');
        await prefs.remove('wifi_password');
      } else {
        await prefs.setString('wifi_ssid', ssid);
        await prefs.setString('wifi_username', _usernameController.text.trim());
        await prefs.setString('wifi_password', _passwordController.text);
      }
    } catch (_) {}
  }

  Future<void> _clearCredentials() async {
    setState(() {
      _ssidController.clear();
      _usernameController.clear();
      _passwordController.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wifi_ssid');
      await prefs.remove('wifi_username');
      await prefs.remove('wifi_password');
    } catch (_) {}

    try {
      await const MethodChannel('com.example.incube_dev_test/wifi')
          .invokeMethod('disconnectWifi');
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ล้างข้อมูล Wi-Fi เรียบร้อยแล้ว')),
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _ssidController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openSystemWifiSettings() async {
    try {
      await const MethodChannel('com.example.incube_dev_test/wifi')
          .invokeMethod('openWifiSettings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดหน้าตั้งค่า Wi-Fi ได้: $e')),
      );
    }
  }

  Future<void> _connectWifi() async {
    final ssid = _ssidController.text.trim();
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก SSID ของ Wi-Fi')),
      );
      return;
    }

    setState(() => _isConnecting = true);
    try {
      try {
        final status = await Permission.location.request();
        if (status.isPermanentlyDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'กรุณาเปิดสิทธิ์ Location และ GPS เพื่อให้ Android สแกนหา Wi-Fi ได้',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (_) {}

      await _saveCredentials();

      final useCase = widget.connectWifiUseCase ??
          (sl.isRegistered<ConnectWifiUseCase>()
              ? sl<ConnectWifiUseCase>()
              : null);
      if (useCase == null) {
        throw Exception('ConnectWifiUseCase not found');
      }

      final success = await useCase(
        WifiNetwork(
          ssid: ssid,
          username: _usernameController.text.trim().isEmpty
              ? null
              : _usernameController.text.trim(),
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'เชื่อมต่อ Wi-Fi สำเร็จ': 'ไม่สามารถเชื่อมต่อ Wi-Fi ได้',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _save() async {
    await _saveCredentials();

    final policy = _retryMode == RetryMode.untilConnected
        ? const RetryPolicy.untilConnected()
        : RetryPolicy.maxDuration(
            Duration(
              minutes: (int.tryParse(_minutesController.text) ?? 10).clamp(1, 1440),
            ),
          );

    if (mounted) {
      Navigator.pop(context, policy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wi-Fi Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: 'Wi-Fi SSID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isConnecting ? null : _connectWifi,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.wifi_lock),
                    label: Text(
                      _isConnecting ? 'กำลังเชื่อมต่อ...': 'Connect Wi-Fi',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearCredentials,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _openSystemWifiSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('เปิดตั้งค่า Wi-Fi ของเครื่อง'),
              ),
            ),
            const Divider(height: 36),
            Text(
              'Retry Policy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioGroup<RetryMode>(
              groupValue: _retryMode,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _retryMode = value);
              },
              child: Column(
                children: const [
                  RadioListTile<RetryMode>(
                    title: Text('Retry until connected'),
                    value: RetryMode.untilConnected,
                  ),
                  RadioListTile<RetryMode>(
                    title: Text('Stop retrying after'),
                    value: RetryMode.maxDuration,
                  ),
                ],
              ),
            ),
            if (_retryMode == RetryMode.maxDuration)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum retry duration',
                    suffixText: 'minutes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
