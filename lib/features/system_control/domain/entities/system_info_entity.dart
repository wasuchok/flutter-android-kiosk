
class SystemInfoEntity {
  final String appVersion;
  final String serialNumber;
  final bool isOnline;
  final bool isKioskActive;

  const SystemInfoEntity({
    this.appVersion = '-',
    this.serialNumber = '-',
    this.isOnline = false,
    this.isKioskActive = false,
  });

  // เพิ่ม method นี้ลงใน class
  SystemInfoEntity copyWith({
    String? appVersion,
    String? serialNumber,
    bool? isOnline,
    bool? isKioskActive,
  }) {
    return SystemInfoEntity(
      appVersion: appVersion ?? this.appVersion,
      serialNumber: serialNumber ?? this.serialNumber,
      isOnline: isOnline ?? this.isOnline,
      isKioskActive: isKioskActive ?? this.isKioskActive,
    );
  }
}
