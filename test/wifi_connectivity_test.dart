import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incube_dev_test/features/wifi_connectivity/domain/entities/wifi_network.dart';
import 'package:incube_dev_test/features/wifi_connectivity/domain/repositories/wifi_repository.dart';
import 'package:incube_dev_test/features/wifi_connectivity/domain/usecases/connect_wifi_usecase.dart';
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

  @override
  Future<bool> connectWifi(WifiNetwork network) async => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    testWidgets('clears wifi credentials when Clear button is tapped', (tester) async {
      SharedPreferences.setMockInitialValues({
        'wifi_ssid': 'SavedOfficeWiFi',
        'wifi_username': 'employee1',
        'wifi_password': 'securePass',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(currentPolicy: RetryPolicy.untilConnected()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SavedOfficeWiFi'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('SavedOfficeWiFi'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('wifi_ssid'), isNull);
      expect(prefs.getString('wifi_username'), isNull);
      expect(prefs.getString('wifi_password'), isNull);
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

  group('ConnectWifiUseCase Tests', () {
    test('calls repository connectWifi', () async {
      final repo = _AlwaysConnectedWifiRepository();
      final useCase = ConnectWifiUseCase(repo);

      final success = await useCase(
        const WifiNetwork(ssid: 'Office-WiFi', password: 'secretpassword'),
      );
      expect(success, isTrue);
    });

    test('throws ArgumentError on empty ssid', () async {
      final repo = _AlwaysConnectedWifiRepository();
      final useCase = ConnectWifiUseCase(repo);

      expect(
        () => useCase(const WifiNetwork(ssid: '   ')),
        throwsArgumentError,
      );
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

    testWidgets('renders wifi input fields and connect button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(currentPolicy: RetryPolicy.untilConnected()),
        ),
      );

      expect(find.text('Wi-Fi Configuration'), findsOneWidget);
      expect(find.text('Wi-Fi SSID'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Connect Wi-Fi'), findsOneWidget);
    });

    testWidgets('loads saved wifi credentials from SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'wifi_ssid': 'SavedOfficeWiFi',
        'wifi_username': 'employee1',
        'wifi_password': 'securePass',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(currentPolicy: RetryPolicy.untilConnected()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SavedOfficeWiFi'), findsOneWidget);
      expect(find.text('employee1'), findsOneWidget);
      expect(find.text('securePass'), findsOneWidget);
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
