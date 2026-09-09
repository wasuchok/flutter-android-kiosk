import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/datasources/wifi_datasource.dart';
import '../data/repositories/wifi_repository_impl.dart';
import '../domain/entities/retry_policy.dart';
import '../domain/entities/wifi_connection_status.dart';
import '../domain/repositories/wifi_repository.dart';

export '../domain/entities/wifi_connection_status.dart';

class WifiConnectionService extends ChangeNotifier {
  WifiConnectionService({
    WifiRepository? repository,
    Connectivity? connectivity,
    RetryPolicy retryPolicy = const RetryPolicy.untilConnected(),
  })  : _repository = repository ??
            WifiRepositoryImpl(
              dataSource: WifiDataSourceImpl(connectivity: connectivity),
            ),
        _retryPolicy = retryPolicy;

  final WifiRepository _repository;

  StreamSubscription<bool>? _subscription;
  Timer? _retryTimer;
  Timer? _countdownTimer;

  bool _started = false;
  bool _isChecking = false;

  WifiConnectionStatus _status = WifiConnectionStatus.checking;
  String _statusText = 'Initializing network...';

  int _retryIndex = 0;
  int _retryAttempt = 0;
  int _retryCountdown = 0;

  WifiConnectionStatus get status => _status;

  String get statusText => _statusText;

  bool get isConnected => _status == WifiConnectionStatus.connected;

  bool get isChecking => _isChecking;

  int get retryAttempt => _retryAttempt;

  int get retryCountdown => _retryCountdown;

  RetryPolicy _retryPolicy;

  DateTime? _retryStartedAt;

  RetryPolicy get retryPolicy => _retryPolicy;

