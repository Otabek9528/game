package com.vegukin.muslim_vegukin.qibla

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.SystemClock
import io.flutter.plugin.common.EventChannel
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * The Qibla page's compass ("vegukin/compass"). Android's fused rotation
 * vector (magnetometer, accelerometer and gyroscope together) gives where
 * the phone's top edge points when it lies flat and where the back camera
 * looks when it stands up, both from MAGNETIC north (the app adds the
 * declination). Also sent: Android's own estimate of the heading's accuracy,
 * the magnetometer's calibration state and the field's strength, which shows
 * metal or electronics nearby.
 */
class QiblaCompass(context: Context) : SensorEventListener, EventChannel.StreamHandler {
    private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var sink: EventChannel.EventSink? = null

    private val rotation = FloatArray(9)
    private var hasRotation = false
    private var source = "none"

    // Without a rotation-vector sensor: accelerometer and magnetometer.
    private val gravity = FloatArray(3)
    private val geomagnetic = FloatArray(3)
    private var hasGravity = false

    /** Radians from the rotation vector, or -1 when the phone doesn't say. */
    private var headingAccuracy = -1f

    /** SensorManager.SENSOR_STATUS_* of the magnetometer: 0 unreliable … 3 high. */
    private var magnetStatus = -1
    private var fieldMicroTesla = 0f
    private var lastSent = 0L

    fun hasCompass(): Boolean = sensors.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        val magnet = sensors.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
        if (magnet == null) {
            events.error("no_compass", "No magnetometer", null)
            return
        }
        val fused = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            ?: sensors.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
        if (fused != null) {
            source = if (fused.type == Sensor.TYPE_ROTATION_VECTOR) "rotation" else "geomagnetic"
            sensors.registerListener(this, fused, SensorManager.SENSOR_DELAY_GAME)
        } else {
            source = "accel+magnet"
            sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
                sensors.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
        }
        sensors.registerListener(this, magnet, SensorManager.SENSOR_DELAY_GAME)
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
        hasRotation = false
        hasGravity = false
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        if (sensor.type == Sensor.TYPE_MAGNETIC_FIELD) magnetStatus = accuracy
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR, Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotation, event.values)
                hasRotation = true
                headingAccuracy = if (event.values.size > 4) event.values[4] else -1f
                send()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                val v = event.values
                val strength = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
                fieldMicroTesla = if (fieldMicroTesla == 0f) strength else fieldMicroTesla * 0.8f + strength * 0.2f
                if (magnetStatus < 0) magnetStatus = event.accuracy
                if (source == "accel+magnet") {
                    for (i in 0..2) geomagnetic[i] = geomagnetic[i] * 0.7f + v[i] * 0.3f
                    if (hasGravity && SensorManager.getRotationMatrix(rotation, null, gravity, geomagnetic)) {
                        hasRotation = true
                        send()
                    }
                }
            }
            Sensor.TYPE_ACCELEROMETER -> {
                for (i in 0..2) gravity[i] = gravity[i] * 0.8f + event.values[i] * 0.2f
                hasGravity = true
            }
        }
    }

    /** About 30 times a second. World axes: x east, y north, z up. */
    private fun send() {
        val sink = sink ?: return
        if (!hasRotation) return
        val now = SystemClock.elapsedRealtime()
        if (now - lastSent < 33) return
        lastSent = now
        val r = rotation
        // Columns of r are the phone's axes in the world: y (top edge) and z
        // (out of the screen; the back camera looks along -z).
        val top = Math.toDegrees(atan2(r[1], r[4]).toDouble())
        val camera = Math.toDegrees(atan2(-r[2], -r[5]).toDouble())
        val cameraUp = Math.toDegrees(asin((-r[8]).coerceIn(-1f, 1f).toDouble()))
        val tilt = Math.toDegrees(acos(r[8].coerceIn(-1f, 1f).toDouble()))
        sink.success(
            mapOf(
                "top" to top,
                "camera" to camera,
                "cameraUp" to cameraUp,
                "tilt" to tilt,
                // "Up" seen from the phone: drives the spirit level.
                "levelX" to r[6].toDouble(),
                "levelY" to r[7].toDouble(),
                "accuracy" to if (headingAccuracy >= 0) Math.toDegrees(headingAccuracy.toDouble()) else -1.0,
                "status" to magnetStatus,
                "field" to fieldMicroTesla.toDouble(),
                "source" to source,
            ),
        )
    }
}
