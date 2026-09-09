import '../entities/system_info_entity.dart';
import '../repositories/system_repository.dart';

class GetFullSystemInfoUseCase {
  final SystemRepository repository;

  GetFullSystemInfoUseCase(this.repository);

  Future<SystemInfoEntity> call() async {
    final isOnline = await repository.checkInitialConnectivity();
    final version = await repository.getAppVersion();
    final serial = await repository.getHardwareSerial();
    final isKiosk = repository.isKioskActive;

    return SystemInfoEntity(
      appVersion: version,
      serialNumber: serial,
      isOnline: isOnline,
      isKioskActive: isKiosk,
    );
  }
}
