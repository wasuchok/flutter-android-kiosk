import '../repositories/wifi_repository.dart';

class SetWifiEnabledUseCase {
  final WifiRepository repository;

  SetWifiEnabledUseCase(this.repository);

  Future<bool> call(bool enabled) => repository.setWifiEnabled(enabled);
}
