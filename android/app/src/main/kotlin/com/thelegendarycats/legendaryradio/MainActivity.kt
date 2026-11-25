package com.thelegendarycats.legendaryradio

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.audiofx.Visualizer
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import kotlin.math.hypot

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.thelegendarycats.legendaryradio/native"
    private val SPECTRUM_EVENT_CHANNEL = "com.thelegendarycats.legendaryradio/spectrum"

    private var visualizer: Visualizer? = null
    private var spectrumSink: EventChannel.EventSink? = null
    private var glyphEnabled: Boolean = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SPECTRUM_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    spectrumSink = events
                    startAudioVisualizer(0) // Output mix session 0 captures active media playback
                }

                override fun onCancel(arguments: Any?) {
                    stopAudioVisualizer()
                    spectrumSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startVisualizer" -> {
                        val sessionId = call.argument<Int>("sessionId") ?: 0
                        startAudioVisualizer(sessionId)
                        result.success(true)
                    }
                    "stopVisualizer" -> {
                        stopAudioVisualizer()
                        result.success(true)
                    }
                    "setGlyphEnabled" -> {
                        glyphEnabled = call.argument<Boolean>("enabled") ?: true
                        result.success(glyphEnabled)
                    }
                    "pulseGlyphForDj" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        triggerNothingGlyphDjAnimation(active)
                        result.success(true)
                    }
                    "getAudioOutputDevices" -> {
                        result.success(getConnectedAudioDevices())
                    }
                    "isNothingDevice" -> {
                        val isNothing = Build.MANUFACTURER.equals("Nothing", ignoreCase = true)
                        result.success(isNothing)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startAudioVisualizer(audioSessionId: Int) {
        try {
            stopAudioVisualizer()
            visualizer = Visualizer(audioSessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1].coerceAtMost(1024)
                setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        v: Visualizer?,
                        waveform: ByteArray?,
                        samplingRate: Int
                    ) {}

                    override fun onFftDataCapture(
                        v: Visualizer?,
                        fft: ByteArray?,
                        samplingRate: Int
                    ) {
                        if (fft == null || spectrumSink == null) return
                        val bands = compute18FrequencyBands(fft)
                        runOnUiThread {
                            spectrumSink?.success(bands)
                        }
                        if (glyphEnabled && bands.isNotEmpty()) {
                            updateNothingGlyphFromBass(bands[0], bands[1])
                        }
                    }
                }, Visualizer.getMaxCaptureRate() / 2, false, true)
                enabled = true
            }
        } catch (e: Exception) {
            // Permission RECORD_AUDIO not yet granted or hardware unsupported
        }
    }

    private fun compute18FrequencyBands(fft: ByteArray): List<Double> {
        val n = fft.size / 2
        val magnitudes = DoubleArray(n)
        for (i in 1 until n) {
            val re = fft[2 * i].toDouble()
            val im = fft[2 * i + 1].toDouble()
            magnitudes[i] = hypot(re, im)
        }
        val bandCount = 18
        val result = ArrayList<Double>(bandCount)
        val step = (n / 2) / bandCount
        for (b in 0 until bandCount) {
            var sum = 0.0
            val start = (b * step).coerceAtLeast(1)
            val end = ((b + 1) * step).coerceAtMost(n - 1)
            for (k in start..end) {
                sum += magnitudes[k]
            }
            val avg = if (end >= start) sum / (end - start + 1) else 0.0
            val normalized = (avg / 45.0).coerceIn(0.05, 1.0)
            result.add(normalized)
        }
        return result
    }

    private fun updateNothingGlyphFromBass(subBass: Double, bass: Double) {
        // Hook for Nothing Glyph Developer Kit (GlyphManager)
        // Maps subBass/bass intensity (0.0..1.0) to Nothing Phone Glyph zones
    }

    private fun triggerNothingGlyphDjAnimation(active: Boolean) {
        // Hook for Nothing Glyph Developer Kit voice animation pattern during Monsieur Chat speech
    }

    private fun getConnectedAudioDevices(): List<Map<String, Any>> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val list = mutableListOf<Map<String, Any>>()
        list.add(mapOf("id" to "phone", "name" to "Haut-parleur Nothing Phone", "type" to "builtin"))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                val typeName = when (device.type) {
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "Bluetooth"
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "Casque / Écouteurs filaires"
                    AudioDeviceInfo.TYPE_USB_DEVICE,
                    AudioDeviceInfo.TYPE_USB_HEADSET -> "DAC / Audio USB"
                    else -> null
                }
                if (typeName != null) {
                    list.add(
                        mapOf(
                            "id" to device.id.toString(),
                            "name" to "${device.productName} ($typeName)",
                            "type" to "system"
                        )
                    )
                }
            }
        }
        return list
    }

    private fun stopAudioVisualizer() {
        try {
            visualizer?.enabled = false
            visualizer?.release()
            visualizer = null
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        stopAudioVisualizer()
        super.onDestroy()
    }
}
