package com.example.incube_dev_test

import android.annotation.SuppressLint
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val HARDWARE_CHANNEL = "com.example.incube_dev_test/hardware"
    private val KIOSK_CHANNEL = "com.example.incube_dev_test/kiosk"

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

        //  Kiosk Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL)
                .setMethodCallHandler { call, result ->
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

                    val adminComponent =
                            ComponentName(this, "com.example.incube_dev_test.MyDeviceAdminReceiver")

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

        MethodChannel(
                        flutterEngine.dartExecutor.binaryMessenger,
                        "com.example.incube_dev_test/power"
                )
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
}
