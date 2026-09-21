package com.tapture.app

import android.annotation.SuppressLint
import android.app.Activity
import android.app.DownloadManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

private const val CHANNEL = "com.tapture.app/files"
private const val SAVE_AS_REQUEST = 7101
private const val PICK_DIR_REQUEST = 7102
private val io = Executors.newSingleThreadExecutor()
private val main = Handler(Looper.getMainLooper())

class MainActivity : FlutterActivity() {
    private var saveAsResult: MethodChannel.Result? = null
    private var saveAsBytes: ByteArray? = null
    private var saveAsFileName: String? = null
    private var pickDirResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> saveToDownloads(
                        call.argument("fileName"),
                        call.argument("mimeType"),
                        call.argument("bytes"),
                        result,
                    )
                    "openDownloads" -> openDownloads(result)
                    "saveAs" -> saveAs(
                        call.argument("fileName"),
                        call.argument("mimeType"),
                        call.argument("bytes"),
                        result,
                    )
                    "publicDocumentsPath" -> publicDocumentsPath(result)
                    "volumeStats" -> volumeStats(call.argument("path"), result)
                    "pickDirectory" -> pickDirectory(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveAs(
        fileName: String?,
        mimeType: String?,
        bytes: ByteArray?,
        result: MethodChannel.Result,
    ) {
        if (fileName == null || bytes == null) {
            result.error("write_failed", "Could not write the download.", null)
            return
        }
        if (saveAsResult != null) {
            result.error("write_failed", "Could not write the download.", null)
            return
        }
        saveAsResult = result
        saveAsBytes = bytes
        saveAsFileName = fileName
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mimeType.isNullOrEmpty()) "application/zip" else mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, SAVE_AS_REQUEST)
        } catch (_: Exception) {
            finishSaveAsError("write_failed", "Could not write the download.")
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_DIR_REQUEST) {
            finishPickDirectory(resultCode, data)
            return
        }
        if (requestCode != SAVE_AS_REQUEST) {
            return
        }
        val pending = saveAsResult
        val bytes = saveAsBytes
        val fileName = saveAsFileName
        saveAsResult = null
        saveAsBytes = null
        saveAsFileName = null
        if (pending == null) {
            return
        }
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
            pending.error("cancelled", "The save was cancelled.", null)
            return
        }
        io.execute {
            try {
                contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: error("stream")
                val name = displayName(uri) ?: fileName
                main.post { pending.success(name) }
            } catch (_: Exception) {
                main.post {
                    pending.error("write_failed", "Could not write the download.", null)
                }
            }
        }
    }

    private fun displayName(uri: Uri): String? {
        return contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null }
    }

    private fun finishSaveAsError(code: String, message: String) {
        val pending = saveAsResult
        saveAsResult = null
        saveAsBytes = null
        saveAsFileName = null
        pending?.error(code, message, null)
    }

    private fun openDownloads(result: MethodChannel.Result) {
        try {
            startActivity(
                Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK,
                ),
            )
            result.success(null)
        } catch (_: Exception) {
            result.error("open_failed", "Could not open Downloads.", null)
        }
    }

    private fun volumeStats(path: String?, result: MethodChannel.Result) {
        val target = path ?: Environment.getDataDirectory().absolutePath
        try {
            val stat = StatFs(target)
            val total = stat.totalBytes
            val free = stat.availableBytes
            result.success(
                hashMapOf(
                    "totalBytes" to total,
                    "freeBytes" to free,
                    "usedBytes" to (total - free),
                ),
            )
        } catch (_: Exception) {
            result.error("unreadable", "Could not read volume stats.", null)
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pickDirResult != null) {
            result.error("busy", "A folder pick is already open.", null)
            return
        }
        pickDirResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, PICK_DIR_REQUEST)
        } catch (_: Exception) {
            pickDirResult = null
            result.error("pick_failed", "Could not open a folder picker.", null)
        }
    }

    private fun finishPickDirectory(resultCode: Int, data: Intent?) {
        val pending = pickDirResult
        pickDirResult = null
        if (pending == null) {
            return
        }
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.error("cancelled", "The pick was cancelled.", null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: Exception) {
            // Persistable grants are optional; a path is enough for resolve.
        }
        val path = treeUriToPath(uri)
        if (path.isNullOrEmpty()) {
            pending.error("pick_failed", "Could not read that folder.", null)
            return
        }
        pending.success(path)
    }

    private fun treeUriToPath(uri: Uri): String? {
        val docId = DocumentsContract.getTreeDocumentId(uri)
        if (docId.startsWith("primary:")) {
            val rel = docId.removePrefix("primary:")
            val base = Environment.getExternalStorageDirectory().absolutePath
            return if (rel.isEmpty()) base else "$base/$rel"
        }
        return uri.path
    }

    private fun publicDocumentsPath(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.error("unsupported", "Shared documents need Android 11 or later.", null)
            return
        }
        result.success(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                .absolutePath,
        )
    }

    private fun saveToDownloads(
        fileName: String?,
        mimeType: String?,
        bytes: ByteArray?,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || fileName == null || bytes == null) {
            result.error("unsupported", "Shared downloads need Android 10 or later.", null)
            return
        }
        writeOnQ(fileName, mimeType, bytes, result)
    }

    @SuppressLint("NewApi")
    private fun writeOnQ(
        fileName: String,
        mimeType: String?,
        bytes: ByteArray,
        result: MethodChannel.Result,
    ) {
        io.execute {
            try {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType ?: "application/octet-stream")
                    put(MediaStore.Downloads.RELATIVE_PATH, "Download/Tapture")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val resolver = contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: error("insert")
                resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: error("stream")
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                val name = resolver.query(
                    uri,
                    arrayOf(MediaStore.Downloads.DISPLAY_NAME),
                    null,
                    null,
                    null,
                )?.use { if (it.moveToFirst()) it.getString(0) else fileName } ?: fileName
                main.post { result.success("Download/Tapture/$name") }
            } catch (_: Exception) {
                main.post { result.error("write_failed", "Could not write the download.", null) }
            }
        }
    }
}
