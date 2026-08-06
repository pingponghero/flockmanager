package com.tyndallstudios.flockmanager

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val exactAlarmChannel = "com.tyndallstudios.flockmanager/exact_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exactAlarmChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openExactAlarmSettings" -> result.success(openExactAlarmSettings())
                    "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
                    else -> result.notImplemented()
                }
            }
    }

    // Whether the app can schedule exact alarms. Below Android 12 exact alarms
    // are always allowed; from Android 12 this reflects the SCHEDULE_EXACT_ALARM
    // special access the user grants on the "Alarms & reminders" page.
    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

    // Open the system "Alarms & reminders" special-access page so the user can
    // grant SCHEDULE_EXACT_ALARM. The awesome_notifications permission dialog
    // does not open this page when notifications are already allowed, so we
    // launch the settings intent directly. Falls back to the app details page.
    private fun openExactAlarmSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            true
        } catch (e: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                )
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
