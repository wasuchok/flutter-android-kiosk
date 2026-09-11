import '../entities/wifi_network.dart';
import '../repositories/wifi_repository.dart';

class ConnectWifiUseCase {
  final WifiRepository repository;

  ConnectWifiUseCase(this.repository);

  Future<bool> call(WifiNetwork network) => execute(network);

  Future<bool> execute(WifiNetwork network) async {
    if (network.ssid.trim().isEmpty) {
      throw ArgumentError('SSID cannot be empty');
    }
    return await repository.connectWifi(network);
  }
}
