package mn.callrecorder.record_calls

import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.util.Log

object AudioEffectsHelper {
    private const val TAG = "AudioEffectsHelper"
    private var agc: AutomaticGainControl? = null
    private var ns: NoiseSuppressor? = null

    fun attachEffects(audioSessionId: Int) {
        if (audioSessionId == 0) return

        try {
            if (AutomaticGainControl.isAvailable()) {
                agc = AutomaticGainControl.create(audioSessionId)?.apply {
                    enabled = true
                    Log.d(TAG, "AutomaticGainControl attached and enabled.")
                }
            } else {
                Log.d(TAG, "AutomaticGainControl not available on this device.")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to initialize AutomaticGainControl: ${e.message}")
        }

        try {
            if (NoiseSuppressor.isAvailable()) {
                ns = NoiseSuppressor.create(audioSessionId)?.apply {
                    enabled = true
                    Log.d(TAG, "NoiseSuppressor attached and enabled.")
                }
            } else {
                Log.d(TAG, "NoiseSuppressor not available on this device.")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to initialize NoiseSuppressor: ${e.message}")
        }
    }

    fun releaseEffects() {
        try {
            agc?.release()
            agc = null
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing AGC: ${e.message}")
        }

        try {
            ns?.release()
            ns = null
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing NS: ${e.message}")
        }
    }
}
