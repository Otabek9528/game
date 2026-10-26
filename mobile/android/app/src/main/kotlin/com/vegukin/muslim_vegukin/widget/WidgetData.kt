package com.vegukin.muslim_vegukin.widget

import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * What the Flutter app hands the widgets (see lib/features/widget/
 * home_widget_bridge.dart): a week of prayer times plus every label already
 * in the user's language, so the widgets never need the app to be running.
 */
class WidgetData(
    val brand: String,
    val message: String,
    val city: String?,
    val names: List<String>,
    val until: List<String>,
    val days: List<Day>,
) {
    /** One day; [times] are Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha in epoch ms. */
    class Day(
        val date: String,
        val line1: String,
        val line2: String,
        val short: String,
        val times: LongArray,
    )

    /** Where a moment falls: the window it is in and the countdown target. */
    class Moment(
        val day: Day,
        val current: Int,
        val next: Int,
        val nextAt: Long,
        val progress: Float,
    ) {
        /** 0–1 across the day strip: whole windows passed plus this one's share. */
        val dayFraction: Float get() = ((current + progress) / 6f).coerceIn(0f, 1f)
    }

    /**
     * The window [now] falls in, or null when the saved week has run out.
     * Before Fajr, Isha is still current (from last night); after Isha, the
     * next Fajr is tomorrow's.
     */
    fun momentAt(now: Long): Moment? {
        val key = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
        val index = days.indexOfFirst { it.date == key }
        if (index < 0) return null
        val day = days[index]
        val t = day.times
        if (t.size < 6) return null

        var passed = -1
        for (i in 0 until 6) if (now >= t[i]) passed = i

        val start: Long
        val end: Long
        val current: Int
        val next: Int
        when (passed) {
            -1 -> {
                current = 5
                next = 0
                start = days.getOrNull(index - 1)?.times?.get(5) ?: (t[5] - DAY_MS)
                end = t[0]
            }
            5 -> {
                current = 5
                next = 0
                start = t[5]
                end = days.getOrNull(index + 1)?.times?.get(0) ?: (t[0] + DAY_MS)
            }
            else -> {
                current = passed
                next = passed + 1
                start = t[passed]
                end = t[passed + 1]
            }
        }
        val span = (end - start).coerceAtLeast(1L)
        val progress = ((now - start).toFloat() / span).coerceIn(0f, 1f)
        return Moment(day, current, next, end, progress)
    }

    companion object {
        const val DAY_MS = 24L * 60 * 60 * 1000

        /** Null when there is nothing usable yet; the widget then asks to open the app. */
        fun parse(json: String?): WidgetData? {
            if (json.isNullOrEmpty()) return null
            return try {
                val o = JSONObject(json)
                val names = o.optJSONArray("names")
                val until = o.optJSONArray("until")
                val days = o.optJSONArray("days")
                WidgetData(
                    brand = o.optString("brand", "Muslim Vegukin"),
                    message = o.optString("message", ""),
                    city = if (o.has("city")) o.getString("city") else null,
                    names = List(names?.length() ?: 0) { names!!.getString(it) },
                    until = List(until?.length() ?: 0) { until!!.getString(it) },
                    days = List(days?.length() ?: 0) { i ->
                        val d = days!!.getJSONObject(i)
                        val times = d.getJSONArray("times")
                        Day(
                            date = d.getString("date"),
                            line1 = d.getString("line1"),
                            line2 = d.getString("line2"),
                            short = d.getString("short"),
                            times = LongArray(times.length()) { times.getLong(it) },
                        )
                    },
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}
