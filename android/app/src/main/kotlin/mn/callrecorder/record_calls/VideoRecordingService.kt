package mn.callrecorder.record_calls

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream

class VideoRecordingService : Service() {

    companion object {
        private const val TAG = "VideoRecordingService"
        const val CHANNEL_ID = "mn_callrecorder_video_fgs_channel"
        const val NOTIFICATION_ID = 2002

        const val ACTION_START = "mn.callrecorder.action.START_VIDEO"
        const val ACTION_STOP = "mn.callrecorder.action.STOP_VIDEO"

        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_DATA = "extra_result_data"
        const val EXTRA_CALLER_NUMBER = "extra_caller_number"
        const val EXTRA_APP_SOURCE = "extra_app_source"
        const val EXTRA_AUDIO_SOURCE = "extra_audio_source"

        @Volatile
        var isRecording: Boolean = false
            private set

        @Volatile
        var currentSource: String = "Idle"
            private set

        @Volatile
        var currentCaller: String = ""
            private set

        var onStatusListener: ((status: String, details: Map<String, Any>) -> Unit)? = null

        fun startRecording(
            context: Context,
            resultCode: Int,
            resultData: Intent?,
            callerNumber: String,
            appSource: String,
            audioSource: String
        ) {
            val intent = Intent(context, VideoRecordingService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_RESULT_CODE, resultCode)
                putExtra(EXTRA_RESULT_DATA, resultData)
                putExtra(EXTRA_CALLER_NUMBER, callerNumber)
                putExtra(EXTRA_APP_SOURCE, appSource)
                putExtra(EXTRA_AUDIO_SOURCE, audioSource)
            }
            try {
                ContextCompat.startForegroundService(context, intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start video foreground service: ${e.message}")
            }
        }

        fun stopRecording(context: Context) {
            val intent = Intent(context, VideoRecordingService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.startService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send stop video service: ${e.message}")
            }
        }
    }