  /// Retry pattern:
  /// 3 → 3 → 5 → 5 → 10 → 10 → 30 → 30 → 30...
  static const List<Duration> _retryDelays = [
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  bool _hasRetryTimeExpired() {
    if (_retryPolicy.mode == RetryMode.untilConnected) {
      return false;
    }

    final maxDuration = _retryPolicy.maxDuration;

    if (maxDuration == null || _retryStartedAt == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(_retryStartedAt!);

    return elapsed >= maxDuration;
  }

  void setRetryPolicy(RetryPolicy policy) {
    _retryPolicy = policy;
    notifyListeners();
  }

  // ============================================================
  // START
  // ============================================================

  Future<void> start() async {
    if (_started) return;

    _started = true;

    _updateStatus(
      WifiConnectionStatus.checking,
      'Starting network connection...',
    );

    /// Listen for OS network changes.
    _subscription = _repository.wifiConnectionStream.listen(
      _onWifiChanged,
      onError: (Object error) {
        debugPrint('[WiFi] Connectivity listener error: $error');

        _handleDisconnected();
      },
    );

    await checkNow();
  }

  // ============================================================
  // CHECK CONNECTION
  // ============================================================

  Future<void> checkNow() async {
    if (!_started) return;

    /// Prevent multiple checks running at the same time.
    if (_isChecking) return;

    _cancelRetryTimers();

    _isChecking = true;

    _updateStatus(
      WifiConnectionStatus.checking,
      _retryAttempt == 0
          ? 'Checking Wi-Fi connection...'
          : 'Retrying Wi-Fi connection... '
                '(Attempt $_retryAttempt)',
    );

    try {
      final hasWifi = await _repository.checkWifiConnection();

      if (hasWifi) {
        _handleConnected();
      } else {
        _handleDisconnected();
      }
    } catch (error) {
      debugPrint('[WiFi] Connection check failed: $error');

      _handleDisconnected();
    } finally {
      _isChecking = false;
    }
  }

  // ============================================================
  // DEVICE OWNER: ENABLE / DISABLE WI-FI
  // ============================================================

  Future<bool> setWifiEnabled(bool enabled) async {
    final success = await _repository.setWifiEnabled(enabled);
    if (success) {
      if (enabled) {
        await checkNow();
      } else {
        _handleDisconnected();
      }
    }
    return success;
  }

  // ============================================================
  // OS CONNECTIVITY CHANGE
  // ============================================================

  void _onWifiChanged(bool hasWifi) {
    if (!_started) return;

    debugPrint('[WiFi] Network changed: hasWifi=$hasWifi');

    if (hasWifi) {
      _handleConnected();
    } else {
      _handleDisconnected();
    }
  }

  // ============================================================
  // CONNECTED
  // ============================================================

  void _handleConnected() {
    _cancelRetryTimers();
    //reset the retry time
    _retryStartedAt = null;

    _retryIndex = 0;
    _retryAttempt = 0;
    _retryCountdown = 0;

    _updateStatus(WifiConnectionStatus.connected, 'Wi-Fi connected');

    debugPrint('[WiFi] Connected');
  }

  // ============================================================
  // DISCONNECTED
  // ============================================================

  void _handleDisconnected() {
    if (!_started) return;

    _retryStartedAt ??= DateTime.now();

    _updateStatus(WifiConnectionStatus.disconnected, 'Wi-Fi disconnected');

    _scheduleRetry();
  }

  // ============================================================
  // RETRY
  // ============================================================

  void _scheduleRetry() {
    if (!_started) return;

    /// Already waiting for retry.
    if (_retryTimer?.isActive == true) {
      return;
    }

    if (_hasRetryTimeExpired()) {
      _cancelRetryTimers();

      _updateStatus(
        WifiConnectionStatus.retryStopped,
        'Unable to connect to Wi-Fi. Maximum retry duration reached.',
      );

      return;
    }

    final index = _retryIndex.clamp(0, _retryDelays.length - 1);

    final delay = _retryDelays[index];

    _retryCountdown = delay.inSeconds;

    _updateStatus(
      WifiConnectionStatus.waitingToRetry,
      'Wi-Fi unavailable. '
      'Retrying in $_retryCountdown seconds...',
    );

    /// Countdown shown on screen.
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_started) {
        timer.cancel();
        return;
      }

      if (_retryCountdown > 1) {
        _retryCountdown--;

        _updateStatus(
          WifiConnectionStatus.waitingToRetry,
          'Wi-Fi unavailable. '
          'Retrying in $_retryCountdown seconds...',
        );
      } else {
        timer.cancel();
      }
    });

    /// Actual retry timer.
    _retryTimer = Timer(delay, () async {
      _retryTimer = null;
      _countdownTimer?.cancel();

      if (!_started) return;

      _retryAttempt++;

      /// Move through:
      ///
      /// 3 → 3 → 5 → 5 → 10 → 10 → 30
      ///
      /// Then remain at 30.
      if (_retryIndex < _retryDelays.length - 1) {
        _retryIndex++;
      }

      await checkNow();
    });
  }

  // ============================================================
  // MANUAL RETRY
  // ============================================================

  Future<void> retryNow() async {
    if (!_started) return;

    // Stop previous retry timers.
    _cancelRetryTimers();

    // Start a completely new retry session.
    _retryStartedAt = DateTime.now();

    _retryIndex = 0;
    _retryAttempt = 0;
    _retryCountdown = 0;

    _updateStatus(
      WifiConnectionStatus.checking,
      'Retrying Wi-Fi connection...',
    );

    await checkNow();
  }

  // ============================================================
  // UPDATE UI STATUS
  // ============================================================

  void _updateStatus(WifiConnectionStatus status, String text) {
    _status = status;
    _statusText = text;

    notifyListeners();
  }

  // ============================================================
  // CANCEL TIMERS
  // ============================================================

  void _cancelRetryTimers() {
    _retryTimer?.cancel();
    _retryTimer = null;

    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ============================================================
  // STOP
  // ============================================================

  void stop() {
    _started = false;

    _cancelRetryTimers();

    _subscription?.cancel();
    _subscription = null;

    _isChecking = false;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
