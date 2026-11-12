package mn.callrecorder.record_calls

import android.content.Context
import android.content.SharedPreferences
import android.os.Environment
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object AppSettingsHelper {
    private const val PREFS_NAME = "mn_callrecorder_settings"
    private const val KEY_AUTO_RECORD = "auto_record_enabled"
    private const val KEY_STORAGE_DIRECTORY = "storage_directory"
    private const val KEY_AUDIO_SOURCE = "audio_recording_source"
    private var lastOutputTimestamp = 0L

    private fun getPrefs(context: Context): SharedPreferences {
        return context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getAudioRecordingSource(context: Context): String {
        return getPrefs(context).getString(KEY_AUDIO_SOURCE, "both") ?: "both"
    }

    fun setAudioRecordingSource(context: Context, source: String) {
        getPrefs(context).edit().putString(KEY_AUDIO_SOURCE, source).apply()
    }

    fun isAutoRecordEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_AUTO_RECORD, true)
    }

    fun setAutoRecordEnabled(context: Context, enabled: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_AUTO_RECORD, enabled).apply()
    }

    fun isWritableDirectory(dir: File): Boolean {
        return try {
            if (!dir.exists()) {
                val created = dir.mkdirs()
                if (!created && !dir.exists()) {
                    return false
                }
            }
            if (!dir.isDirectory) {
                return false
            }
            // Test actual write capability by creating and immediately deleting a test file
            val testFile = File(dir, ".record_call_write_test_${System.currentTimeMillis()}")
            val created = testFile.createNewFile()
            if (created) {
                testFile.delete()
                true
            } else {
                testFile.exists() && testFile.canWrite()
            }
        } catch (e: Exception) {
            false
        }
    }

    fun getDefaultStorageDirectory(context: Context): String {
        // App-specific Documents is writable on Android 10–15 without broad storage
        // permissions. A public Documents directory needs a SAF/MediaStore grant.
        val documentsDir = context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS)
            ?: File(context.filesDir, Environment.DIRECTORY_DOCUMENTS)
        val dir = File(documentsDir, "Record Call")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir.absolutePath
    }

    fun getStorageDirectory(context: Context): String {
        val savedPath = getPrefs(context).getString(KEY_STORAGE_DIRECTORY, null)
        if (!savedPath.isNullOrBlank()) {
            val customDir = File(savedPath)
            if (isWritableDirectory(customDir)) {
                return customDir.absolutePath
            }
        }
        return getDefaultStorageDirectory(context)
    }

    fun setStorageDirectory(context: Context, path: String): Boolean {
        return try {
            val trimmedPath = path.trim().removeSurrounding("\"").removeSurrounding("'")
            if (trimmedPath.isBlank()) {
                return false
            }
            val dir = File(trimmedPath)
            if (!isWritableDirectory(dir)) {
                return false
            }
            getPrefs(context).edit().putString(KEY_STORAGE_DIRECTORY, dir.absolutePath).apply()
            true
        } catch (e: Exception) {
            false
        }
    }

    fun resetStorageDirectory(context: Context): String {
        val defaultPath = getDefaultStorageDirectory(context)
        getPrefs(context).edit().remove(KEY_STORAGE_DIRECTORY).apply()
        return defaultPath
    }

    fun sanitizeAppSource(appSource: String?): String {
        val trimmed = appSource?.trim() ?: ""
        val standard = when (trimmed.lowercase(Locale.US)) {
            "viber" -> "Viber"
            "telegram" -> "Telegram"
            "whatsapp", "watsapp" -> "WhatsApp"
            "wechat" -> "WeChat"
            "messenger", "facebook", "orca" -> "Messenger"
            "instagram" -> "Instagram"
            "discord" -> "Discord"
            "signal" -> "Signal"
            "line" -> "LINE"
            "skype" -> "Skype"
            "cellular", "phone", "call" -> "Phone"
            "manual" -> "Manual"
            else -> trimmed.replace("[^a-zA-Z0-9]".toRegex(), "")
        }
        return if (standard.isNotBlank()) standard else "Manual"
    }

    fun sanitizeCallerNumber(callerNumber: String?): String {
        if (callerNumber.isNullOrBlank()) {
            return "Unknown_Caller"
        }
        val sanitized = callerNumber.trim()
            .replace("[^a-zA-Z0-9+_.-]".toRegex(), "_")
            .replace("_+".toRegex(), "_")
            .trim('_')
        return if (sanitized.isNotBlank() &&
            !sanitized.equals("Unknown", ignoreCase = true) &&
            !sanitized.equals("Unknown_Caller", ignoreCase = true)
        ) {
            sanitized
        } else {
            "Unknown_Caller"
        }
    }

    fun getRecordingOutputFile(
        context: Context,
        appSource: String?,
        callerNumber: String?,
        extension: String?
    ): File {
        val storagePath = getStorageDirectory(context)
        var recordingsDir = File(storagePath)
        if (!recordingsDir.exists()) {
            recordingsDir.mkdirs()
        }

        val defaultPath = getDefaultStorageDirectory(context)
        if (!isWritableDirectory(recordingsDir)) {
            recordingsDir = File(defaultPath)
            if (!recordingsDir.exists()) {
                recordingsDir.mkdirs()
            }
        }

        val sourceDirName = sanitizeAppSource(appSource)
        val callerDirName = sanitizeCallerNumber(callerNumber)

        val mediaType = when (extension?.removePrefix(".")?.lowercase(Locale.US)) {
            "mp4" -> "Video"
            else -> "Audio"
        }
        var targetFolder = File(recordingsDir, "$mediaType/$sourceDirName/$callerDirName")
        if (!targetFolder.exists() && !targetFolder.mkdirs()) {
            // Fallback to default scoped storage directory if custom path creation fails
            recordingsDir = File(defaultPath)
            targetFolder = File(recordingsDir, "$mediaType/$sourceDirName/$callerDirName")
            targetFolder.mkdirs()
        }

        val cleanExt = (extension ?: "m4a").removePrefix(".")
        return nextAvailableRecordingFile(targetFolder, cleanExt)
    }

    @Synchronized
    fun nextAvailableRecordingFile(directory: File, extension: String): File {
        val timestampMillis = maxOf(System.currentTimeMillis(), lastOutputTimestamp + 1L)
        lastOutputTimestamp = timestampMillis
        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss_SSS", Locale.US)
            .format(Date(timestampMillis))
        val cleanExtension = extension.removePrefix(".")
        var candidate = File(directory, "$timestamp.$cleanExtension")
        var suffix = 1
        while (candidate.exists()) {
            candidate = File(directory, "${timestamp}_$suffix.$cleanExtension")
            suffix++
        }
        return candidate
    }

    fun getStorageDirectoryInfo(context: Context): Map<String, Any> {
        val path = getStorageDirectory(context)
        val dir = File(path)
        val exists = dir.exists()
        val writable = isWritableDirectory(dir)
        val freeSpace = if (exists) dir.freeSpace else 0L
        val totalSpace = if (exists) dir.totalSpace else 0L
        val recordingFilesCount = if (exists && dir.isDirectory) {
            try {
                dir.walkTopDown()
                    .maxDepth(6)
                    .filter { f ->
                        f.isFile && (f.name.endsWith(".m4a", true) ||
                                     f.name.endsWith(".mp4", true) ||
                                     f.name.endsWith(".mp3", true) ||
                                     f.name.endsWith(".aac", true) ||
                                     f.name.endsWith(".wav", true))
                    }.count()
            } catch (_: Exception) {
                0
            }
        } else {
            0
        }

        return mapOf(
            "path" to path,
            "exists" to exists,
            "isWritable" to writable,
            "freeSpaceBytes" to freeSpace,
            "totalSpaceBytes" to totalSpace,
            "recordingFilesCount" to recordingFilesCount
        )
    }

    fun getAvailableStorageDirectories(context: Context): List<Map<String, String>> {
        val dirs = mutableListOf<Map<String, String>>()

        // 1. App-specific external Documents root (Scoped, Android 10-15)
        context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS)?.let { documentsDir ->
            val externalDir = File(documentsDir, "Record Call")
            dirs.add(mapOf(
                "title" to "Аппын гадаад хавтас (Үндсэн Scoped)",
                "path" to externalDir.absolutePath,
                "isDefault" to "true",
                "description" to "Documents/Record Call (аппын scoped хавтас)"
            ))
        }

        // 2. App-specific Internal Storage
        val internalDir = File(File(context.filesDir, Environment.DIRECTORY_DOCUMENTS), "Record Call")
        dirs.add(mapOf(
            "title" to "Аппын дотоод хавтас (Нууцлагдмал)",
            "path" to internalDir.absolutePath,
            "isDefault" to "false",
            "description" to "Бусад апп харах боломжгүй хувийн санах ой"
        ))

        // 3. Secondary External Storage (MicroSD Card if present and writable)
        try {
            val externalDirs = context.getExternalFilesDirs(Environment.DIRECTORY_DOCUMENTS)
            if (externalDirs.size > 1) {
                for (i in 1 until externalDirs.size) {
                    val sdDir = externalDirs[i]
                    if (sdDir != null && isWritableDirectory(sdDir)) {
                        dirs.add(mapOf(
                            "title" to "SD Карт (MicroSD)",
                            "path" to File(sdDir, "Record Call").absolutePath,
                            "isDefault" to "false",
                            "description" to "Нэмэлт гадаад санах ойн карт"
                        ))
                    }
                }
            }
        } catch (_: Exception) {}

        // 4. Shared Music / Audio folder (Only if writable)
        try {
            val musicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Recordings")
            if (isWritableDirectory(musicDir)) {
                dirs.add(mapOf(
                    "title" to "Хөгжим/Аудио хавтас (Music/Recordings)",
                    "path" to musicDir.absolutePath,
                    "isDefault" to "false",
                    "description" to "Хөгжим тоглуулагч аппуудад нээлттэй"
                ))
            }
        } catch (_: Exception) {}

        // 5. Shared Documents folder (Only if writable)
        try {
            val docsDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "Recordings")
            if (isWritableDirectory(docsDir)) {
                dirs.add(mapOf(
                    "title" to "Баримт бичиг хавтас (Documents/Recordings)",
                    "path" to docsDir.absolutePath,
                    "isDefault" to "false",
                    "description" to "Нийтийн Documents хавтас"
                ))
            }
        } catch (_: Exception) {}

        return dirs
    }
}