    private var mediaRecorder: MediaRecorder? = null
    private var mediaProjection: MediaProjection? = null
    private var mediaProjectionCallback: MediaProjection.Callback? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var outputFile: File? = null
    private var playbackAudioFile: File? = null
    private var playbackAudioCapture: PlaybackAudioCaptureRecorder? = null
    private var playbackAudioCaptured = false
    private var startupAudioWarning: String? = null
    private var audioSource: String = "both"
    private var recordStartTime: Long = 0
    private var callerNumber: String = "Unknown"
    private var appSource: String = "Manual"

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val resultData = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(EXTRA_RESULT_DATA)
                }
                callerNumber = intent.getStringExtra(EXTRA_CALLER_NUMBER) ?: "Unknown"
                appSource = intent.getStringExtra(EXTRA_APP_SOURCE) ?: "Manual"
                audioSource = intent.getStringExtra(EXTRA_AUDIO_SOURCE)
                    ?: AppSettingsHelper.getAudioRecordingSource(this)
                startVideoRecordingInternal(resultCode, resultData)
            }
            ACTION_STOP -> {
                stopVideoRecordingInternal()
            }
            else -> {
                Log.w(TAG, "Unknown action: ${intent?.action}")
            }
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Video Call Recorder Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifies when video call screen recording is actively recording."
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Record Call (Video)")
            .setContentText("Recording $appSource video call: $callerNumber")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startVideoRecordingInternal(resultCode: Int, resultData: Intent?) {
        if (isRecording || AudioRecordingService.isRecording) {
            Log.d(TAG, "Recording already in progress (video=$isRecording, audio=${AudioRecordingService.isRecording}).")
            return
        }

        val hasProjection = resultCode == Activity.RESULT_OK && resultData != null
        playbackAudioCaptured = false
        startupAudioWarning = null
        if (!hasProjection) {
            emitAudioWarning("screen_capture_permission_required")
            stopSelf()
            return
        }

        // Start Foreground Service with MEDIA_PROJECTION and MICROPHONE types (Android 14+ safe)
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val fgsType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                }
                if (fgsType != 0) {
                    startForeground(NOTIFICATION_ID, notification, fgsType)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to startForeground for video: ${e.message}")
            stopSelf()
            return
        }

        acquireWakeLock()

        // Nested folder hierarchy: <StorageDir>/<AppSource>/<SanitizedCallerNumber>/<Timestamp>.mp4
        outputFile = AppSettingsHelper.getRecordingOutputFile(this, appSource, callerNumber, "mp4")
        outputFile?.parentFile?.mkdirs()

        var initialized = false
        if (hasProjection) {
            initialized = startMediaProjectionCapture(resultCode, resultData!!)
        }

        if (!initialized) {
            Log.e(TAG, "MediaProjection video capture failed to start.")
            emitAudioWarning("screen_capture_start_failed")
            outputFile?.delete()
            releaseWakeLock()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        isRecording = true
        currentSource = appSource
        currentCaller = callerNumber
        recordStartTime = System.currentTimeMillis()
        Log.i(TAG, "Video recording started -> ${outputFile?.absolutePath}")

        onStatusListener?.invoke("recording_started", mapOf(
            "filePath" to (outputFile?.absolutePath ?: ""),
            "callerNumber" to callerNumber,
            "appSource" to appSource,
            "mediaType" to "video"
        ))
        startupAudioWarning?.let(::emitAudioWarning)
    }

    private fun startMediaProjectionCapture(resultCode: Int, resultData: Intent): Boolean {
        return try {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                ?: return false
            val projection = projectionManager.getMediaProjection(resultCode, resultData) ?: return false
            mediaProjection = projection
            val capturePlaybackAudio = audioSource == "remote_only" || audioSource == "both"
            val includeMicrophone = audioSource == "both"

            val windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager?.defaultDisplay?.getRealMetrics(metrics)

            var w = if (metrics.widthPixels > 0) metrics.widthPixels else 720
            var h = if (metrics.heightPixels > 0) metrics.heightPixels else 1280
            val dpi = if (metrics.densityDpi > 0) metrics.densityDpi else 320

            val largestDimension = maxOf(w, h)
            if (largestDimension > 1280) {
                val scale = 1280.0 / largestDimension
                w = (w * scale).toInt()
                h = (h * scale).toInt()
            }
            val width = (w / 2) * 2
            val height = (h / 2) * 2

            val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            if (audioSource == "mic_only") {
                recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            }
            recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            if (audioSource == "mic_only") {
                recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            }
            recorder.setVideoSize(width, height)
            recorder.setVideoEncodingBitRate(1200000)
            recorder.setVideoFrameRate(24)
            if (audioSource == "mic_only") {
                recorder.setAudioSamplingRate(22050)
                recorder.setAudioEncodingBitRate(64000)
            }
            recorder.setOutputFile(outputFile?.absolutePath)
            recorder.prepare()

            mediaRecorder = recorder

            // Android 14+ requires MediaProjection.Callback registered before createVirtualDisplay
            val projectionCallback = object : MediaProjection.Callback() {
                override fun onStop() {
                    super.onStop()
                    Log.i(TAG, "MediaProjection session stopped by system.")
                    stopVideoRecordingInternal()
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                projection.registerCallback(projectionCallback, mainHandler)
            } else {
                projection.registerCallback(projectionCallback, null)
            }
            mediaProjectionCallback = projectionCallback

            virtualDisplay = projection.createVirtualDisplay(
                "RecordCall-ScreenCapture",
                width,
                height,
                dpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                recorder.surface,
                null,
                null
            )

            recorder.start()
            if (capturePlaybackAudio) {
                val playbackFile = File(
                    outputFile?.parentFile,
                    "${outputFile?.nameWithoutExtension}_playback.m4a"
                )
                val capture = PlaybackAudioCaptureRecorder(
                    projection,
                    playbackFile,
                    includeMicrophone
                )
                if (capture.start()) {
                    playbackAudioFile = playbackFile
                    playbackAudioCapture = capture
                } else {
                    playbackFile.delete()
                    startupAudioWarning = "screen_system_audio_unavailable"
                }
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "startMediaProjectionCapture failed: ${e.message}", e)
            cleanUpRecorder()
            false
        }
    }

    private fun stopVideoRecordingInternal() {
        if (!isRecording) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        isRecording = false

        val durationMs = System.currentTimeMillis() - recordStartTime
        val durationSec = (durationMs / 1000).toInt()

        try {
            mediaRecorder?.stop()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping mediaRecorder: ${e.message}")
        } finally {
            if (audioSource == "remote_only") {
                playbackAudioFile = playbackAudioCapture?.stop()
            } else if (audioSource == "both") {
                val capture = playbackAudioCapture
                playbackAudioFile = capture?.stop()
                playbackAudioCaptured = capture?.hasPlaybackAudio == true
            }
            playbackAudioCapture = null
            cleanUpRecorder()
            releaseWakeLock()
        }

        val file = outputFile
        if ((audioSource == "remote_only" || audioSource == "both") &&
            file != null && file.exists()
        ) {
            val capturedAudio = playbackAudioFile
            val muxed = PlaybackAudioMuxer.replaceVideoAudio(file, capturedAudio)
            if (muxed) {
                capturedAudio?.delete()
            } else if (capturedAudio != null && capturedAudio.exists()) {
                savePlaybackAudioSeparately(capturedAudio, durationSec)
            }
            playbackAudioFile = null
            if (!muxed || capturedAudio == null ||
                (audioSource == "both" && !playbackAudioCaptured)
            ) {
                emitAudioWarning("screen_system_audio_unavailable")
            }
        } else {
            playbackAudioCapture?.stop()?.delete()
            playbackAudioCapture = null
            playbackAudioFile?.delete()
            playbackAudioFile = null
        }
        val fileSize = file?.length() ?: 0L

        if (file != null && file.exists() && fileSize > 512) {
            Log.i(TAG, "Video recording saved: ${file.absolutePath} ($fileSize bytes, ${durationSec}s)")
            val metadata = RecordingMetadata(
                filePath = file.absolutePath,
                callerNumber = callerNumber,
                appSource = appSource,
                durationSec = durationSec,
                fileSize = fileSize,
                createdAt = recordStartTime,
                mediaType = "video"
            )

            RecordingQueueManager.enqueue(this, metadata)

            onStatusListener?.invoke("recording_completed", mapOf(
                "filePath" to metadata.filePath,
                "callerNumber" to metadata.callerNumber,
                "appSource" to metadata.appSource,
                "durationSec" to metadata.durationSec,
                "fileSize" to metadata.fileSize,
                "createdAt" to metadata.createdAt,
                "mediaType" to "video"
            ))
        } else {
            Log.w(TAG, "Video recording file was empty or missing. Discarding: ${file?.absolutePath}")
            file?.delete()
        }

        currentSource = "Idle"
        currentCaller = ""
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "RecordCall::VideoRecordingWakeLock"
            )?.apply {
                acquire(15 * 60 * 1000L)
            }
        } catch (e: Exception) {
            Log.w(TAG, "WakeLock error: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "WakeLock release error: ${e.message}")
        } finally {
            wakeLock = null
        }
    }

    private fun cleanUpRecorder() {
        try {
            virtualDisplay?.release()
        } catch (_: Exception) {}
        virtualDisplay = null

        try {
            mediaProjectionCallback?.let { cb ->
                mediaProjection?.unregisterCallback(cb)
            }
        } catch (_: Exception) {}
        mediaProjectionCallback = null

        try {
            mediaProjection?.stop()
        } catch (_: Exception) {}
        mediaProjection = null

        try {
            mediaRecorder?.reset()
            mediaRecorder?.release()
        } catch (_: Exception) {}
        mediaRecorder = null
    }

    private fun emitAudioWarning(messageKey: String) {
        onStatusListener?.invoke("recording_warning", mapOf("messageKey" to messageKey))
    }

    private fun savePlaybackAudioSeparately(audioFile: File, durationSec: Int) {
        val audioPath = AppSettingsHelper.getRecordingOutputFile(
            this,
            appSource,
            callerNumber,
            "m4a"
        )
        if (!audioFile.renameTo(audioPath)) {
            Log.w(TAG, "Playback audio remains at ${audioFile.absolutePath}")
        }
        val savedFile = if (audioPath.exists()) audioPath else audioFile
        RecordingQueueManager.enqueue(
            this,
            RecordingMetadata(
                filePath = savedFile.absolutePath,
                callerNumber = callerNumber,
                appSource = appSource,
                durationSec = durationSec,
                fileSize = savedFile.length(),
                createdAt = recordStartTime,
                mediaType = "audio"
            )
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isRecording) {
            stopVideoRecordingInternal()
        }
    }
}
