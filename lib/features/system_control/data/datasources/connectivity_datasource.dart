import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityDataSource {
  Future<bool> checkConnectivity();
  Stream<bool> get onConnectivityChanged;
}

class ConnectivityDataSourceImpl implements ConnectivityDataSource {
  final Connectivity _connectivity;

  ConnectivityDataSourceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    );
  }
}
