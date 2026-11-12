package mn.callrecorder.record_calls

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File

class AudioRecordingService : Service() {

    companion object {
        private const val TAG = "AudioRecordingService"
        const val CHANNEL_ID = "mn_callrecorder_fgs_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START = "mn.callrecorder.action.START"
        const val ACTION_STOP = "mn.callrecorder.action.STOP"

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

        // Listeners for live amplitude and recording status events
        var onAmplitudeListener: ((amplitude: Double) -> Unit)? = null
        var onStatusListener: ((status: String, details: Map<String, Any>) -> Unit)? = null

        fun startRecording(
            context: Context,
            callerNumber: String,
            appSource: String,
            audioSource: String? = null
        ) {
            val intent = Intent(context, AudioRecordingService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_CALLER_NUMBER, callerNumber)
                putExtra(EXTRA_APP_SOURCE, appSource)
                putExtra(EXTRA_AUDIO_SOURCE, audioSource)
            }
            try {
                ContextCompat.startForegroundService(context, intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start foreground service: ${e.message}")
            }
        }

        fun stopRecording(context: Context) {
            val intent = Intent(context, AudioRecordingService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.startService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send stop service: ${e.message}")
            }
        }
    }

    private var mediaRecorder: MediaRecorder? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var outputFile: File? = null
    private var recordStartTime: Long = 0
    private var callerNumber: String = "Unknown"
    private var appSource: String = "Cellular"
    private var audioSourceOverride: String? = null
    private var activeAudioInputSource: Int? = null
    private var currentAudioChannel: String = "both"
    private var maximumObservedAmplitude: Int = 0

