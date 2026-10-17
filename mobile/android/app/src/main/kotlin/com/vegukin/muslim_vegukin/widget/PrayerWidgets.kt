package com.vegukin.muslim_vegukin.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.vegukin.muslim_vegukin.MainActivity
import com.vegukin.muslim_vegukin.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** The large (4×2) widget: everything the app's prayer card shows. */
class LargePrayerWidget : PrayerWidgetProvider()

/** The small (2×2) widget: countdown, next prayer, progress, city. */
class SmallPrayerWidget : PrayerWidgetProvider()

/**
 * Both widgets. They redraw when Android asks (every 30 minutes, see
 * res/xml/widget_prayer_*_info.xml), when the app sends new data, at each
 * prayer time and at midnight (an alarm set by [PrayerWidgets.scheduleNext]),
 * and when the clock or time zone changes. The countdown itself is a
 * Chronometer, which ticks every second by itself.
 */
abstract class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        PrayerWidgets.updateAll(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        // Resized: the progress line is drawn to the widget's width.
        PrayerWidgets.render(context, manager, id, this is LargePrayerWidget)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            PrayerWidgets.ACTION_TICK,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED -> PrayerWidgets.updateAll(context)
        }
    }
}

object PrayerWidgets {
    const val ACTION_TICK = "com.vegukin.muslim_vegukin.WIDGET_TICK"

    /** Opens the app from the widget's city and refreshes the location. */
    const val ACTION_REFRESH_LOCATION = "com.vegukin.muslim_vegukin.REFRESH_LOCATION"

    private const val PREFS = "vegukin_widget"
    private const val KEY_DATA = "data"

    private val cells = intArrayOf(R.id.cell_0, R.id.cell_1, R.id.cell_2, R.id.cell_3, R.id.cell_4, R.id.cell_5)
    private val names = intArrayOf(R.id.name_0, R.id.name_1, R.id.name_2, R.id.name_3, R.id.name_4, R.id.name_5)
    private val times = intArrayOf(R.id.time_0, R.id.time_1, R.id.time_2, R.id.time_3, R.id.time_4, R.id.time_5)

