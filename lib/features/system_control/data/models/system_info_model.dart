import '../../domain/entities/system_info_entity.dart';

class SystemInfoModel extends SystemInfoEntity {
  const SystemInfoModel({
    super.appVersion,
    super.serialNumber,
    super.isOnline,
    super.isKioskActive,
  });

  factory SystemInfoModel.fromDataSource({
    required String appVersion,
    required String serialNumber,
    required bool isOnline,
    required bool isKioskActive,
  }) {
    return SystemInfoModel(
      appVersion: appVersion,
      serialNumber: serialNumber,
      isOnline: isOnline,
      isKioskActive: isKioskActive,
    );
  }

  SystemInfoEntity toEntity() {
    return SystemInfoEntity(
      appVersion: appVersion,
      serialNumber: serialNumber,
      isOnline: isOnline,
      isKioskActive: isKioskActive,
    );
  }
}
