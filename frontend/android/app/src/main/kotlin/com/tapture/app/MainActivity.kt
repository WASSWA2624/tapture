package com.tapture.app

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

private const val CHANNEL = "com.tapture.app/files"
private val io = Executors.newSingleThreadExecutor()
private val main = Handler(Looper.getMainLooper())

class MainActivity : FlutterActivity() {
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
                    "publicDocumentsPath" -> publicDocumentsPath(result)
                    else -> result.notImplemented()
                }
            }
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
