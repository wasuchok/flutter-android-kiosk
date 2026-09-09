import 'package:flutter_test/flutter_test.dart';
import 'package:incube_dev_test/features/system_control/domain/repositories/system_repository.dart';
import 'package:incube_dev_test/features/system_control/domain/usecases/get_full_system_info_usecase.dart';
import 'package:incube_dev_test/features/system_control/domain/usecases/toggle_kiosk_usecase.dart';

class FakeSystemRepository implements SystemRepository {
  bool isOnline = true;
  String appVersion = '1.0.0 (1)';
  String serial = 'TEST1234';
  bool _kioskActive = false;

  @override
  bool get isKioskActive => _kioskActive;

  @override
  Future<bool> checkInitialConnectivity() async => isOnline;

  @override
  Future<String> getAppVersion() async => appVersion;

  @override
  Future<String> getHardwareSerial() async => serial;

  @override
  Stream<bool> get internetConnectionStream => Stream.value(isOnline);

  @override
  Future<bool> setKioskMode(bool enable) async {
    _kioskActive = enable;
    return true;
  }

  @override
  Future<void> rebootDevice() async {}

  @override
  Future<void> checkForUpdate() async {}
}

void main() {
  group('System Control Use Cases Tests', () {
    test('GetFullSystemInfoUseCase returns system info entity correctly without mutating kiosk mode', () async {
      final fakeRepo = FakeSystemRepository();
      final useCase = GetFullSystemInfoUseCase(fakeRepo);

      final result = await useCase();

      expect(result.appVersion, '1.0.0 (1)');
      expect(result.serialNumber, 'TEST1234');
      expect(result.isOnline, isTrue);
      expect(result.isKioskActive, isFalse);
      expect(fakeRepo.isKioskActive, isFalse);
    });

    test('ToggleKioskUseCase toggles kiosk mode successfully', () async {
      final fakeRepo = FakeSystemRepository();
      final useCase = ToggleKioskUseCase(fakeRepo);

      final success = await useCase(true);

      expect(success, isTrue);
      expect(fakeRepo.isKioskActive, isTrue);
    });
  });
}
