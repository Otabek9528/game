package com.vegukin.muslim_vegukin.qibla

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Size
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import kotlin.math.abs
import kotlin.math.atan

/**
 * The back camera's picture for the Qibla page's camera view, drawn into a
 * Flutter texture. Also reports the lens's field of view, so the app can put
 * the Kaaba marker at the right place in the picture. Uses the camera
 * permission the app asked for once, at first launch.
 */
class QiblaCamera(private val context: Context, private val textures: TextureRegistry) {
    private val main = Handler(Looper.getMainLooper())
    private var thread: HandlerThread? = null
    private var device: CameraDevice? = null
    private var session: CameraCaptureSession? = null
    private var producer: TextureRegistry.SurfaceProducer? = null

    /** Bumped by [stop]: a camera that opens after it is closed at once. */
    private var generation = 0
    private var pending: MethodChannel.Result? = null

    @SuppressLint("MissingPermission")
    fun start(result: MethodChannel.Result) {
        stop()
        val gen = ++generation
        if (context.checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            result.error("permission", "Camera permission is off", null)
            return
        }
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val id = manager.cameraIdList.firstOrNull {
            manager.getCameraCharacteristics(it).get(CameraCharacteristics.LENS_FACING) ==
                CameraCharacteristics.LENS_FACING_BACK
        }
        if (id == null) {
            result.error("no_camera", "No back camera", null)
            return
        }
        val chars = manager.getCameraCharacteristics(id)
        val size = previewSize(chars)
        val sensorOrientation = chars.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 90
        val focal = chars.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.firstOrNull()
        val sensor = chars.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
        fun fov(mm: Float?): Double =
            if (focal == null || focal <= 0f || mm == null) 60.0 else Math.toDegrees(2 * atan(mm / (2 * focal)).toDouble())

        val worker = HandlerThread("qibla-camera").apply { start() }
        thread = worker
        val handler = Handler(worker.looper)
        val texture = textures.createSurfaceProducer()
        texture.setSize(size.width, size.height)
        producer = texture

        pending = result
        fun answer(block: (MethodChannel.Result) -> Unit) = main.post {
            if (gen == generation) pending?.let(block)
            pending = null
        }

        manager.openCamera(
            id,
            object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    if (gen != generation) {
                        camera.close()
                        return
                    }
                    device = camera
                    val surface = texture.surface
                    @Suppress("DEPRECATION")
                    camera.createCaptureSession(
                        listOf(surface),
                        object : CameraCaptureSession.StateCallback() {
                            override fun onConfigured(s: CameraCaptureSession) {
                                session = s
                                val request = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                                    addTarget(surface)
                                    set(
                                        CaptureRequest.CONTROL_AF_MODE,
                                        CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE,
                                    )
                                }.build()
                                try {
                                    s.setRepeatingRequest(request, null, handler)
                                } catch (e: Exception) {
                                    answer { it.error("camera", e.message, null) }
                                    return
                                }
                                answer {
                                    it.success(
                                        mapOf(
                                            "textureId" to texture.id(),
                                            "width" to size.width,
                                            "height" to size.height,
                                            "sensorOrientation" to sensorOrientation,
                                            "fovLong" to fov(sensor?.width),
                                            "fovShort" to fov(sensor?.height),
                                            "rotateInApp" to !texture.handlesCropAndRotation(),
                                        ),
                                    )
                                }
                            }

                            override fun onConfigureFailed(s: CameraCaptureSession) {
                                answer { it.error("camera", "Session failed", null) }
                            }
                        },
                        handler,
                    )
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    answer { it.error("camera", "Disconnected", null) }
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    answer { it.error("camera", "Error $error", null) }
                }
            },
            handler,
        )
    }

    fun stop() {
        generation++
        pending?.error("stopped", "Camera view closed", null)
        pending = null
        try {
            session?.close()
        } catch (_: Exception) {
        }
        session = null
        device?.close()
        device = null
        producer?.release()
        producer = null
        thread?.quitSafely()
        thread = null
    }

    /** 4:3, the whole sensor, so the field of view holds; at most ~1.5 MP. */
    private fun previewSize(chars: CameraCharacteristics): Size {
        val map = chars.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val sizes = map?.getOutputSizes(SurfaceTexture::class.java)?.toList().orEmpty()
        val fourThree = sizes.filter { abs(it.width * 3 - it.height * 4) < 8 && it.width <= 1600 }
        return fourThree.maxByOrNull { it.width * it.height }
            ?: sizes.filter { it.width <= 1920 }.maxByOrNull { it.width * it.height }
            ?: Size(1280, 960)
    }
}
