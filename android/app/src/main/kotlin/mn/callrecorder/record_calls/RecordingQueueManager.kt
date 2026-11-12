package mn.callrecorder.record_calls

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

data class RecordingMetadata(
    val filePath: String,
    val callerNumber: String,
    val appSource: String,
    val durationSec: Int,
    val fileSize: Long,
    val createdAt: Long,
    val isFavorite: Int = 0,
    val notes: String = "",
    val mediaType: String = "audio"
) {
    fun toJsonObject(): JSONObject {
        return JSONObject().apply {
            put("filePath", filePath)
            put("callerNumber", callerNumber)
            put("appSource", appSource)
            put("durationSec", durationSec)
            put("fileSize", fileSize)
            put("createdAt", createdAt)
            put("isFavorite", isFavorite)
            put("notes", notes)
            put("mediaType", mediaType)
        }
    }

    companion object {
        fun fromJsonObject(json: JSONObject): RecordingMetadata {
            return RecordingMetadata(
                filePath = json.optString("filePath", ""),
                callerNumber = json.optString("callerNumber", "Unknown"),
                appSource = json.optString("appSource", "Cellular"),
                durationSec = json.optInt("durationSec", 0),
                fileSize = json.optLong("fileSize", 0L),
                createdAt = json.optLong("createdAt", System.currentTimeMillis()),
                isFavorite = json.optInt("isFavorite", 0),
                notes = json.optString("notes", ""),
                mediaType = json.optString("mediaType", "audio")
            )
        }
    }
}

object RecordingQueueManager {
    private const val PREF_NAME = "mn_callrecorder_offline_queue"
    private const val KEY_PENDING_RECORDINGS = "pending_recordings"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.applicationContext.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    @Synchronized
    fun enqueue(context: Context, metadata: RecordingMetadata) {
        val prefs = getPrefs(context)
        val raw = prefs.getString(KEY_PENDING_RECORDINGS, "[]") ?: "[]"
        val array = try {
            JSONArray(raw)
        } catch (e: Exception) {
            JSONArray()
        }
        array.put(metadata.toJsonObject())
        prefs.edit().putString(KEY_PENDING_RECORDINGS, array.toString()).apply()
    }

    @Synchronized
    fun dequeueAll(context: Context): List<RecordingMetadata> {
        val prefs = getPrefs(context)
        val raw = prefs.getString(KEY_PENDING_RECORDINGS, "[]") ?: "[]"
        val list = mutableListOf<RecordingMetadata>()
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val item = RecordingMetadata.fromJsonObject(obj)
                if (File(item.filePath).exists()) {
                    list.add(item)
                }
            }
        } catch (e: Exception) {
            // Log and return empty list on parsing failure
        }
        // Clear queue once dequeued
        prefs.edit().remove(KEY_PENDING_RECORDINGS).apply()
        return list
    }

    @Synchronized
    fun getPendingCount(context: Context): Int {
        val prefs = getPrefs(context)
        val raw = prefs.getString(KEY_PENDING_RECORDINGS, "[]") ?: "[]"
        return try {
            JSONArray(raw).length()
        } catch (e: Exception) {
            0
        }
    }
}
