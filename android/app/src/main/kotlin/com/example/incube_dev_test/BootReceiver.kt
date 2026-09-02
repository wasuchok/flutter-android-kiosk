package com.example.incube_dev_test

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
                        intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                it.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                context.startActivity(it)
            }
        }
    }
}
