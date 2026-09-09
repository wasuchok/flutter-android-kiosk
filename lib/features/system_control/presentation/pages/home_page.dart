import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/system_info_entity.dart';
import '../../domain/usecases/get_full_system_info_usecase.dart';
import '../../domain/usecases/system_action_usecases.dart';
import '../../domain/usecases/toggle_kiosk_usecase.dart';
import '../widgets/info_row.dart';
import '../widgets/section_header.dart';
import '../../../wifi_connectivity/domain/entities/retry_policy.dart';
import '../../../wifi_connectivity/domain/usecases/set_wifi_enabled_usecase.dart';
import '../../../wifi_connectivity/presentation/pages/settings_page.dart';
import '../../../wifi_connectivity/presentation/pages/wifi_status_page.dart';
import '../../../wifi_connectivity/presentation/widgets/wifi_connection_card.dart';
import '../../../wifi_connectivity/services/wifi_connection_service.dart';

class HomePage extends StatefulWidget {
  final GetFullSystemInfoUseCase getFullSystemInfoUseCase;
  final ToggleKioskUseCase toggleKioskUseCase;
  final RebootDeviceUseCase rebootDeviceUseCase;
  final CheckUpdateUseCase checkUpdateUseCase;
  final SetWifiEnabledUseCase setWifiEnabledUseCase;
  final WifiConnectionService wifiService;

  HomePage({
    super.key,
    GetFullSystemInfoUseCase? getFullSystemInfoUseCase,
    ToggleKioskUseCase? toggleKioskUseCase,
    RebootDeviceUseCase? rebootDeviceUseCase,
    CheckUpdateUseCase? checkUpdateUseCase,
    SetWifiEnabledUseCase? setWifiEnabledUseCase,
    WifiConnectionService? wifiService,
  })  : getFullSystemInfoUseCase =
            getFullSystemInfoUseCase ?? sl<GetFullSystemInfoUseCase>(),
        toggleKioskUseCase =
            toggleKioskUseCase ?? sl<ToggleKioskUseCase>(),
        rebootDeviceUseCase =
            rebootDeviceUseCase ?? sl<RebootDeviceUseCase>(),
        checkUpdateUseCase =
            checkUpdateUseCase ?? sl<CheckUpdateUseCase>(),
        setWifiEnabledUseCase =
            setWifiEnabledUseCase ?? sl<SetWifiEnabledUseCase>(),
        wifiService =
            wifiService ?? sl<WifiConnectionService>();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SystemInfoEntity _systemInfo = const SystemInfoEntity();
  bool _isLoading = true;
  bool _isTogglingWifi = false;

  Timer? _initialUpdateTimer;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    widget.wifiService.addListener(_onWifiChanged);
    widget.wifiService.start();
    _initData();
    _setupAutoUpdate();
  }

  @override
  void dispose() {
    widget.wifiService.removeListener(_onWifiChanged);
    _initialUpdateTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _onWifiChanged() {
    if (!mounted) return;
    setState(() {
      _systemInfo = _systemInfo.copyWith(isOnline: widget.wifiService.isConnected);
    });
  }

  Future<void> _initData() async {
    final data = await widget.getFullSystemInfoUseCase();

    if (!mounted) return;
    setState(() {
      _systemInfo = data.copyWith(isOnline: widget.wifiService.isConnected);
      _isLoading = false;
    });
  }

  void _setupAutoUpdate() {
    _initialUpdateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) widget.checkUpdateUseCase();
    });

    _updateTimer = Timer.periodic(const Duration(hours: 1), (_) {
      widget.checkUpdateUseCase();
    });
  }

  Future<void> _toggleKiosk(bool enable) async {
    final success = await widget.toggleKioskUseCase(enable);
    if (success && mounted) {
      setState(() {
        _systemInfo = _systemInfo.copyWith(isKioskActive: enable);
      });
    }
  }

  Future<void> _setWifiEnabled(bool enable) async {
    if (_isTogglingWifi) return;
    setState(() => _isTogglingWifi = true);

    final success = await widget.setWifiEnabledUseCase(enable);

    if (!mounted) return;
    setState(() => _isTogglingWifi = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (enable ? 'Wi-Fi enabled' : 'Wi-Fi disabled')
              : 'Failed to ${enable ? 'enable' : 'disable'} Wi-Fi (Device Owner required)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    if (success) {
      if (enable) {
        widget.wifiService.retryNow();
      } else {
        setState(() {
          _systemInfo = _systemInfo.copyWith(isOnline: false);
        });
      }
    }
  }

  Future<void> _openWifiSettings() async {
    final result = await Navigator.push<RetryPolicy>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(currentPolicy: widget.wifiService.retryPolicy),
      ),
    );

    if (result != null) {
      widget.wifiService.setRetryPolicy(result);
    }
  }

  void _openWifiStatusPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WifiStatusPage(wifiService: widget.wifiService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Device System',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.black87),
            tooltip: 'Wi-Fi Status Page',
            onPressed: _openWifiStatusPage,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            tooltip: 'Wi-Fi Retry Settings',
            onPressed: _openWifiSettings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black12, height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black54,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Device Information'),
                  const SizedBox(height: 4),
                  InfoRow(label: 'App Version', value: _systemInfo.appVersion),
                  InfoRow(
                    label: 'Serial Number',
                    value: _systemInfo.serialNumber,
                  ),
                  InfoRow(
                    label: 'Network Status',
                    value: widget.wifiService.isConnected
                        ? 'Connected'
                        : widget.wifiService.statusText,
                  ),
                  InfoRow(
                    label: 'Kiosk Status',
                    value: _systemInfo.isKioskActive ? 'Active' : 'Inactive',
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.black12, height: 1),

                  const SectionHeader(title: 'Wi-Fi Connection'),
                  const SizedBox(height: 4),
                  WifiConnectionCard(
                    service: widget.wifiService,
                    onOpenSettings: _openWifiSettings,
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.black12, height: 1),

                  const SectionHeader(title: 'Controls'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => widget.checkUpdateUseCase(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Check Update',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => widget.rebootDeviceUseCase(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Reboot',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: !_systemInfo.isKioskActive
                              ? () => _toggleKiosk(true)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            disabledForegroundColor: Colors.black26,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Enable Kiosk',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _systemInfo.isKioskActive
                              ? () => _toggleKiosk(false)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            disabledForegroundColor: Colors.black26,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Disable Kiosk',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isTogglingWifi
                              ? null
                              : () => _setWifiEnabled(true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Turn On Wi-Fi',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isTogglingWifi
                              ? null
                              : () => _setWifiEnabled(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Turn Off Wi-Fi',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
