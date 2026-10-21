package com.vegukin.muslim_vegukin

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import com.vegukin.muslim_vegukin.qibla.QiblaCamera
import com.vegukin.muslim_vegukin.qibla.QiblaCompass
import com.vegukin.muslim_vegukin.reminders.PrayerReminders
import com.vegukin.muslim_vegukin.widget.PrayerWidgets
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var camera: QiblaCamera? = null

    /** Set when a widget or a reminder opened the app; Flutter takes it once. */
    private var launchAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertsChannel()
        readLaunchAction(intent)
    }

    /**
     * Push notifications from the server (watched places, areas, HiKorea) go
     * to their own channel, named in the phone's language, so they can be
     * muted apart from prayer reminders. The manifest points Firebase at it.
     */
    private fun createAlertsChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel("alerts", getString(R.string.alerts_channel), NotificationManager.IMPORTANCE_HIGH),
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readLaunchAction(intent)
    }

    private fun readLaunchAction(intent: Intent?) {
        when (intent?.action) {
            PrayerWidgets.ACTION_REFRESH_LOCATION -> launchAction = "refresh_location"
            PrayerReminders.ACTION_OPEN_PRAYERS -> launchAction = "open_prayers"
        }
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
                "exactAlarmsMissing" -> result.success(!PrayerWidgets.canAlarmExactly(this))
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
        // The Qibla page: lib/features/qibla/qibla_sensors.dart.
        val compass = QiblaCompass(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "vegukin/compass").setStreamHandler(compass)
        val qiblaCamera = QiblaCamera(this, flutterEngine.renderer).also { camera = it }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vegukin/qibla").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasCompass" -> result.success(compass.hasCompass())
                "keepScreenOn" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                "startCamera" -> qiblaCamera.start(result)
                "stopCamera" -> {
                    qiblaCamera.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        /** "vegukin/reminders": see lib/features/reminders/reminder_controller.dart. */
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vegukin/reminders").setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    PrayerReminders.save(this, call.arguments as String)
                    result.success(null)
                }
                "preview" -> {
                    PrayerReminders.preview(this, call.arguments as String)
                    result.success(null)
                }
                "notificationsAllowed" -> result.success(PrayerReminders.notificationsAllowed(this))
                "openNotificationSettings" -> {
                    startActivity(
                        if (Build.VERSION.SDK_INT >= 26) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        },
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        /** "vegukin/system": other apps and this phone, see lib/core/system.dart. */
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vegukin/system").setMethodCallHandler { call, result ->
            when (call.method) {
                // Of the apps asked about, the ones installed, with their icons.
                "installed" -> result.success(
                    (call.arguments as List<*>).filterIsInstance<String>()
                        .filter { packageManager.getLaunchIntentForPackage(it) != null }
                        .map { mapOf("package" to it, "icon" to iconPng(it)) },
                )
                "open" -> {
                    val launch = packageManager.getLaunchIntentForPackage(call.arguments as String)
                    if (launch != null) startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(launch != null)
                }
                "device" -> {
                    val info = packageManager.getPackageInfo(packageName, 0)
                    val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else @Suppress("DEPRECATION") info.versionCode.toLong()
                    result.success(
                        mapOf(
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "android" to Build.VERSION.RELEASE,
                            "version" to "${info.versionName} ($code)",
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }

        /** "vegukin/share": Android's share sheet, see lib/core/share.dart. */
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vegukin/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "text" -> {
                    val send = Intent(Intent.ACTION_SEND)
                        .setType("text/plain")
                        .putExtra(Intent.EXTRA_TEXT, call.arguments as String)
                    startActivity(Intent.createChooser(send, null))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** An app's launcher icon as a PNG, 96 px square. */
    private fun iconPng(pkg: String): ByteArray? = try {
        val drawable = packageManager.getApplicationIcon(pkg)
        val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, 96, 96)
        drawable.draw(Canvas(bitmap))
        ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
    } catch (e: Exception) {
        null
    }

    override fun onDestroy() {
        camera?.stop()
        super.onDestroy()
    }
}
