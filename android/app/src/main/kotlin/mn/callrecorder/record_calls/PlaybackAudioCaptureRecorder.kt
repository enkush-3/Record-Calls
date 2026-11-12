package mn.callrecorder.record_calls

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

internal class PlaybackAudioCaptureRecorder(
    private val projection: MediaProjection,
    private val outputFile: File,
    private val includeMicrophone: Boolean = false
) {
    companion object {
        private const val TAG = "PlaybackAudioCapture"
        private const val SAMPLE_RATE = 22050
        private const val AUDIO_BIT_RATE = 64000
        private const val CHANNEL_COUNT = 1
        private const val TIMEOUT_US = 10_000L
        private const val EOS_DRAIN_TIMEOUT_MS = 5_000L
        private const val NON_SILENT_THRESHOLD = 8
    }

    @Volatile private var isCapturing = false
    @Volatile private var hasNonSilentAudio = false
    @Volatile var hasPlaybackAudio = false
        private set
    @Volatile private var stopDeadlineNanos = 0L
    @Volatile private var captureFailed = false
    private var playbackAudioRecord: AudioRecord? = null
    private var microphoneAudioRecord: AudioRecord? = null
    private var microphoneBuffer: ByteBuffer? = null
    private var encoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var encoderThread: Thread? = null
    private var muxerTrack = -1
    private var muxerStarted = false

    fun start(): Boolean {
        return try {
            val audioFormat = AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(SAMPLE_RATE)
                .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                .build()
            val playbackConfig = AudioPlaybackCaptureConfiguration.Builder(projection)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .build()
            val minimumBufferSize = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            if (minimumBufferSize <= 0) return false

            playbackAudioRecord = AudioRecord.Builder()
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(minimumBufferSize * 2)
                .setAudioPlaybackCaptureConfig(playbackConfig)
                .build()
            if (includeMicrophone) {
                microphoneBuffer = ByteBuffer.allocateDirect(minimumBufferSize * 2)
                    .order(ByteOrder.LITTLE_ENDIAN)
                microphoneAudioRecord = AudioRecord.Builder()
                    .setAudioSource(MediaRecorder.AudioSource.MIC)
                    .setAudioFormat(audioFormat)
                    .setBufferSizeInBytes(minimumBufferSize * 2)
                    .build()
            }
            encoder = createEncoder(minimumBufferSize)
            muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            playbackAudioRecord?.startRecording()
            microphoneAudioRecord?.startRecording()
            encoder?.start()
            isCapturing = true
            encoderThread = Thread(::encodePlaybackAudio, "PlaybackAudioEncoder").also { it.start() }
            true
        } catch (error: Exception) {
            Log.w(TAG, "Playback capture could not start: ${error.message}")
            releaseResources()
            false
        }
    }

    fun stop(): File? {
        isCapturing = false
        stopDeadlineNanos = System.nanoTime() + EOS_DRAIN_TIMEOUT_MS * 1_000_000L
        try {
            playbackAudioRecord?.stop()
        } catch (_: IllegalStateException) {
            // The recorder may already have stopped after a device-level error.
        }
        try {
            microphoneAudioRecord?.stop()
        } catch (_: IllegalStateException) {
            // The recorder may already have stopped after a device-level error.
        }
        if (!joinEncoderThread()) {
            synchronized(this) {
                captureFailed = true
                outputFile.delete()
            }
            Log.w(TAG, "Audio encoder did not stop before the deadline")
            return null
        }
        return outputFile.takeIf {
            !captureFailed && hasNonSilentAudio && it.exists() && it.length() > 0L
        }
            ?: run {
                outputFile.delete()
                null
            }
    }

    private fun createEncoder(maxInputSize: Int): MediaCodec {
        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, SAMPLE_RATE, CHANNEL_COUNT)
        format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        format.setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BIT_RATE)
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, maxInputSize)
        return MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC).apply {
            configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        }
    }

    private fun encodePlaybackAudio() {
        val outputInfo = MediaCodec.BufferInfo()
        var totalFrames = 0L
        var inputEnded = false
        var outputEnded = false
        try {
            while (!outputEnded) {
                if (!inputEnded) {
                    val inputIndex = encoder?.dequeueInputBuffer(TIMEOUT_US) ?: -1
                    if (inputIndex >= 0) {
                        val input = encoder?.getInputBuffer(inputIndex)
                        if (input != null) {
                            input.clear()
                                input.order(ByteOrder.LITTLE_ENDIAN)
                            if (isCapturing) {
                                val read = if (includeMicrophone) {
                                    readMixedAudio(input)
                                } else {
                                    playbackAudioRecord?.read(
                                        input,
                                        input.remaining(),
                                        AudioRecord.READ_BLOCKING
                                    ) ?: 0
                                }
                                if (read > 0) {
                                    if (!includeMicrophone) {
                                        hasPlaybackAudio = hasPlaybackAudio ||
                                            containsAudio(input, read)
                                    }
                                    hasNonSilentAudio = hasNonSilentAudio || containsAudio(input, read)
                                    val presentationTimeUs = totalFrames * 1_000_000L / SAMPLE_RATE
                                    totalFrames += read / 2
                                    encoder?.queueInputBuffer(
                                        inputIndex,
                                        0,
                                        read,
                                        presentationTimeUs,
                                        0
                                    )
                                } else if (read < 0) {
                                    isCapturing = false
                                    queueEndOfStream(inputIndex, totalFrames)
                                    inputEnded = true
                                } else {
                                    encoder?.queueInputBuffer(inputIndex, 0, 0, 0L, 0)
                                }
                            } else {
                                queueEndOfStream(inputIndex, totalFrames)
                                inputEnded = true
                            }
                        }
                    }
                }
                outputEnded = drainEncoder(outputInfo)
                if (!isCapturing && stopDeadlineNanos > 0L &&
                    System.nanoTime() >= stopDeadlineNanos
                ) {
                    captureFailed = true
                    Log.w(TAG, "Timed out while draining AAC encoder")
                    break
                }
            }
        } catch (error: Exception) {
            captureFailed = true
            Log.e(TAG, "Playback audio encoding failed: ${error.message}", error)
        } finally {
            synchronized(this) {
                finishMuxer()
                if (captureFailed) outputFile.delete()
                releaseResources()
            }
        }
    }

    private fun containsAudio(buffer: ByteBuffer, byteCount: Int): Boolean {
        val originalPosition = buffer.position()
        val originalLimit = buffer.limit()
        buffer.position(0)
        buffer.limit(byteCount.coerceAtMost(buffer.capacity()))
        while (buffer.remaining() >= 2) {
            if (kotlin.math.abs(buffer.short.toInt()) > NON_SILENT_THRESHOLD) {
                buffer.position(originalPosition)
                buffer.limit(originalLimit)
                return true
            }
        }
        buffer.position(originalPosition)
        buffer.limit(originalLimit)
        return false
    }

    private fun readMixedAudio(input: ByteBuffer): Int {
        val microphone = microphoneAudioRecord ?: return -1
        val micBuffer = microphoneBuffer ?: return -1
        micBuffer.clear()
        input.clear()
        val requestedBytes = minOf(input.remaining(), micBuffer.remaining())
        val microphoneBytes = microphone.read(
            micBuffer,
            requestedBytes,
            AudioRecord.READ_BLOCKING
        )
        if (microphoneBytes < 0) return microphoneBytes

        val playbackBytes = playbackAudioRecord?.read(
            input,
            requestedBytes,
            AudioRecord.READ_NON_BLOCKING
        ) ?: 0
        if (playbackBytes < 0) return playbackBytes
        hasPlaybackAudio = hasPlaybackAudio || containsAudio(input, playbackBytes)

        val outputBytes = maxOf(microphoneBytes, playbackBytes) and -2
        for (offset in 0 until outputBytes step 2) {
            val hasMicrophoneSample = offset < microphoneBytes
            val hasPlaybackSample = offset < playbackBytes
            val microphoneSample = if (hasMicrophoneSample) micBuffer.getShort(offset).toInt() else 0
            val playbackSample = if (hasPlaybackSample) input.getShort(offset).toInt() else 0
            val mixedSample = when {
                hasMicrophoneSample && hasPlaybackSample ->
                    (microphoneSample + playbackSample) / 2
                hasMicrophoneSample -> microphoneSample
                hasPlaybackSample -> playbackSample
                else -> 0
            }
            input.putShort(offset, mixedSample.toShort())
        }
        input.position(0)
        input.limit(outputBytes)
        return outputBytes
    }

    private fun queueEndOfStream(inputIndex: Int, totalFrames: Long) {
        encoder?.queueInputBuffer(
            inputIndex,
            0,
            0,
            totalFrames * 1_000_000L / SAMPLE_RATE,
            MediaCodec.BUFFER_FLAG_END_OF_STREAM
        )
    }

    private fun drainEncoder(info: MediaCodec.BufferInfo): Boolean {
        val codec = encoder ?: return true
        when (val outputIndex = codec.dequeueOutputBuffer(info, TIMEOUT_US)) {
            MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                muxerTrack = muxer?.addTrack(codec.outputFormat) ?: -1
                if (muxerTrack >= 0) {
                    muxer?.start()
                    muxerStarted = true
                }
            }
            MediaCodec.INFO_TRY_AGAIN_LATER -> return false
            else -> if (outputIndex >= 0) {
                val encoded = codec.getOutputBuffer(outputIndex)
                val isCodecConfig = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                if (encoded != null && info.size > 0 && !isCodecConfig && muxerStarted) {
                    encoded.position(info.offset)
                    encoded.limit(info.offset + info.size)
                    muxer?.writeSampleData(muxerTrack, encoded, info)
                }
                val ended = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                codec.releaseOutputBuffer(outputIndex, false)
                return ended
            }
        }
        return false
    }

    private fun finishMuxer() {
        try {
            if (muxerStarted) muxer?.stop()
        } catch (_: IllegalStateException) {
            Log.w(TAG, "Audio muxer stopped without a complete track")
        } finally {
            muxerStarted = false
        }
    }

    private fun joinEncoderThread(): Boolean {
        val thread = encoderThread ?: return true
        return try {
            thread.join(EOS_DRAIN_TIMEOUT_MS + 1_000L)
            !thread.isAlive
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            false
        }
    }

    private fun releaseResources() {
        try {
            playbackAudioRecord?.release()
        } catch (_: IllegalStateException) {
            Log.w(TAG, "AudioRecord was already released")
        }
        playbackAudioRecord = null
        try {
            microphoneAudioRecord?.release()
        } catch (_: IllegalStateException) {
            Log.w(TAG, "Microphone AudioRecord was already released")
        }
        microphoneAudioRecord = null
        microphoneBuffer = null
        try {
            encoder?.stop()
        } catch (_: IllegalStateException) {
            Log.w(TAG, "Audio encoder was not running")
        }
        try {
            encoder?.release()
        } catch (_: IllegalStateException) {
            Log.w(TAG, "Audio encoder was already released")
        }
        encoder = null
        try {
            muxer?.release()
        } catch (_: IllegalStateException) {
            Log.w(TAG, "Audio muxer was already released")
        }
        muxer = null
    }
}
