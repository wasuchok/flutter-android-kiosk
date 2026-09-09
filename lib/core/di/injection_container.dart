import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../features/system_control/data/datasources/connectivity_datasource.dart';
import '../../features/system_control/data/datasources/device_local_datasource.dart';
import '../../features/system_control/data/datasources/platform_channel_datasource.dart';
import '../../features/system_control/data/datasources/update_datasource.dart';
import '../../features/system_control/data/repositories/system_repository_impl.dart';
import '../../features/system_control/domain/repositories/system_repository.dart';
import '../../features/system_control/domain/usecases/get_full_system_info_usecase.dart';
import '../../features/system_control/domain/usecases/listen_connectivity_usecase.dart';
import '../../features/system_control/domain/usecases/system_action_usecases.dart';
import '../../features/system_control/domain/usecases/toggle_kiosk_usecase.dart';
import '../../features/wifi_connectivity/data/datasources/wifi_datasource.dart';
import '../../features/wifi_connectivity/data/repositories/wifi_repository_impl.dart';
import '../../features/wifi_connectivity/domain/repositories/wifi_repository.dart';
import '../../features/wifi_connectivity/domain/usecases/check_wifi_connection_usecase.dart';
import '../../features/wifi_connectivity/domain/usecases/listen_wifi_connection_usecase.dart';
import '../../features/wifi_connectivity/domain/usecases/set_wifi_enabled_usecase.dart';
import '../../features/wifi_connectivity/services/wifi_connection_service.dart';

final sl = GetIt.instance;

Future<void> initLocator() async {
  // External / 3rd Party
  if (!sl.isRegistered<Connectivity>()) {
    sl.registerLazySingleton(() => Connectivity());
  }

  // Data Sources - System Control
  if (!sl.isRegistered<PlatformChannelDataSource>()) {
    sl.registerLazySingleton<PlatformChannelDataSource>(
      () => PlatformChannelDataSourceImpl(),
    );
  }
  if (!sl.isRegistered<DeviceLocalDataSource>()) {
    sl.registerLazySingleton<DeviceLocalDataSource>(
      () => DeviceLocalDataSourceImpl(),
    );
  }
  if (!sl.isRegistered<ConnectivityDataSource>()) {
    sl.registerLazySingleton<ConnectivityDataSource>(
      () => ConnectivityDataSourceImpl(connectivity: sl()),
    );
  }
  if (!sl.isRegistered<UpdateDataSource>()) {
    sl.registerLazySingleton<UpdateDataSource>(
      () => UpdateRemoteDataSourceImpl(),
    );
  }

  // Data Sources - WiFi Connectivity
  if (!sl.isRegistered<WifiDataSource>()) {
    sl.registerLazySingleton<WifiDataSource>(
      () => WifiDataSourceImpl(connectivity: sl()),
    );
  }

  // Repositories - System Control
  if (!sl.isRegistered<SystemRepository>()) {
    sl.registerLazySingleton<SystemRepository>(
      () => SystemRepositoryImpl(
        localDataSource: sl(),
        platformSource: sl(),
        connectivityDataSource: sl(),
        updateDataSource: sl(),
      ),
    );
  }

  // Repositories - WiFi Connectivity
  if (!sl.isRegistered<WifiRepository>()) {
    sl.registerLazySingleton<WifiRepository>(
      () => WifiRepositoryImpl(dataSource: sl()),
    );
  }

  // Use Cases - System Control
  if (!sl.isRegistered<GetFullSystemInfoUseCase>()) {
    sl.registerLazySingleton(() => GetFullSystemInfoUseCase(sl()));
  }
  if (!sl.isRegistered<ListenConnectivityUseCase>()) {
    sl.registerLazySingleton(() => ListenConnectivityUseCase(sl()));
  }
  if (!sl.isRegistered<ToggleKioskUseCase>()) {
    sl.registerLazySingleton(() => ToggleKioskUseCase(sl()));
  }
  if (!sl.isRegistered<RebootDeviceUseCase>()) {
    sl.registerLazySingleton(() => RebootDeviceUseCase(sl()));
  }
  if (!sl.isRegistered<CheckUpdateUseCase>()) {
    sl.registerLazySingleton(() => CheckUpdateUseCase(sl()));
  }

  // Use Cases - WiFi Connectivity
  if (!sl.isRegistered<CheckWifiConnectionUseCase>()) {
    sl.registerLazySingleton(() => CheckWifiConnectionUseCase(sl()));
  }
  if (!sl.isRegistered<ListenWifiConnectionUseCase>()) {
    sl.registerLazySingleton(() => ListenWifiConnectionUseCase(sl()));
  }
  if (!sl.isRegistered<SetWifiEnabledUseCase>()) {
    sl.registerLazySingleton(() => SetWifiEnabledUseCase(sl()));
  }

  // Presentation Services / Controllers
  if (!sl.isRegistered<WifiConnectionService>()) {
    sl.registerLazySingleton<WifiConnectionService>(
      () => WifiConnectionService(repository: sl()),
    );
  }
}
