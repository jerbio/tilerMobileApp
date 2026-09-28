package app.tiler.app

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.Locale

class MainActivity : FlutterActivity() {

    /// Channel the Flutter side uses to persist files into the user-visible
    /// Downloads folder. On scoped-storage devices (API 29+, which is every
    /// realistic target for this app) the app cannot write to
    /// `Environment.DIRECTORY_DOWNLOADS` via file paths, so the write goes
    /// through MediaStore.
    private val downloadsChannelName = "tiler_app/comment_downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    // The handler is invoked on the platform main thread;
                    // file + MediaStore IO must not block it.
                    Thread {
                        try {
                            val rawBytes = call.argument<List<Int>>("bytes")
                                ?: throw IllegalArgumentException("missing bytes")
                            val saved = saveToDownloadsDirectory(
                                rawBytes.map { it.toByte() }.toByteArray(),
                                call.argument<String>("fileName")
                                    ?: throw IllegalArgumentException("missing fileName"),
                                call.argument<Int>("expectedBytes")?.toLong()
                            )
                            // {name, uri} so the Flutter side can open the
                            // exact row later without a name re-query.
                            result.success(
                                mapOf(
                                    "name" to saved.first,
                                    "uri" to saved.second,
                                )
                            )
                        } catch (e: Throwable) {
                            result.error("DOWNLOADS_SAVE_FAILED", e.message, null)
                        }
                    }.start()
                } else if (call.method == "openInDownloads") {
                    val fileName = call.argument<String>("fileName")
                    if (fileName.isNullOrBlank()) {
                        result.error("OPEN_FAILED", "missing fileName", null)
                    } else {
                        Thread {
                            try {
                                // Prefer the exact content URI the save
                                // returned — a fresh MediaStore row is not
                                // always immediately findable by a
                                // DISPLAY_NAME re-query.
                                val savedUri = call.argument<String>("uri")
                                if (savedUri != null &&
                                    openContentUri(savedUri, contentTypeFor(fileName))
                                ) {
                                    result.success(true)
                                } else {
                                    val uri = queryDownloadUri(fileName)
                                    if (uri != null) {
                                        startActivity(
                                            Intent(Intent.ACTION_VIEW).apply {
                                                setDataAndType(uri, contentTypeFor(fileName))
                                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                            }
                                        )
                                        result.success(true)
                                    } else {
                                        result.error("OPEN_FAILED", "file not found in Downloads", null)
                                    }
                                }
                            } catch (e: Throwable) {
                                result.error("OPEN_FAILED", e.message, null)
                            }
                        }.start()
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Launches [uriString] in the system viewer with [mime]. Returns false
     * when no app can handle it (e.g. the MediaStore row was deleted in the
     * meantime) so the caller can fall back to the name-based lookup.
     */
    private fun openContentUri(uriString: String, mime: String): Boolean =
        try {
            val uri = Uri.parse(uriString)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) == null) return false
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }

    /**
     * Writes [bytes] into the public Downloads folder via MediaStore and
     * returns the stored file name plus the content URI of the row that was
     * written (null when the app-directory fallback was used instead). On a
     * failure the pending MediaStore row is rolled back and the bytes are
     * written to the app-specific external directory, so the caller still
     * gets a readable location.
     */
    private fun saveToDownloadsDirectory(
        bytes: ByteArray,
        fileName: String,
        expectedBytes: Long?
    ): Pair<String, String?> {
        // Re-downloading the same file (same name + size) reuses the
        // existing row instead of creating "name (2)".
        val existingSize = findDownloadSize(fileName)
        val uniqueName = if (expectedBytes != null && existingSize == expectedBytes) {
            fileName
        } else {
            uniqueDownloadName(fileName)
        }
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, uniqueName)
            put(MediaStore.Downloads.MIME_TYPE, contentTypeFor(uniqueName))
            put(MediaStore.Downloads.IS_PENDING, 1)
            if (Build.VERSION.SDK_INT >= 29) {
                put(MediaStore.Downloads.RELATIVE_PATH, "Download/")
            }
        }
        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw java.io.IOException("MediaStore insert returned null")
        try {
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
            contentResolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                null,
                null
            )
            // Return the row's own URI: it stays valid even when a same-size
            // re-download later appends "(2)" duplicates with the same name.
            return uniqueName to uri.toString()
        } catch (e: Exception) {
            try {
                contentResolver.delete(uri, null, null)
            } catch (_: Exception) {
            }
            val dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                ?: File(filesDir, "downloads")
            if (!dir.isDirectory && !dir.mkdirs()) {
                throw e
            }
            val file = File(dir, uniqueName)
            FileOutputStream(file).use { it.write(bytes) }
            return file.absolutePath to null
        }
    }

    /** Returns [desired] or a collision-avoiding variant not taken in Downloads yet. */
    private fun uniqueDownloadName(desired: String): String {
        val clean = desired.replace(Regex("[\\\\/:*?\"<>|]"), "_").ifBlank { "attachment" }
        val hasExt = clean.lastIndexOf('.') > 0
        val base = if (hasExt) clean.substringBeforeLast('.') else clean
        val ext = if (hasExt) clean.substringAfterLast('.') else ""
        var candidate = clean
        for (i in 2..1000) {
            if (!downloadExists(candidate)) return candidate
            candidate = if (hasExt) "$base ($i).$ext" else "$base ($i)"
        }
        return candidate
    }

    private fun downloadExists(name: String): Boolean =
        contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Downloads.DISPLAY_NAME),
            MediaStore.Downloads.DISPLAY_NAME + " = ?",
            arrayOf(name),
            null
        ).use { it != null && it.moveToFirst() }

    /** Size of the (first) file named [name] in Downloads, or null. */
    private fun findDownloadSize(name: String): Long? =
        contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Downloads.SIZE),
            MediaStore.Downloads.DISPLAY_NAME + " = ?",
            arrayOf(name),
            null
        ).use { cursor ->
            if (cursor == null || !cursor.moveToFirst() || cursor.isNull(0)) null
            else cursor.getLong(0)
        }

    /** Content URI of the most recently modified file named [name]. */
    private fun queryDownloadUri(name: String): Uri? =
        contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Downloads._ID),
            MediaStore.Downloads.DISPLAY_NAME + " = ?",
            arrayOf(name),
            "${MediaStore.Downloads.DATE_MODIFIED} DESC"
        ).use { cursor ->
            if (cursor == null || !cursor.moveToFirst() || cursor.isNull(0)) null
            else
                // Equivalent of ContentUris.withAppendedId(...) — the local
                // android-36 platform jar is missing ContentUris, and Uri's
                // builder produces the identical "content://.../<id>" URI.
                MediaStore.Downloads.EXTERNAL_CONTENT_URI.buildUpon()
                    .appendPath(cursor.getLong(0).toString())
                    .build()
        }

    /** MIME type for the comment-attachment extensions; octet-stream otherwise. */
    private fun contentTypeFor(fileName: String): String =
        when (fileName.substringAfterLast('.', "").lowercase(Locale.ROOT)) {
            "pdf" -> "application/pdf"
            "png" -> "image/png"
            "jpg", "jpeg" -> "image/jpeg"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            else -> "application/octet-stream"
        }
}
