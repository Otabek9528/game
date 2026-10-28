package com.vegukin.muslim_vegukin.widget

import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.text.SimpleDateFormat
import java.util.Collections
import java.util.Date
import java.util.Locale

/**
 * The widgets' own usage counts, sent as the app sends its own
 * (lib/core/activity_log.dart), so the stats page can tell how many phones
 * have a widget even when the app itself isn't opened:
 *
 * * `widget_large_apk`, `widget_small_apk`: once a day while one is on a
 *   home screen;
 * * `widget_added_large_apk` …: the first of its size placed;
 * * `widget_removed_large_apk` …: the last of its size taken away.
 *
 * The app tells it where to send and as whom ([remember]); until the app has
 * been opened once, nothing is sent. A send that fails is dropped, except the
 * daily one, which the next redraw tries again.
 */
object WidgetLog {
    private const val PREFS = "vegukin_widget_log"
    private const val KEY_URL = "url"
    private const val KEY_USER = "user_id"
    private const val KEY_NAME = "username"

    /** What is on its way, so a burst of redraws sends it once. */
    private val sending = Collections.synchronizedSet(mutableSetOf<String>())

    fun remember(context: Context, url: String, userId: Long, username: String) {
        prefs(context).edit()
            .putString(KEY_URL, url)
            .putLong(KEY_USER, userId)
            .putString(KEY_NAME, username)
            .apply()
    }

    /** Today's "still on a home screen", once a day for each size there is. */
    fun daily(context: Context, large: Int, small: Int) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val prefs = prefs(context)
        for ((size, count) in listOf("large" to large, "small" to small)) {
            val key = "sent_$size"
            if (count == 0 || prefs.getString(key, null) == today) continue
            send(context, "widget_$size") { prefs.edit().putString(key, today).apply() }
        }
    }

    fun event(context: Context, action: String) = send(context, action, null)

    private fun send(context: Context, action: String, done: (() -> Unit)?) {
        val prefs = prefs(context)
        val url = prefs.getString(KEY_URL, null) ?: return
        val userId = prefs.getLong(KEY_USER, 0L).takeIf { it != 0L } ?: return
        val body = JSONObject()
            .put("user_id", userId)
            .put("username", prefs.getString(KEY_NAME, "") ?: "")
            .put("action", "${action}_apk")
            .toString()
        if (!sending.add(action)) return
        // Off the main thread; a widget update must return at once.
        Thread {
            try {
                val connection = URI(url).toURL().openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.connectTimeout = 15_000
                connection.readTimeout = 15_000
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use { it.write(body.toByteArray()) }
                if (connection.responseCode in 200..299) done?.invoke()
                connection.disconnect()
            } catch (_: Exception) {
                // Offline: the daily one goes with a later redraw.
            } finally {
                sending.remove(action)
            }
        }.start()
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
