package mn.callrecorder.record_calls

import android.Manifest
import android.accessibilityservice.AccessibilityService
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.media.projection.MediaProjectionConfig
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "mn.callrecorder/command"
        const val EVENT_CHANNEL = "mn.callrecorder/stream"
        private const val REQUEST_SCREEN_CAPTURE = 2002
    }

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingScreenCaptureResult: MethodChannel.Result? = null
    private var pendingVideoCaller: String = "Manual Video Test"
    private var pendingVideoSource: String = "Manual"
    private var pendingVideoAudioSource: String = "mic_only"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. MethodChannel for RPC commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPermissionsStatus" -> {
                        val status = getPermissionsStatusMap()
                        result.success(status)
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    }
                    "openAppDetailsSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            try {
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("BATTERY_INTENT_ERROR", e.message, null)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "setAutoRecordEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppSettingsHelper.setAutoRecordEnabled(this, enabled)
                        result.success(true)
                    }
                    "isAutoRecordEnabled" -> {
                        val enabled = AppSettingsHelper.isAutoRecordEnabled(this)
                        result.success(enabled)
                    }
                    "setAudioRecordingSource" -> {
                        val source = call.argument<String>("source") ?: "both"
                        AppSettingsHelper.setAudioRecordingSource(this, source)
                        result.success(true)
                    }
                    "getAudioRecordingSource" -> {
                        val source = AppSettingsHelper.getAudioRecordingSource(this)
                        result.success(source)
                    }
                    "getStorageDirectory" -> {
                        val dir = AppSettingsHelper.getStorageDirectory(this)
                        result.success(dir)
                    }
                    "setStorageDirectory" -> {
                        val path = call.argument<String>("path")
                        if (path != null && path.isNotBlank()) {
                            val success = AppSettingsHelper.setStorageDirectory(this, path)
                            result.success(success)
                        } else {
                            result.error("INVALID_PATH", "Storage path cannot be empty", null)
                        }
                    }
                    "resetStorageDirectory" -> {
                        val defaultPath = AppSettingsHelper.resetStorageDirectory(this)
                        result.success(defaultPath)
                    }
                    "getAvailableStorageDirectories" -> {
                        val list = AppSettingsHelper.getAvailableStorageDirectories(this)
                        result.success(list)
                    }
                    "getStorageDirectoryInfo" -> {
                        val info = AppSettingsHelper.getStorageDirectoryInfo(this)
                        result.success(info)
                    }
                    "startManualRecording" -> {
                        val audioSource = call.argument<String>("audioSource")
                        AudioRecordingService.startRecording(
                            this,
                            "Manual Test",
                            "Manual",
                            audioSource
                        )
                        result.success(true)
                    }
                    "stopManualRecording" -> {
                        AudioRecordingService.stopRecording(this)
                        result.success(true)
                    }
                    "startVideoRecording" -> {
                        if (pendingScreenCaptureResult != null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val caller = call.argument<String>("callerNumber") ?: "Manual Video Test"
                        val source = call.argument<String>("appSource") ?: "Manual"
                        pendingVideoAudioSource = call.argument<String>("audioSource")
                            ?: "mic_only"
                        pendingVideoCaller = caller
                        pendingVideoSource = source

                        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                        if (projectionManager == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        pendingScreenCaptureResult = result
                        try {
                            val captureIntent = if (
                                Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                            ) {
                                projectionManager.createScreenCaptureIntent(
                                    MediaProjectionConfig.createConfigForDefaultDisplay()
                                )
                            } else {
                                projectionManager.createScreenCaptureIntent()
                            }
                            @Suppress("DEPRECATION")
                            startActivityForResult(captureIntent, REQUEST_SCREEN_CAPTURE)
                        } catch (e: Exception) {
                            Log.w("MainActivity", "Failed to launch screen capture intent: ${e.message}")
                            pendingScreenCaptureResult?.success(false)
                            pendingScreenCaptureResult = null
                        }
                    }
                    "stopVideoRecording" -> {
                        VideoRecordingService.stopRecording(this)
                        result.success(true)
                    }
                    "isVideoRecording" -> {
                        result.success(VideoRecordingService.isRecording)
                    }
                    "isRecording" -> {
                        result.success(AudioRecordingService.isRecording || VideoRecordingService.isRecording)
                    }
                    "fetchPendingRecordings" -> {
                        val items = RecordingQueueManager.dequeueAll(this)
                        val listMaps = items.map { item ->
                            mapOf(
                                "filePath" to item.filePath,
                                "callerNumber" to item.callerNumber,
                                "appSource" to item.appSource,
                                "durationSec" to item.durationSec,
                                "fileSize" to item.fileSize,
                                "createdAt" to item.createdAt,
                                "isFavorite" to item.isFavorite,
                                "notes" to item.notes,
                                "mediaType" to item.mediaType
                            )
                        }
                        result.success(listMaps)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // 2. EventChannel for real-time events & waveform amplitude
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events

                    AudioRecordingService.onAmplitudeListener = { amp ->
                        mainHandler.post {
                            eventSink?.success(mapOf(
                                "type" to "amplitude_update",
                                "amplitude" to amp
                            ))
                        }
                    }

                    AudioRecordingService.onStatusListener = { status, details ->
                        val map = HashMap<String, Any>(details)
                        map["type"] = status
                        mainHandler.post {
                            eventSink?.success(map)
                        }
                    }

                    VideoRecordingService.onStatusListener = { status, details ->
                        val map = HashMap<String, Any>(details)
                        map["type"] = status
                        mainHandler.post {
                            eventSink?.success(map)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    AudioRecordingService.onAmplitudeListener = null
                    AudioRecordingService.onStatusListener = null
                    VideoRecordingService.onStatusListener = null
                }
            })
    }

    private fun getPermissionsStatusMap(): Map<String, Boolean> {
        val micGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        val phoneGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

        val notificationGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        val accessibilityGranted = isAccessibilityServiceEnabled(this, CallAccessibilityService::class.java)

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val batteryIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
        } else {
            true
        }

        return mapOf(
            "mic" to micGranted,
            "phone" to phoneGranted,
            "notification" to notificationGranted,
            "accessibility" to accessibilityGranted,
            "batteryIgnored" to batteryIgnored
        )
    }

    private fun isAccessibilityServiceEnabled(context: Context, service: Class<out AccessibilityService>): Boolean {
        val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager ?: return false
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        val myServiceName = ComponentName(context, service).flattenToString()

        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(myServiceName, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_SCREEN_CAPTURE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                VideoRecordingService.startRecording(
                    this,
                    resultCode,
                    data,
                    pendingVideoCaller,
                    pendingVideoSource,
                    pendingVideoAudioSource
                )
                pendingScreenCaptureResult?.success(true)
            } else {
                Log.i("MainActivity", "Screen capture permission declined or canceled; video recording was not started.")
                pendingScreenCaptureResult?.success(false)
            }
            pendingScreenCaptureResult = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        eventSink = null
        AudioRecordingService.onAmplitudeListener = null
        AudioRecordingService.onStatusListener = null
        VideoRecordingService.onStatusListener = null
    }
}
