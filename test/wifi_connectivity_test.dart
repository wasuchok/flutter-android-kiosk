import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incube_dev_test/features/wifi_connectivity/domain/repositories/wifi_repository.dart';
import 'package:incube_dev_test/features/wifi_connectivity/domain/usecases/set_wifi_enabled_usecase.dart';
import 'package:incube_dev_test/features/wifi_connectivity/models/retry_policy.dart';
import 'package:incube_dev_test/features/wifi_connectivity/presentation/pages/settings_page.dart';
import 'package:incube_dev_test/features/wifi_connectivity/presentation/widgets/wifi_connection_card.dart';
import 'package:incube_dev_test/features/wifi_connectivity/services/wifi_connection_service.dart';

class _AlwaysConnectedWifiRepository implements WifiRepository {
  bool _wifiEnabled = true;

  @override
  Future<bool> checkWifiConnection() async => true;

  @override
  Stream<bool> get wifiConnectionStream => Stream.value(true);

  @override
  Future<bool> setWifiEnabled(bool enabled) async {
    _wifiEnabled = enabled;
    return true;
  }

  @override
  Future<bool> isWifiEnabled() async => _wifiEnabled;
}

void main() {
  group('RetryPolicy Tests', () {
    test('RetryPolicy.untilConnected defaults to untilConnected mode', () {
      const policy = RetryPolicy.untilConnected();
      expect(policy.mode, RetryMode.untilConnected);
      expect(policy.maxDuration, isNull);
    });

    test('RetryPolicy.maxDuration sets duration correctly', () {
      const duration = Duration(minutes: 5);
      const policy = RetryPolicy.maxDuration(duration);
      expect(policy.mode, RetryMode.maxDuration);
      expect(policy.maxDuration, duration);
    });
  });

  group('WifiConnectionService Tests', () {
    test('initial status is checking', () {
      final service = WifiConnectionService();
      expect(service.status, WifiConnectionStatus.checking);
      expect(service.isConnected, isFalse);
      expect(service.retryAttempt, 0);
      expect(service.retryCountdown, 0);
    });

    test('setRetryPolicy updates retry policy', () {
      final service = WifiConnectionService();
      expect(service.retryPolicy.mode, RetryMode.untilConnected);

      const newPolicy = RetryPolicy.maxDuration(Duration(minutes: 15));
      service.setRetryPolicy(newPolicy);
      expect(service.retryPolicy.mode, RetryMode.maxDuration);
      expect(service.retryPolicy.maxDuration, const Duration(minutes: 15));
    });

    test('setWifiEnabled calls repository and updates state', () async {
      final repo = _AlwaysConnectedWifiRepository();
      final service = WifiConnectionService(repository: repo);

      final result = await service.setWifiEnabled(false);
      expect(result, isTrue);
      expect(await repo.isWifiEnabled(), isFalse);
    });
  });

  group('SetWifiEnabledUseCase Tests', () {
    test('calls repository setWifiEnabled', () async {
      final repo = _AlwaysConnectedWifiRepository();
      final useCase = SetWifiEnabledUseCase(repo);

      final success = await useCase(false);
      expect(success, isTrue);
      expect(await repo.isWifiEnabled(), isFalse);
    });
  });

  group('SettingsPage Widget Tests', () {
    testWidgets('renders retry options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(currentPolicy: RetryPolicy.untilConnected()),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Retry until connected'), findsOneWidget);
      expect(find.text('Stop retrying after'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('WifiConnectionCard Widget Tests', () {
    testWidgets('renders connection status card', (tester) async {
      final service = WifiConnectionService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiConnectionCard(service: service),
          ),
        ),
      );

      expect(find.text('Checking Wi-Fi'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders compact card when connected', (tester) async {
      final service = WifiConnectionService(
        repository: _AlwaysConnectedWifiRepository(),
      );
      await service.start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiConnectionCard(service: service),
          ),
        ),
      );

      expect(find.text('Wi-Fi Connected'), findsOneWidget);
      expect(find.text('Wi-Fi connected'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
