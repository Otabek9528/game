package com.vegukin.muslim_vegukin

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import com.vegukin.muslim_vegukin.widget.PrayerWidgets
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** Set when a widget opened the app for something; Flutter takes it once. */
    private var launchAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        readLaunchAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readLaunchAction(intent)
    }

    private fun readLaunchAction(intent: Intent?) {
        if (intent?.action == PrayerWidgets.ACTION_REFRESH_LOCATION) launchAction = "refresh_location"
    }

    /** "vegukin/widget": see lib/features/widget/home_widget_bridge.dart. */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vegukin/widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    PrayerWidgets.save(this, call.arguments as String)
                    PrayerWidgets.updateAll(this)
                    result.success(null)
                }
                "exactAlarmsMissing" -> result.success(PrayerWidgets.exactAlarmsMissing(this))
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= 31) {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")),
                        )
                    }
                    result.success(null)
                }
                "takeLaunchAction" -> {
                    result.success(launchAction)
                    launchAction = null
                }
                else -> result.notImplemented()
            }
        }
    }
}
