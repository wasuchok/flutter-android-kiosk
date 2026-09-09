import 'package:flutter/material.dart';
import '../../services/wifi_connection_service.dart';

class WifiConnectionCard extends StatelessWidget {
  const WifiConnectionCard({
    super.key,
    required this.service,
    this.onOpenSettings,
  });

  final WifiConnectionService service;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final status = service.status;

    if (status == WifiConnectionStatus.connected) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Wi-Fi Connected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.statusText.isNotEmpty
                          ? service.statusText
                          : 'Connected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenSettings != null)
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Colors.black54,
                  ),
                  tooltip: 'Wi-Fi Settings',
                  onPressed: onOpenSettings,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WifiStatusIcon(status: status, size: 36),
            const SizedBox(height: 10),
            Text(
              _getTitle(status),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            if (status == WifiConnectionStatus.checking)
              const LinearProgressIndicator(),
            if (status == WifiConnectionStatus.waitingToRetry) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Retry attempt: ${service.retryAttempt}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                'Next retry in ${service.retryCountdown} seconds',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (status == WifiConnectionStatus.disconnected)
              const LinearProgressIndicator(),
            if (status != WifiConnectionStatus.connected) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: service.isChecking ? null : service.retryNow,
                    icon: const Icon(Icons.refresh, size: 16),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    label: Text(
                      status == WifiConnectionStatus.retryStopped
                          ? 'Retry Again'
                          : 'Retry Now',
                    ),
                  ),
                  if (onOpenSettings != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings, size: 16),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      label: const Text('Settings'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTitle(WifiConnectionStatus status) {
    switch (status) {
      case WifiConnectionStatus.checking:
        return 'Checking Wi-Fi';
      case WifiConnectionStatus.connected:
        return 'Wi-Fi Connected';
      case WifiConnectionStatus.disconnected:
        return 'Wi-Fi Disconnected';
      case WifiConnectionStatus.waitingToRetry:
        return 'Waiting to Reconnect';
      case WifiConnectionStatus.retryStopped:
        return 'Retry Stopped';
    }
  }
}

class WifiStatusIcon extends StatelessWidget {
  const WifiStatusIcon({
    super.key,
    required this.status,
    this.size = 36,
  });

  final WifiConnectionStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case WifiConnectionStatus.checking:
        return Icon(
          Icons.wifi_find,
          size: size,
          color: Colors.blue,
        );
      case WifiConnectionStatus.connected:
        return Icon(
          Icons.wifi,
          size: size,
          color: Colors.green,
        );
      case WifiConnectionStatus.disconnected:
        return Icon(
          Icons.wifi_off,
          size: size,
          color: Colors.red,
        );
      case WifiConnectionStatus.waitingToRetry:
        return Icon(
          Icons.wifi_off,
          size: size,
          color: Colors.orange,
        );
      case WifiConnectionStatus.retryStopped:
        return Icon(
          Icons.error_outline,
          size: size,
          color: Colors.red,
        );
    }
  }
}
