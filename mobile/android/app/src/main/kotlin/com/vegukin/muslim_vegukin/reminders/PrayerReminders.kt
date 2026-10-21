package com.vegukin.muslim_vegukin.reminders

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.vegukin.muslim_vegukin.MainActivity
import com.vegukin.muslim_vegukin.R
import com.vegukin.muslim_vegukin.widget.PrayerWidgets
import org.json.JSONArray

/** Fires the next reminder, and puts the chain back after a restart or clock change. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            PrayerReminders.ACTION_FIRE -> PrayerReminders.fire(context)
            else -> PrayerReminders.scheduleNext(context) // boot, update, clock, permission
        }
    }
}

/**
 * Prayer reminders. The app works out a week of them, texts included, in
 * its own language (lib/features/reminders/) and hands them over with
 * [save]; from then on they arrive with the app closed. One alarm is set,
 * for the soonest; when it fires, that reminder is shown and the next alarm
 * set. Each way of arriving (sound, vibration, silent) is its own channel,
 * as Android fixes sound and vibration per channel.
 */
object PrayerReminders {
    const val ACTION_FIRE = "com.vegukin.muslim_vegukin.REMINDER"

    /** Tapping a reminder opens the app on the prayers page. */
    const val ACTION_OPEN_PRAYERS = "com.vegukin.muslim_vegukin.OPEN_PRAYERS"

    private const val PREFS = "vegukin_reminders"
    private const val KEY_LIST = "list"
    private const val KEY_SHOWN = "shown_until"

    /** A late alarm still shows a reminder this old; anything older is dropped. */
    private const val LATE_MS = 30 * 60 * 1000L

    private val VIBRATION = longArrayOf(0, 220, 140, 220)

    private class Entry(
        val id: Int,
        val at: Long,
        val channel: String,
        val title: String,
        val body: String,
    )

    fun save(context: Context, json: String) {
        prefs(context).edit().putString(KEY_LIST, json).apply()
        scheduleNext(context)
    }

    fun scheduleNext(context: Context) {
        val now = System.currentTimeMillis()
        var shown = prefs(context).getLong(KEY_SHOWN, 0)
        if (shown > now + 1000) {
            // The clock was set back: what was shown is in the future again.
            shown = now
            prefs(context).edit().putLong(KEY_SHOWN, now).apply()
        }
        val next = load(context).filter { it.at > maxOf(now, shown) }.minByOrNull { it.at }
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = fireIntent(context)
        if (next == null) {
            alarms.cancel(intent)
            return
        }
        if (PrayerWidgets.canAlarmExactly(context)) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.at, intent)
        } else {
            // Without "Alarms & reminders" Android may run this a few minutes late.
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.at, intent)
        }
    }

    fun fire(context: Context) {
        val now = System.currentTimeMillis()
        val prefs = prefs(context)
        val shown = prefs.getLong(KEY_SHOWN, 0)
        val due = load(context).filter { it.at > shown && it.at <= now + 1000 }
        due.filter { it.at > now - LATE_MS }.forEach { show(context, it) }
        due.maxOfOrNull { it.at }?.let { prefs.edit().putLong(KEY_SHOWN, it).apply() }
        scheduleNext(context)
    }

    fun notificationsAllowed(context: Context): Boolean =
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()

    /** Lets the user hear or feel a choice before keeping it. */
    fun preview(context: Context, mode: String) {
        when (mode) {
            "sound" -> MediaPlayer.create(context, R.raw.vegukin_chime)?.apply {
                setOnCompletionListener { it.release() }
                start()
            }
            "vibrate" -> vibrate(context)
        }
    }

    private fun show(context: Context, entry: Entry) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = when (entry.channel) {
            "sound" -> CHANNEL_SOUND
            "vibrate" -> CHANNEL_VIBRATE
            else -> CHANNEL_SILENT
        }
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            ensureChannels(context, manager)
            Notification.Builder(context, channel)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).apply {
                setDefaults(0)
                when (channel) {
                    CHANNEL_SOUND -> {
                        setSound(chime(context))
                        setVibrate(VIBRATION)
                        setPriority(Notification.PRIORITY_HIGH)
                    }
                    CHANNEL_VIBRATE -> {
                        setVibrate(VIBRATION)
                        setPriority(Notification.PRIORITY_HIGH)
                    }
                    else -> setPriority(Notification.PRIORITY_DEFAULT)
                }
            }
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_prayer)
            .setColor(0xFF047857.toInt())
            .setContentTitle(entry.title)
            .setContentText(entry.body)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setWhen(entry.at)
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(openPrayers(context))
            .build()
        manager.notify(entry.id, notification)
    }

    private const val CHANNEL_SOUND = "prayer_sound"
    private const val CHANNEL_VIBRATE = "prayer_vibrate"
    private const val CHANNEL_SILENT = "prayer_silent"

    private fun ensureChannels(context: Context, manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < 26) return
        val sound = NotificationChannel(
            CHANNEL_SOUND,
            context.getString(R.string.reminders_channel_sound),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(
                chime(context),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            enableVibration(true)
            vibrationPattern = VIBRATION
        }
        val vibrate = NotificationChannel(
            CHANNEL_VIBRATE,
            context.getString(R.string.reminders_channel_vibrate),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(null, null)
            enableVibration(true)
            vibrationPattern = VIBRATION
        }
        val silent = NotificationChannel(
            CHANNEL_SILENT,
            context.getString(R.string.reminders_channel_silent),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannels(listOf(sound, vibrate, silent))
    }

    private fun chime(context: Context): Uri =
        Uri.parse("android.resource://${context.packageName}/${R.raw.vegukin_chime}")

    private fun vibrate(context: Context) {
        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (Build.VERSION.SDK_INT >= 26) {
            vibrator.vibrate(VibrationEffect.createWaveform(VIBRATION, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(VIBRATION, -1)
        }
    }

    private fun openPrayers(context: Context): PendingIntent = PendingIntent.getActivity(
        context,
        2,
        Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_PRAYERS
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        },
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun fireIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, ReminderReceiver::class.java).setAction(ACTION_FIRE),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(context: Context): List<Entry> {
        val json = prefs(context).getString(KEY_LIST, null) ?: return emptyList()
        return try {
            val array = JSONArray(json)
            List(array.length()) { i ->
                val o = array.getJSONObject(i)
                Entry(
                    id = o.getInt("id"),
                    at = o.getLong("at"),
                    channel = o.getString("channel"),
                    title = o.getString("title"),
                    body = o.getString("body"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