    /** Called by MainActivity when the Flutter app publishes new data. */
    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY_DATA, json).apply()
    }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val large = manager.getAppWidgetIds(ComponentName(context, LargePrayerWidget::class.java))
        val small = manager.getAppWidgetIds(ComponentName(context, SmallPrayerWidget::class.java))
        large.forEach { render(context, manager, it, true) }
        small.forEach { render(context, manager, it, false) }
        if (large.isEmpty() && small.isEmpty()) cancelSchedule(context) else scheduleNext(context)
    }

    fun render(context: Context, manager: AppWidgetManager, id: Int, large: Boolean) {
        val views = RemoteViews(
            context.packageName,
            if (large) R.layout.widget_prayer_large else R.layout.widget_prayer_small,
        )
        val now = System.currentTimeMillis()
        val data = load(context)
        val moment = data?.momentAt(now)

        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, null))

        if (data == null || moment == null || data.names.size < 6 || data.until.size < 6) {
            views.setViewVisibility(R.id.widget_content, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            views.setTextViewText(
                R.id.empty_message,
                data?.message?.takeIf { it.isNotEmpty() } ?: context.getString(R.string.widget_open_app),
            )
            manager.updateAppWidget(id, views)
            return
        }

        views.setViewVisibility(R.id.widget_content, View.VISIBLE)
        views.setViewVisibility(R.id.widget_empty, View.GONE)
        views.setTextViewText(R.id.brand, data.brand)
        views.setTextViewText(R.id.city, data.city ?: "")
        views.setOnClickPendingIntent(R.id.city_chip, openApp(context, ACTION_REFRESH_LOCATION))

        views.setTextViewText(R.id.until, data.until[moment.next])
        // Chronometer counts down to the next prayer by itself, every second.
        val base = SystemClock.elapsedRealtime() + (moment.nextAt - now)
        views.setChronometer(R.id.countdown, base, null, true)
        views.setChronometerCountDown(R.id.countdown, true)

        val day = moment.day
        if (large) {
            views.setTextViewText(R.id.date_line1, day.line1)
            views.setTextViewText(R.id.date_line2, day.line2)
            for (i in 0 until 6) {
                val current = i == moment.current
                views.setTextViewText(names[i], data.names[i])
                views.setTextViewText(times[i], hhmm(day.times[i]))
                views.setInt(cells[i], "setBackgroundResource", if (current) R.drawable.widget_cell_current else 0)
                tint(context, views, names[i], if (current) R.color.widget_accent else R.color.widget_faint)
                tint(
                    context,
                    views,
                    times[i],
                    when {
                        current -> R.color.widget_accent
                        i == 1 -> R.color.widget_soft // sunrise ends a window, it starts no prayer
                        else -> R.color.widget_ink
                    },
                )
            }
        } else {
            views.setTextViewText(R.id.next, "${data.names[moment.next]} · ${hhmm(moment.nextAt)}")
            views.setTextViewText(R.id.date_short, day.short)
            // On a narrow launcher the city keeps the room; the date goes.
            val widthDp = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 150)
            views.setViewVisibility(R.id.date_short, if (widthDp >= 150) View.VISIBLE else View.GONE)
        }

        views.setImageViewBitmap(R.id.rail, rail(context, manager, id, large, moment.dayFraction))
        manager.updateAppWidget(id, views)
    }

    /** Text colour from a day/night colour resource; follows the theme on Android 12+. */
    private fun tint(context: Context, views: RemoteViews, viewId: Int, colorRes: Int) {
        if (Build.VERSION.SDK_INT >= 31) {
            views.setColorStateList(viewId, "setTextColor", colorRes)
        } else {
            views.setTextColor(viewId, context.getColor(colorRes))
        }
    }

    private fun load(context: Context): WidgetData? =
        WidgetData.parse(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_DATA, null))

    private fun hhmm(millis: Long): String = SimpleDateFormat("HH:mm", Locale.US).format(Date(millis))

    private fun openApp(context: Context, action: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action ?: Intent.ACTION_MAIN
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            if (action == null) 0 else 1,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    // ------------------------------------------------------------- schedule

    /**
     * Wakes the widgets at the next prayer time or midnight, whichever comes
     * first. A non-waking alarm with a one-minute window: it needs no special
     * permission and, while the screen is off (nobody looking), waits until the
     * phone wakes, then fires straight away.
     */
    private fun scheduleNext(context: Context) {
        val now = System.currentTimeMillis()
        val nextPrayer = load(context)?.momentAt(now)?.nextAt
        val midnight = Calendar.getInstance().apply {
            timeInMillis = now
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 1)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val at = minOf(nextPrayer ?: midnight, midnight) + 1000
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.setWindow(AlarmManager.RTC, at, 60_000L, tickIntent(context))
    }

    private fun cancelSchedule(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(tickIntent(context))
    }

    private fun tickIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, LargePrayerWidget::class.java).setAction(ACTION_TICK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    // ------------------------------------------------------------ the rail

    /**
     * The progress line as a picture: six segments (one per window), gold up
     * to [fraction], and the eight-pointed star at its end. Drawn to the
     * widget's actual width so the star isn't stretched.
     */
    private fun rail(context: Context, manager: AppWidgetManager, id: Int, large: Boolean, fraction: Float): Bitmap {
        val density = context.resources.displayMetrics.density
        val options = manager.getAppWidgetOptions(id)
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, if (large) 320 else 150)
        val paddingDp = if (large) 32 else 28
        val width = (((widthDp - paddingDp).coerceAtLeast(80)) * density).toInt()
        val height = (12 * density).toInt()

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val gap = 2 * density
        val segment = (width - 5 * gap) / 6f
        val barTop = height / 2f - 1.5f * density
        val barBottom = height / 2f + 1.5f * density
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(70, 128, 128, 128) }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = GOLD }
        val filledTo = fraction * width
        val radius = 1.5f * density

        for (i in 0 until 6) {
            val left = i * (segment + gap)
            val right = left + segment
            canvas.drawRoundRect(RectF(left, barTop, right, barBottom), radius, radius, track)
            if (filledTo > left) {
                canvas.drawRoundRect(RectF(left, barTop, minOf(right, filledTo), barBottom), radius, radius, fill)
            }
        }

        val star = khatam(filledTo.coerceIn(height / 2f, width - height / 2f), height / 2f, height.toFloat())
        canvas.drawPath(star, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = GOLD })
        canvas.drawPath(
            star,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = GOLD_DEEP
                style = Paint.Style.STROKE
                strokeWidth = density
            },
        )
        return bitmap
    }

    private const val GOLD = 0xFFEAB932.toInt()
    private const val GOLD_DEEP = 0xFFB5860A.toInt()

    /** The eight-pointed star, as in the app (lib/core/widgets/khatam.dart). */
    private fun khatam(cx: Float, cy: Float, size: Float): Path {
        val points = floatArrayOf(
            8f, 0f, 10.34f, 2.34f, 13.66f, 2.34f, 13.66f, 5.66f, 16f, 8f, 13.66f, 10.34f,
            13.66f, 13.66f, 10.34f, 13.66f, 8f, 16f, 5.66f, 13.66f, 2.34f, 13.66f, 2.34f, 10.34f,
            0f, 8f, 2.34f, 5.66f, 2.34f, 2.34f, 5.66f, 2.34f,
        )
        val scale = size / 16f
        val path = Path()
        for (i in points.indices step 2) {
            val x = cx + (points[i] - 8f) * scale
            val y = cy + (points[i + 1] - 8f) * scale
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        return path
    }
}
