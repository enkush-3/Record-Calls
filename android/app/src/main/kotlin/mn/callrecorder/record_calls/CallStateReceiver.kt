package mn.callrecorder.record_calls

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class CallStateReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallStateReceiver"
        private var lastState = TelephonyManager.EXTRA_STATE_IDLE
        private var savedNumber: String? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            return
        }

        if (!AppSettingsHelper.isAutoRecordEnabled(context)) {
            Log.d(TAG, "Auto-record disabled in settings. Skipping cellular call.")
            return
        }

        val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        if (!incomingNumber.isNullOrEmpty()) {
            savedNumber = incomingNumber
        }

        if (stateStr == lastState) {
            return
        }

        Log.d(TAG, "Telephony state changed: $lastState -> $stateStr (number: $savedNumber)")

        when (stateStr) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                // Incoming call ringing
                if (!incomingNumber.isNullOrEmpty()) {
                    savedNumber = incomingNumber
                }
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                // Call started (incoming answered or outgoing connected)
                val caller = if (!savedNumber.isNullOrEmpty()) savedNumber!! else "Cellular Call"
                Log.i(TAG, "Starting cellular call recording: $caller")
                AudioRecordingService.startRecording(context, caller, "Cellular")
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                // Call ended
                if (lastState == TelephonyManager.EXTRA_STATE_OFFHOOK) {
                    Log.i(TAG, "Cellular call terminated. Stopping recording.")
                    AudioRecordingService.stopRecording(context)
                }
                savedNumber = null
            }
        }

        lastState = stateStr
    }
}
