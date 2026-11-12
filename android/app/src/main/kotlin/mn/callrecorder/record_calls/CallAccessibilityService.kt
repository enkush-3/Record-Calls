package mn.callrecorder.record_calls

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.media.AudioManager
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class CallAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "CallAccessibility"

        private val VOIP_PACKAGES = mapOf(
            "com.viber.voip" to "Viber",
            "org.telegram.messenger" to "Telegram",
            "com.whatsapp" to "WhatsApp",
            "com.facebook.orca" to "Messenger",
            "com.tencent.mm" to "WeChat",
            "com.instagram.android" to "Instagram",
            "com.instagram.lite" to "Instagram",
            "com.discord" to "Discord",
            "org.thoughtcrime.securesms" to "Signal",
            "jp.naver.line.android" to "LINE",
            "com.skype.raider" to "Skype"
        )

        @Volatile
        var isServiceConnected: Boolean = false
            private set
    }

    private var activeVoipApp: String? = null
    private var isVoipRecordingActive: Boolean = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceConnected = true
        Log.i(TAG, "CallAccessibilityService connected and ready.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        val appName = VOIP_PACKAGES[packageName] ?: return

        if (!AppSettingsHelper.isAutoRecordEnabled(this)) {
            return
        }

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val audioMode = audioManager.mode

        val isInCall = audioMode == AudioManager.MODE_IN_COMMUNICATION ||
                       audioMode == AudioManager.MODE_IN_CALL

        Log.d(TAG, "VoIP event from $appName ($packageName), mode=$audioMode, isInCall=$isInCall")

        if (isInCall) {
            if (!isVoipRecordingActive && !AudioRecordingService.isRecording && !VideoRecordingService.isRecording) {
                Log.i(TAG, "Detected active VoIP call in $appName. Starting recording...")
                activeVoipApp = appName
                isVoipRecordingActive = true
                val caller = extractCallerIdentifier(event, appName)
                AudioRecordingService.startRecording(this, caller, appName)
            }
        } else {
            // Check if call ended
            if (isVoipRecordingActive && activeVoipApp == appName) {
                if (audioMode == AudioManager.MODE_NORMAL) {
                    Log.i(TAG, "VoIP call in $appName ended (mode normal). Stopping recording.")
                    AudioRecordingService.stopRecording(this)
                    isVoipRecordingActive = false
                    activeVoipApp = null
                }
            }
        }
    }

    private fun extractCallerIdentifier(event: AccessibilityEvent, appName: String): String {
        // 1. Check event text list
        for (charSeq in event.text) {
            val text = charSeq?.toString()?.trim() ?: continue
            if (isValidCallerText(text, appName)) {
                return text
            }
        }

        // 2. Check event contentDescription
        val desc = event.contentDescription?.toString()?.trim()
        if (desc != null && isValidCallerText(desc, appName)) {
            return desc
        }

        // 3. Inspect active window root
        try {
            val root = rootInActiveWindow
            if (root != null) {
                val candidate = findCallerTextInNode(root, appName)
                if (!candidate.isNullOrBlank()) {
                    return candidate
                }
            }
        } catch (_: Exception) {}

        return "Unknown_Caller"
    }

    private fun isValidCallerText(text: String, appName: String): Boolean {
        if (text.length < 2 || text.length > 50) return false
        val lower = text.lowercase(java.util.Locale.US)
        if (lower == appName.lowercase(java.util.Locale.US)) return false
        val ignoredWords = setOf(
            "calling", "incoming", "outgoing", "call", "mute", "speaker", "video",
            "bluetooth", "cancel", "decline", "answer", "hold", "add", "keypad",
            "end", "audio", "mic", "wechat", "whatsapp", "telegram", "viber", "messenger",
            "дуудлага", "ярьж байна", "record"
        )
        return !ignoredWords.contains(lower)
    }

    private fun findCallerTextInNode(node: android.view.accessibility.AccessibilityNodeInfo, appName: String): String? {
        val text = node.text?.toString()?.trim()
        if (text != null && isValidCallerText(text, appName)) {
            return text
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findCallerTextInNode(child, appName)
            if (found != null) return found
        }
        return null
    }

    override fun onInterrupt() {
        Log.w(TAG, "CallAccessibilityService interrupted.")
        if (isVoipRecordingActive) {
            AudioRecordingService.stopRecording(this)
            isVoipRecordingActive = false
            activeVoipApp = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceConnected = false
        if (isVoipRecordingActive) {
            AudioRecordingService.stopRecording(this)
            isVoipRecordingActive = false
            activeVoipApp = null
        }
    }
}
