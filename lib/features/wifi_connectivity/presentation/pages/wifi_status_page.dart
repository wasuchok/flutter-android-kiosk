import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/retry_policy.dart';
import '../../services/wifi_connection_service.dart';
import 'settings_page.dart';

class WifiStatusPage extends StatefulWidget {
  final WifiConnectionService wifiService;

  WifiStatusPage({super.key, WifiConnectionService? wifiService})
    : wifiService = wifiService ?? sl<WifiConnectionService>();

  @override
  State<WifiStatusPage> createState() => _WifiStatusPageState();
}

class _WifiStatusPageState extends State<WifiStatusPage> {
  @override
  void initState() {
    super.initState();
    widget.wifiService.addListener(_onStatusChanged);
    widget.wifiService.start();
  }

  void _onStatusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    widget.wifiService.removeListener(_onStatusChanged);
    super.dispose();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<RetryPolicy>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SettingsPage(currentPolicy: widget.wifiService.retryPolicy),
      ),
    );

    if (result == null) return;
    widget.wifiService.setRetryPolicy(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Wi-Fi Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 450,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIcon(),
                  const SizedBox(height: 24),
                  Text(
                    _buildTitle(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.wifiService.statusText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!widget.wifiService.isConnected)
                    const LinearProgressIndicator(),
                  if (!widget.wifiService.isConnected) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: widget.wifiService.isChecking
                          ? null
                          : widget.wifiService.retryNow,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        widget.wifiService.status ==
                                WifiConnectionStatus.retryStopped
                            ? 'Retry Again'
                            : 'Retry Now',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.wifiService.status) {
      case WifiConnectionStatus.connected:
        return const Icon(Icons.wifi, size: 80, color: Colors.green);

      case WifiConnectionStatus.checking:
        return const Icon(Icons.wifi_find, size: 80, color: Colors.blue);

      case WifiConnectionStatus.disconnected:
      case WifiConnectionStatus.waitingToRetry:
        return const Icon(Icons.wifi_off, size: 80, color: Colors.red);

      case WifiConnectionStatus.retryStopped:
        return const Icon(Icons.error_outline, size: 72, color: Colors.red);
    }
  }

  String _buildTitle() {
    switch (widget.wifiService.status) {
      case WifiConnectionStatus.connected:
        return 'Connected';

      case WifiConnectionStatus.checking:
        return 'Checking Connection';

      case WifiConnectionStatus.disconnected:
        return 'Disconnected';

      case WifiConnectionStatus.waitingToRetry:
        return 'Connection Lost';

      case WifiConnectionStatus.retryStopped:
        return 'Retry Stopped';
    }
  }
}
