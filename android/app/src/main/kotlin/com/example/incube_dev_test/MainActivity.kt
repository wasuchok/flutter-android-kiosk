package com.example.incube_dev_test

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiEnterpriseConfig
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiNetworkSpecifier
import android.provider.Settings
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val HARDWARE_CHANNEL = "com.example.incube_dev_test/hardware"
    private val KIOSK_CHANNEL = "com.example.incube_dev_test/kiosk"
    private val POWER_CHANNEL = "com.example.incube_dev_test/power"
    private val UPDATE_CHANNEL = "com.example.incube_dev_test/update"
    private val WIFI_CHANNEL = "com.example.incube_dev_test/wifi"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Hardware Serial Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HARDWARE_CHANNEL)
                .setMethodCallHandler { call, result ->
                    if (call.method == "getHardwareSerial") {
                        val serial = getDeviceSerial()
                        if (serial.isNotEmpty() && serial != "UNKNOWN" && serial != "unknown") {
                            result.success(serial)
                        } else {
                            result.error("ERROR", "Unable to fetch serial number", null)
                        }
                    } else {
                        result.notImplemented()
                    }
                }

        // Kiosk Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL)
                .setMethodCallHandler { call, result ->
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val adminComponent = ComponentName(this, MyDeviceAdminReceiver::class.java)

                    when (call.method) {
                        "startKioskMode" -> {
                            try {
                                if (dpm.isDeviceOwnerApp(packageName)) {
                                    dpm.setLockTaskPackages(adminComponent, arrayOf(packageName))
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                        dpm.setLockTaskFeatures(
                                                adminComponent,
                                                DevicePolicyManager.LOCK_TASK_FEATURE_NONE
                                        )
                                    }
                                }
                                startLockTask()
                                result.success(true)
                            } catch (e: Exception) {
                                result.error(
                                        "ERROR",
                                        "Failed to start Kiosk Mode: ${e.message}",
                                        null
                                )
                            }
                        }
                        "stopKioskMode" -> {
                            try {
                                stopLockTask()
                                result.success(true)
                            } catch (e: Exception) {
                                result.error(
                                        "ERROR",
                                        "Failed to stop Kiosk Mode: ${e.message}",
                                        null
                                )
                            }
                        }
                        else -> result.notImplemented()
                    }
                }

        // Power Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POWER_CHANNEL)
                .setMethodCallHandler { call, result ->
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val adminComponent = ComponentName(this, MyDeviceAdminReceiver::class.java)

                    when (call.method) {
                        "rebootDevice" -> {
                            try {
                                if (dpm.isDeviceOwnerApp(packageName)) {
                                    dpm.reboot(adminComponent)
                                    result.success(true)
                                } else {
                                    result.error("ERROR", "App is not Device Owner", null)
                                }
                            } catch (e: Exception) {
                                result.error("ERROR", "Failed to reboot: ${e.message}", null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }

        // Update Channel (Silent Install)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
                .setMethodCallHandler { call, result ->
                    if (call.method == "installApk") {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            val file = File(filePath)
                            if (file.exists()) {
                                val success = installApkSilently(this, file)
                                result.success(success)
                            } else {
                                result.error("FILE_NOT_FOUND", "APK file does not exist", null)
                            }
                        } else {
                            result.error("INVALID_PATH", "File path is null", null)
                        }
                    } else {
                        result.notImplemented()
                    }
                }

        // Wi-Fi Channel (Device Owner control)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIFI_CHANNEL)
                .setMethodCallHandler { call, result ->
                    val wifiManager =
                            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

                    when (call.method) {
                        "openWifiSettings" -> {
                            try {
                                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    Intent(Settings.Panel.ACTION_WIFI)
                                } else {
                                    Intent(Settings.ACTION_WIFI_SETTINGS)
                                }
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                try {
                                    val fallbackIntent = Intent(Settings.ACTION_WIFI_SETTINGS)
                                    fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(fallbackIntent)
                                    result.success(true)
                                } catch (e2: Exception) {
                                    result.error("ERROR", "Failed to open Wi-Fi settings: ${e2.message}", null)
                                }
                            }
                        }
                        "connectWifi" -> {
                            val ssid = call.argument<String>("ssid") ?: ""
                            val password = call.argument<String>("password") ?: ""
                            val username = call.argument<String>("username") ?: ""

                            try {
                                val success = connectToWifi(wifiManager, ssid, password, username)
                                result.success(success)
                            } catch (e: Exception) {
                                result.error("WIFI_CONNECT_ERROR", e.message, null)
                            }
                        }
                        "disconnectWifi" -> {
                            try {
                                disconnectWifi(wifiManager)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("ERROR", "Failed to disconnect Wi-Fi: ${e.message}", null)
                            }
                        }
                        "setWifiEnabled" -> {
                            val enable = call.argument<Boolean>("enable") ?: false
                            try {
                                @Suppress("DEPRECATION")
                                val success = wifiManager.setWifiEnabled(enable)
                                result.success(success)
                            } catch (e: Exception) {
                                result.error(
                                        "ERROR",
                                        "Failed to set Wi-Fi state: ${e.message}",
                                        null
                                )
                            }
                        }
                        "isWifiEnabled" -> {
                            try {
                                val isEnabled = wifiManager.isWifiEnabled
                                result.success(isEnabled)
                            } catch (e: Exception) {
                                result.error(
                                        "ERROR",
                                        "Failed to get Wi-Fi state: ${e.message}",
                                        null
                                )
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
    }

    private fun installApkSilently(context: Context, apkFile: File): Boolean {
        val packageInstaller = context.packageManager.packageInstaller
        val params =
                PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)

        var session: PackageInstaller.Session? = null
        return try {
            val sessionId = packageInstaller.createSession(params)
            session = packageInstaller.openSession(sessionId)

            FileInputStream(apkFile).use { inputStream ->
                session.openWrite("package_install", 0, apkFile.length()).use { outputStream ->
                    inputStream.copyTo(outputStream)
                    session.fsync(outputStream)
                }
            }

            val intent = Intent(context, InstallResultReceiver::class.java)
            val flags =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }

            val pendingIntent = PendingIntent.getBroadcast(context, sessionId, intent, flags)

            session.commit(pendingIntent.intentSender)
            session.close()
            true
        } catch (e: Exception) {
            session?.abandon()
            false
        }
    }

    @SuppressLint("HardwareIds", "MissingPermission")
    private fun getDeviceSerial(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val serial = Build.getSerial()
                if (serial.isNotEmpty() && serial != "UNKNOWN" && serial != "unknown") {
                    return serial
                }
            } catch (e: SecurityException) {
                // SecurityException
            }
        }

        try {
            val c = Class.forName("android.os.SystemProperties")
            val get = c.getMethod("get", String::class.java)
            val serial = get.invoke(c, "ro.serialno") as String
            if (serial.isNotEmpty() && serial != "UNKNOWN") {
                return serial
            }
        } catch (e: Exception) {
            // Ignored
        }

        @Suppress("DEPRECATION") return Build.SERIAL ?: "UNKNOWN"
    }

    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    private fun connectToWifi(
            wifiManager: WifiManager,
            ssid: String,
            pass: String,
            username: String = ""
    ): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val isDeviceOwner = dpm.isDeviceOwnerApp(packageName)

        @Suppress("DEPRECATION")
        if (!wifiManager.isWifiEnabled) {
            try {
                wifiManager.isWifiEnabled = true
            } catch (_: Exception) {}
        }

        if (isDeviceOwner || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            val wifiConfig =
                    WifiConfiguration().apply {
                        this.SSID = "\"$ssid\""
                        if (username.isNotEmpty()) {
                            this.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_EAP)
                            this.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.IEEE8021X)
                            this.enterpriseConfig =
                                    WifiEnterpriseConfig().apply {
                                        identity = username
                                        password = pass
                                        eapMethod = WifiEnterpriseConfig.Eap.PEAP
                                        phase2Method = WifiEnterpriseConfig.Phase2.MSCHAPV2
                                    }
                        } else if (pass.isNotEmpty()) {
                            this.preSharedKey = "\"$pass\""
                        } else {
                            this.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
                        }
                    }

            @Suppress("DEPRECATION")
            var netId = wifiManager.addNetwork(wifiConfig)
            if (netId == -1) {
                @Suppress("DEPRECATION")
                val existing =
                        wifiManager.configuredNetworks?.firstOrNull { it.SSID == "\"$ssid\"" }
                if (existing != null) {
                    wifiConfig.networkId = existing.networkId
                    @Suppress("DEPRECATION")
                    netId = wifiManager.updateNetwork(wifiConfig)
                    if (netId == -1) {
                        netId = existing.networkId
                    }
                }
            }

            if (netId != -1) {
                @Suppress("DEPRECATION")
                wifiManager.disconnect()
                @Suppress("DEPRECATION")
                val enabled = wifiManager.enableNetwork(netId, true)
                @Suppress("DEPRECATION")
                wifiManager.reconnect()

                if (enabled) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        registerSuggestion(wifiManager, ssid, pass, username, isDeviceOwner)
                    }
                    return true
                }
            }
        }

        @Suppress("DEPRECATION")
        val info = wifiManager.connectionInfo
        if (info != null && info.ssid == "\"$ssid\"" && info.networkId != -1) {
            return true
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            registerSuggestion(wifiManager, ssid, pass, username, isDeviceOwner)
            if (!isDeviceOwner) {
                connectWithSpecifier(ssid, pass, username)
            }
            return true
        }

        return false
    }

    private fun registerSuggestion(
            wifiManager: WifiManager,
            ssid: String,
            pass: String,
            username: String,
            isDeviceOwner: Boolean
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val suggestionBuilder =
                    WifiNetworkSuggestion.Builder()
                            .setSsid(ssid)
                            .setIsAppInteractionRequired(!isDeviceOwner)

            if (username.isNotEmpty()) {
                val enterpriseConfig =
                        WifiEnterpriseConfig().apply {
                            identity = username
                            password = pass
                            eapMethod = WifiEnterpriseConfig.Eap.PEAP
                            phase2Method = WifiEnterpriseConfig.Phase2.MSCHAPV2
                        }
                suggestionBuilder.setWpa2EnterpriseConfig(enterpriseConfig)
            } else if (pass.isNotEmpty()) {
                suggestionBuilder.setWpa2Passphrase(pass)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    val currentSuggestions = wifiManager.networkSuggestions
                    if (currentSuggestions.isNotEmpty()) {
                        wifiManager.removeNetworkSuggestions(currentSuggestions)
                    }
                } catch (_: Exception) {}
            }

            val suggestions = listOf(suggestionBuilder.build())
            wifiManager.addNetworkSuggestions(suggestions)
        }
    }

    private fun connectWithSpecifier(ssid: String, pass: String, username: String = "") {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            networkCallback?.let {
                try {
                    cm.unregisterNetworkCallback(it)
                } catch (_: Exception) {}
            }

            val specifierBuilder = WifiNetworkSpecifier.Builder().setSsid(ssid)
            if (username.isNotEmpty()) {
                val enterpriseConfig =
                        WifiEnterpriseConfig().apply {
                            identity = username
                            password = pass
                            eapMethod = WifiEnterpriseConfig.Eap.PEAP
                            phase2Method = WifiEnterpriseConfig.Phase2.MSCHAPV2
                        }
                specifierBuilder.setWpa2EnterpriseConfig(enterpriseConfig)
            } else if (pass.isNotEmpty()) {
                specifierBuilder.setWpa2Passphrase(pass)
            }

            val request =
                    NetworkRequest.Builder()
                            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                            .setNetworkSpecifier(specifierBuilder.build())
                            .build()

            val callback =
                    object : ConnectivityManager.NetworkCallback() {
                        override fun onAvailable(network: Network) {
                            super.onAvailable(network)
                            cm.bindProcessToNetwork(network)
                        }

                        override fun onLost(network: Network) {
                            super.onLost(network)
                            try {
                                cm.bindProcessToNetwork(null)
                            } catch (_: Exception) {}
                        }

                        override fun onUnavailable() {
                            super.onUnavailable()
                            try {
                                cm.bindProcessToNetwork(null)
                            } catch (_: Exception) {}
                        }
                    }
            networkCallback = callback
            cm.requestNetwork(request, callback)
        }
    }

    private fun disconnectWifi(wifiManager: WifiManager) {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        networkCallback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (_: Exception) {}
            networkCallback = null
        }
        try {
            cm.bindProcessToNetwork(null)
        } catch (_: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val suggestions = wifiManager.networkSuggestions
                if (suggestions.isNotEmpty()) {
                    wifiManager.removeNetworkSuggestions(suggestions)
                }
            } catch (_: Exception) {}
        }
        @Suppress("DEPRECATION")
        try {
            wifiManager.disconnect()
        } catch (_: Exception) {}
    }
}
