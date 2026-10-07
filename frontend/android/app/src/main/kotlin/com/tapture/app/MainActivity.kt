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
import android.speech.SpeechRecognizer
import android.system.ErrnoException
import android.system.OsConstants
import android.webkit.MimeTypeMap
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

private const val CHANNEL = "com.tapture.app/files"
private const val SAVE_AS_REQUEST = 7101
private const val PICK_DIR_REQUEST = 7102
private const val PICK_DOC_REQUEST = 7103
private const val COPY_CHUNK = 64 * 1024
private val io = Executors.newSingleThreadExecutor()
private val main = Handler(Looper.getMainLooper())

class MainActivity : FlutterFragmentActivity() {
    private val cloudSignIn = CloudSignIn(this)
    private val scopedFolderState = lazy { ScopedFolderWriter(applicationContext) }
    private val scopedFolders get() = scopedFolderState.value
    private var saveAsResult: MethodChannel.Result? = null
    private var saveAsBytes: ByteArray? = null
    private var saveAsFileName: String? = null
    private var pickDirResult: MethodChannel.Result? = null
    private var pickDestination = false
    private var pickDocResult: MethodChannel.Result? = null
    private var incomingBundles: IncomingBundles? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tapture.app/cloud")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "signIn" -> cloudSignIn.start(call.argument("authorize"), call.argument("redirect"), result)
                    "cancelSignIn" -> { cloudSignIn.cancel(); result.success(null) }
                    "folderBegin", "folderAppend", "folderFinish", "folderAbort", "folderProbe" -> scopedFolders.handle(call, result)
                    else -> result.notImplemented()
                }
            }
        val filesChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        incomingBundles = IncomingBundles(applicationContext, filesChannel)
        filesChannel
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeIncomingBundle" -> result.success(incomingBundles?.take())
                    "discardIncomingBundles" -> {
                        incomingBundles?.discard()
                        result.success(null)
                    }
                    "saveToDownloads" -> saveToDownloads(
                        call.argument("fileName"),
                        call.argument("mimeType"),
                        call.argument("bytes"),
                        call.argument("subfolder"),
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
                    "pickDestinationDirectory" -> pickDirectory(result, destination = true)
                    "pickDocument" -> pickDocument(call.argument("mimeType"), result)
                    "extractFlutterAsset" -> extractFlutterAsset(
                        call.argument("asset"),
                        call.argument("path"),
                        result,
                    )
                    // Field dictation falls back to the platform recogniser only
                    // when it provably stays on the device (FE-SEC-04, task 120).
                    "onDeviceRecognitionAvailable" -> result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                            SpeechRecognizer.isOnDeviceRecognitionAvailable(applicationContext),
                    )
                    "saveFileToDownloads" -> saveFileToDownloads(
                        call.argument("sourcePath"),
                        call.argument("fileName"),
                        call.argument("mimeType"),
                        call.argument("subfolder"),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
        incomingBundles?.receive(intent)
    }

    override fun onNewIntent(intent: Intent) {
        if (cloudSignIn.receive(intent)) { setIntent(intent); return }
        if (incomingBundles?.receive(intent) == true) { setIntent(intent); return }
        super.onNewIntent(intent)
    }

    override fun onPause() { cloudSignIn.paused(); super.onPause() }

    override fun onResume() { super.onResume(); cloudSignIn.resumed() }

    override fun onDestroy() { cloudSignIn.cancel(); incomingBundles?.close(); if (scopedFolderState.isInitialized()) scopedFolders.close(); super.onDestroy() }

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
        if (requestCode == PICK_DOC_REQUEST) {
            finishPickDocument(resultCode, data)
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

    private fun pickDirectory(result: MethodChannel.Result, destination: Boolean = false) {
        if (pickDirResult != null) {
            result.error("busy", "A folder pick is already open.", null)
            return
        }
        pickDirResult = result
        pickDestination = destination
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
        )
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
        val destination = pickDestination
        pickDestination = false
        if (pending == null) {
            return
        }
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.error("cancelled", "The pick was cancelled.", null)
            return
        }
        try {
            val flags = (data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
            if (destination && flags != (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)) throw SecurityException()
            contentResolver.takePersistableUriPermission(
                uri,
                flags,
            )
        } catch (_: Exception) {
            if (destination) { pending.error("grant_lost", "Could not retain access to that folder.", null); return }
        }
        if (destination) { pending.success(uri.toString()); return }
        val path = treeUriToPath(uri)
        if (path.isNullOrEmpty()) {
            pending.error("pick_failed", "Could not read that folder.", null)
            return
        }
        pending.success(path)
    }

    /// Opens the system document picker for one file of [mimeType].
    private fun pickDocument(mimeType: String?, result: MethodChannel.Result) {
        if (pickDocResult != null) {
            result.error("busy", "A file pick is already open.", null)
            return
        }
        pickDocResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            val mimeTypes = mimeType.orEmpty()
                .split(',')
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .toMutableSet()
            // Android may register CSV under a MIME type other than text/csv.
            if ("text/csv" in mimeTypes) {
                val csvMimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension("csv")
                if (!csvMimeType.isNullOrBlank()) mimeTypes.add(csvMimeType)
            }
            type = mimeTypes.singleOrNull() ?: "*/*"
            if (mimeTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            }
        }
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, PICK_DOC_REQUEST)
        } catch (_: Exception) {
            pickDocResult = null
            result.error("pick_failed", "Could not open a file picker.", null)
        }
    }

    /// Copies the chosen document into the app cache in chunks, so Dart reads
    /// a plain file whatever provider the document came from.
    private fun finishPickDocument(resultCode: Int, data: Intent?) {
        val pending = pickDocResult
        pickDocResult = null
        if (pending == null) {
            return
        }
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.error("cancelled", "The pick was cancelled.", null)
            return
        }
        io.execute {
            try {
                val name = displayName(uri) ?: "document"
                val folder = File(cacheDir, "imports").apply { mkdirs() }
                val safe = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
                val target = File(folder, "${System.currentTimeMillis()}-$safe")
                contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { output ->
                        input.copyTo(output, COPY_CHUNK)
                    }
                } ?: error("stream")
                main.post {
                    pending.success(
                        hashMapOf(
                            "path" to target.absolutePath,
                            "name" to name,
                            "byteLength" to target.length(),
                        ),
                    )
                }
            } catch (_: Exception) {
                main.post { pending.error("pick_failed", "Could not read that file.", null) }
            }
        }
    }

    /// Streams the bundled Flutter asset [asset] into [path] through
    /// `<path>.part`, synced and renamed, so a large model never passes
    /// through the Dart heap. The asset is stored uncompressed
    /// (`noCompress "bin"`). Returns the byte count, or the error `missing`,
    /// `nospace` or `io`.
    private fun extractFlutterAsset(asset: String?, path: String?, result: MethodChannel.Result) {
        if (asset == null || path == null) {
            result.error("io", "Could not extract the asset.", null)
            return
        }
        io.execute {
            val target = File(path)
            val part = File("$path.part")
            try {
                val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
                val input = try {
                    assets.open(key)
                } catch (_: FileNotFoundException) {
                    null
                }
                if (input == null) {
                    main.post { result.error("missing", "The asset is not in this build.", null) }
                    return@execute
                }
                target.parentFile?.mkdirs()
                val written = input.use { source ->
                    FileOutputStream(part).use { output ->
                        val count = source.copyTo(output, COPY_CHUNK)
                        output.flush()
                        output.fd.sync()
                        count
                    }
                }
                if (!part.renameTo(target)) {
                    throw IOException("rename")
                }
                main.post { result.success(written) }
            } catch (error: Exception) {
                part.delete()
                val code = if (isNoSpace(error)) "nospace" else "io"
                main.post { result.error(code, "Could not extract the asset.", null) }
            }
        }
    }

    /// Whether [error] reports a full disk (`ENOSPC`).
    private fun isNoSpace(error: Throwable): Boolean {
        var cause: Throwable? = error
        while (cause != null) {
            if (cause is ErrnoException && cause.errno == OsConstants.ENOSPC) {
                return true
            }
            if (cause.message?.contains("ENOSPC") == true) {
                return true
            }
            cause = cause.cause
        }
        return false
    }

    /// Streams a stored file into the shared Downloads folder, so a package
    /// larger than memory is never read whole.
    private fun saveFileToDownloads(
        sourcePath: String?,
        fileName: String?,
        mimeType: String?,
        subfolder: String?,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || sourcePath == null ||
            fileName == null
        ) {
            result.error("unsupported", "Shared downloads need Android 10 or later.", null)
            return
        }
        val source = File(sourcePath)
        if (!source.isFile) {
            result.error("write_failed", "Could not write the download.", null)
            return
        }
        val relative = if (subfolder == "Exports") {
            "Download/Tapture/Exports"
        } else {
            "Download/Tapture"
        }
        copyOnQ(source, fileName, mimeType, relative, result)
    }

    @SuppressLint("NewApi")
    private fun copyOnQ(
        source: File,
        fileName: String,
        mimeType: String?,
        relativePath: String,
        result: MethodChannel.Result,
    ) {
        io.execute {
            try {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType ?: "application/octet-stream")
                    put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val resolver = contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: error("insert")
                resolver.openOutputStream(uri)?.use { output ->
                    FileInputStream(source).use { input -> input.copyTo(output, COPY_CHUNK) }
                } ?: error("stream")
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
                main.post { result.success("$relativePath/$name") }
            } catch (_: Exception) {
                main.post { result.error("write_failed", "Could not write the download.", null) }
            }
        }
    }

    private fun treeUriToPath(uri: Uri): String? {
        val docId = DocumentsContract.getTreeDocumentId(uri)
        if (docId.startsWith("primary:")) {
            val rel = docId.removePrefix("primary:")
            val base = Environment.getExternalStorageDirectory().absolutePath
            return if (rel.isEmpty()) base else "$base/$rel"
        }
        // A SAF tree identifier is not a filesystem path. Scoped providers
        // need ContentResolver document operations, never a File(uri.path).
        return null
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
        subfolder: String?,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || fileName == null || bytes == null) {
            result.error("unsupported", "Shared downloads need Android 10 or later.", null)
            return
        }
        val relative = if (subfolder == "Exports") {
            "Download/Tapture/Exports"
        } else {
            "Download/Tapture"
        }
        writeOnQ(fileName, mimeType, bytes, relative, result)
    }

    @SuppressLint("NewApi")
    private fun writeOnQ(
        fileName: String,
        mimeType: String?,
        bytes: ByteArray,
        relativePath: String,
        result: MethodChannel.Result,
    ) {
        io.execute {
            try {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType ?: "application/octet-stream")
                    put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
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
                main.post { result.success("$relativePath/$name") }
            } catch (_: Exception) {
                main.post { result.error("write_failed", "Could not write the download.", null) }
            }
        }
    }
}
