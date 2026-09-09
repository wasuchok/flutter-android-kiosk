import '../repositories/wifi_repository.dart';

class ListenWifiConnectionUseCase {
  final WifiRepository repository;

  ListenWifiConnectionUseCase(this.repository);

  Stream<bool> call() => repository.wifiConnectionStream;
}
