package mn.callrecorder.record_calls

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import java.nio.file.Files
import java.nio.file.StandardCopyOption

internal object PlaybackAudioMuxer {
    private const val TAG = "PlaybackAudioMuxer"
    private const val DEFAULT_BUFFER_SIZE = 2 * 1024 * 1024

    fun replaceVideoAudio(videoFile: File, playbackAudioFile: File?): Boolean {
        val temporaryFile = File(videoFile.parentFile, "${videoFile.nameWithoutExtension}.mux.mp4")
        val videoExtractor = MediaExtractor()
        val audioExtractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var muxerStarted = false

        return try {
            videoExtractor.setDataSource(videoFile.absolutePath)
            val videoTrack = findTrack(videoExtractor, "video/")
                ?: return false
            videoExtractor.selectTrack(videoTrack)

            val audioTrack = playbackAudioFile?.takeIf { it.exists() }?.let { file ->
                audioExtractor.setDataSource(file.absolutePath)
                findTrack(audioExtractor, "audio/")
            }
            if (audioTrack != null) audioExtractor.selectTrack(audioTrack)

            muxer = MediaMuxer(temporaryFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxedVideoTrack = muxer.addTrack(videoExtractor.getTrackFormat(videoTrack))
            val muxedAudioTrack = audioTrack?.let { muxer.addTrack(audioExtractor.getTrackFormat(it)) }
            muxer.start()
            muxerStarted = true

            writeInterleavedSamples(
                muxer = muxer,
                videoExtractor = videoExtractor,
                videoTrack = muxedVideoTrack,
                audioExtractor = if (audioTrack != null) audioExtractor else null,
                audioTrack = muxedAudioTrack
            )
            muxer.stop()
            muxerStarted = false
            muxer.release()
            muxer = null
            Files.move(
                temporaryFile.toPath(),
                videoFile.toPath(),
                StandardCopyOption.REPLACE_EXISTING
            )
            true
        } catch (error: Exception) {
            Log.e(TAG, "Could not mux playback audio: ${error.message}", error)
            false
        } finally {
            if (muxerStarted) {
                try { muxer?.stop() } catch (_: IllegalStateException) { }
            }
            muxer?.release()
            videoExtractor.release()
            audioExtractor.release()
            temporaryFile.delete()
        }
    }

    private fun findTrack(extractor: MediaExtractor, mimePrefix: String): Int? {
        for (index in 0 until extractor.trackCount) {
            if (extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)?.startsWith(mimePrefix) == true) {
                return index
            }
        }
        return null
    }

    private fun writeInterleavedSamples(
        muxer: MediaMuxer,
        videoExtractor: MediaExtractor,
        videoTrack: Int,
        audioExtractor: MediaExtractor?,
        audioTrack: Int?
    ) {
        val buffer = ByteBuffer.allocate(DEFAULT_BUFFER_SIZE)
        val info = MediaCodec.BufferInfo()
        var videoDone = false
        var audioDone = audioExtractor == null || audioTrack == null

        while (!videoDone || !audioDone) {
            val videoTime = if (videoDone) Long.MAX_VALUE else videoExtractor.sampleTime
            val audioTime = if (audioDone) Long.MAX_VALUE else audioExtractor?.sampleTime ?: Long.MAX_VALUE
            val writeVideo = videoTime <= audioTime
            val extractor = if (writeVideo) videoExtractor else audioExtractor
            val outputTrack = if (writeVideo) videoTrack else audioTrack
            if (extractor == null || outputTrack == null || extractor.sampleTime < 0L) {
                if (writeVideo) videoDone = true else audioDone = true
                continue
            }

            buffer.clear()
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) {
                if (writeVideo) videoDone = true else audioDone = true
                continue
            }
            info.set(0, size, extractor.sampleTime, extractor.sampleFlags)
            muxer.writeSampleData(outputTrack, buffer, info)
            extractor.advance()
        }
    }
}
