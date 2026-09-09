import 'package:incube_dev_test/features/system_control/domain/repositories/system_repository.dart';

class ToggleKioskUseCase {
  final SystemRepository repository;

  ToggleKioskUseCase(this.repository);

  Future<bool> call(bool enable) => repository.setKioskMode(enable);
}
