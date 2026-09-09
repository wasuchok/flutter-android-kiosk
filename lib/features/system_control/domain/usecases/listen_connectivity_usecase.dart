import 'package:incube_dev_test/features/system_control/domain/repositories/system_repository.dart';

class ListenConnectivityUseCase {
  final SystemRepository repository;

  ListenConnectivityUseCase(this.repository);

  Stream<bool> call() => repository.internetConnectionStream;
}