    private val handler = Handler(Looper.getMainLooper())
    private val amplitudeRunnable = object : Runnable {
        override fun run() {
            if (isRecording && mediaRecorder != null) {
                try {
                    val maxAmp = mediaRecorder?.maxAmplitude ?: 0
                    maximumObservedAmplitude = maxOf(maximumObservedAmplitude, maxAmp)
                    // Normalize amplitude roughly between 0.0 and 1.0
                    val normalized = (maxAmp / 32767.0).coerceIn(0.0, 1.0)
                    onAmplitudeListener?.invoke(normalized)
                } catch (e: Exception) {
                    // Ignore transient errors when stopping
                }
                handler.postDelayed(this, 100)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                callerNumber = intent.getStringExtra(EXTRA_CALLER_NUMBER) ?: "Unknown"
                appSource = intent.getStringExtra(EXTRA_APP_SOURCE) ?: "Cellular"
                audioSourceOverride = intent.getStringExtra(EXTRA_AUDIO_SOURCE)
                startRecordingInternal()
            }
            ACTION_STOP -> {
                stopRecordingInternal()
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
                "Call Recorder Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifies when call recording is actively recording in the background."
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
            .setContentTitle("Record Call")
            .setContentText("Recording $appSource call: $callerNumber")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startRecordingInternal() {
        if (isRecording || VideoRecordingService.isRecording) {
            Log.d(TAG, "Already recording (audio=$isRecording, video=${VideoRecordingService.isRecording}). Ignoring start request.")
            return
        }

        // Android 14/15 FGS pre-flight permission check
        val hasMicPermission = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasMicPermission) {
            Log.e(TAG, "RECORD_AUDIO permission missing! Aborting foreground start.")
            stopSelf()
            return
        }

        try {
            // Start Foreground with Microphone type for Android 14/15
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground with microphone type: ${e.message}")
            stopSelf()
            return
        }

        // Acquire Partial WakeLock
        acquireWakeLock()

        outputFile = AppSettingsHelper.getRecordingOutputFile(this, appSource, callerNumber, "m4a")

        val audioChannel = audioSourceOverride
            ?: AppSettingsHelper.getAudioRecordingSource(this)
        currentAudioChannel = audioChannel
        maximumObservedAmplitude = 0
        fun tryInitWithConfiguredSources(): Boolean {
            return when (audioChannel) {
                "mic_only" -> {
                    // Own voice only
                    initMediaRecorder(MediaRecorder.AudioSource.MIC) ||
                    initMediaRecorder(MediaRecorder.AudioSource.VOICE_RECOGNITION)
                }
                "remote_only" -> {
                    // Android may reject these privileged call-audio sources.
                    initMediaRecorder(MediaRecorder.AudioSource.VOICE_DOWNLINK) ||
                    initMediaRecorder(MediaRecorder.AudioSource.VOICE_CALL)
                }
                else -> {
                    // Both streams (Mic + Remote incoming audio)
                    initMediaRecorder(MediaRecorder.AudioSource.VOICE_COMMUNICATION) ||
                    initMediaRecorder(MediaRecorder.AudioSource.VOICE_RECOGNITION) ||
                    initMediaRecorder(MediaRecorder.AudioSource.MIC)
                }
            }
        }

        var success = tryInitWithConfiguredSources()

        // If recording failed and we used a custom folder, retry once with the default directory
        if (!success) {
            val defaultPath = AppSettingsHelper.getDefaultStorageDirectory(this)
            val baseSource = AppSettingsHelper.sanitizeAppSource(appSource)
            val baseCaller = AppSettingsHelper.sanitizeCallerNumber(callerNumber)
            val fallbackFolder = File(defaultPath, "Audio/$baseSource/$baseCaller")
            if (!fallbackFolder.exists()) {
                fallbackFolder.mkdirs()
            }
            outputFile = AppSettingsHelper.nextAvailableRecordingFile(fallbackFolder, "m4a")
            success = tryInitWithConfiguredSources()
        }

        if (!success) {
            Log.e(TAG, "Failed to initialize MediaRecorder with either audio source.")
            if (audioChannel == "remote_only") {
                onStatusListener?.invoke(
                    "recording_warning",
                    mapOf("messageKey" to "remote_call_audio_unavailable")
                )
            }
            releaseWakeLock()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        val callAudioWarning = if (audioChannel == "both" &&
            (audioSourceOverride != null ||
                activeAudioInputSource != MediaRecorder.AudioSource.VOICE_COMMUNICATION)
        ) "audio_both_call_audio_limited" else null

        try {
            mediaRecorder?.start()
            isRecording = true
            currentSource = appSource
            currentCaller = callerNumber
            recordStartTime = System.currentTimeMillis()
            Log.i(TAG, "Recording started -> ${outputFile?.absolutePath}")

            // Attach hardware AGC and NoiseSuppressor if available
            try {
                mediaRecorder?.let {
                    // Audio session effects
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        AudioEffectsHelper.attachEffects(it.activeRecordingConfiguration?.clientAudioSessionId ?: 0)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "AudioEffectsHelper attach warning: ${e.message}")
            }

            // Start amplitude polling
            handler.post(amplitudeRunnable)

            // Notify UI
            onStatusListener?.invoke("recording_started", mapOf(
                "filePath" to (outputFile?.absolutePath ?: ""),
                "callerNumber" to callerNumber,
                "appSource" to appSource,
                "mediaType" to "audio"
            ))
            callAudioWarning?.let { warningKey ->
                onStatusListener?.invoke(
                    "recording_warning",
                    mapOf("messageKey" to warningKey)
                )
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error starting MediaRecorder: ${e.message}", e)
            if (audioChannel == "remote_only") {
                onStatusListener?.invoke(
                    "recording_warning",
                    mapOf("messageKey" to "remote_call_audio_unavailable")
                )
            }
            cleanUpRecorder()
            releaseWakeLock()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun initMediaRecorder(audioSource: Int): Boolean {
        return try {
            cleanUpRecorder()
            val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            recorder.setAudioSource(audioSource)
            recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            recorder.setAudioSamplingRate(22050)
            recorder.setAudioEncodingBitRate(64000)
            recorder.setOutputFile(outputFile?.absolutePath)
            recorder.prepare()

            mediaRecorder = recorder
            activeAudioInputSource = audioSource
            Log.d(TAG, "MediaRecorder prepared successfully with source $audioSource")
            true
        } catch (e: Exception) {
            Log.w(TAG, "AudioSource $audioSource failed: ${e.message}")
            cleanUpRecorder()
            false
        }
    }

    private fun stopRecordingInternal() {
        if (!isRecording) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        handler.removeCallbacks(amplitudeRunnable)
        val durationMs = System.currentTimeMillis() - recordStartTime
        val durationSec = (durationMs / 1000).toInt()
        val remoteCallAudioWasSilent = currentAudioChannel == "remote_only" &&
            maximumObservedAmplitude == 0

        try {
            mediaRecorder?.stop()
        } catch (e: Exception) {
            Log.w(TAG, "Exception while stopping MediaRecorder: ${e.message}")
        } finally {
            cleanUpRecorder()
            AudioEffectsHelper.releaseEffects()
            releaseWakeLock()
        }

        isRecording = false
        val file = outputFile
        val fileSize = file?.length() ?: 0L

        if (file != null && file.exists() && fileSize > 1024) {
            Log.i(TAG, "Recording saved: ${file.absolutePath} ($fileSize bytes, ${durationSec}s)")
            val metadata = RecordingMetadata(
                filePath = file.absolutePath,
                callerNumber = callerNumber,
                appSource = appSource,
                durationSec = durationSec,
                fileSize = fileSize,
                createdAt = recordStartTime,
                mediaType = "audio"
            )

            // Persist to offline queue in SharedPreferences
            RecordingQueueManager.enqueue(this, metadata)

            // Notify UI if listener attached
            onStatusListener?.invoke("recording_completed", mapOf(
                "filePath" to metadata.filePath,
                "callerNumber" to metadata.callerNumber,
                "appSource" to metadata.appSource,
                "durationSec" to metadata.durationSec,
                "fileSize" to metadata.fileSize,
                "createdAt" to metadata.createdAt,
                "mediaType" to "audio"
            ))
        } else {
            Log.w(TAG, "Recording file was empty or too small. Discarding: ${file?.absolutePath}")
            file?.delete()
        }

        currentSource = "Idle"
        currentCaller = ""
        if (remoteCallAudioWasSilent) {
            onStatusListener?.invoke(
                "recording_warning",
                mapOf("messageKey" to "remote_call_audio_unavailable")
            )
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "RecordCall::RecordingWakeLock"
            )?.apply {
                acquire(10 * 60 * 1000L /* 10 minutes max fallback */)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not acquire WakeLock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing WakeLock: ${e.message}")
        } finally {
            wakeLock = null
        }
    }

    private fun cleanUpRecorder() {
        try {
            mediaRecorder?.reset()
            mediaRecorder?.release()
        } catch (e: Exception) {
            // Ignore reset/release errors
        } finally {
            mediaRecorder = null
            activeAudioInputSource = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isRecording) {
            stopRecordingInternal()
        }
        handler.removeCallbacks(amplitudeRunnable)
    }
}
