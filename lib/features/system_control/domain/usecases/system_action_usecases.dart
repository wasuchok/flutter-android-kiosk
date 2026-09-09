import 'package:incube_dev_test/features/system_control/domain/repositories/system_repository.dart';

class RebootDeviceUseCase {
  final SystemRepository repository;
  RebootDeviceUseCase(this.repository);
  Future<void> call() => repository.rebootDevice();
}

class CheckUpdateUseCase {
  final SystemRepository repository;
  CheckUpdateUseCase(this.repository);
  Future<void> call() => repository.checkForUpdate();
}
