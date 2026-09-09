import '../repositories/wifi_repository.dart';

class CheckWifiConnectionUseCase {
  final WifiRepository repository;

  CheckWifiConnectionUseCase(this.repository);

  Future<bool> call() => repository.checkWifiConnection();
}
