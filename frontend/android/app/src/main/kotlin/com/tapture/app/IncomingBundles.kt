package com.tapture.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/** Copies only a user-opened archive into the sandbox; Flutter still inspects it. */
internal class IncomingBundles(private val context: Context, private val channel: MethodChannel) {
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private val pending = ArrayDeque<Map<String, Any>>()
    @Volatile private var closed = false
    @Volatile private var generation = 0
    private var outstanding = 0

    fun receive(intent: Intent): Boolean {
        val uri = incomingUri(intent) ?: return false
        val mime = intent.type
        val path = uri.lastPathSegment.orEmpty().lowercase()
        if (uri.scheme !in listOf("content", "file") ||
            (mime !in listOf("application/zip", "application/vnd.tapture.bundle+zip") &&
                !path.endsWith(".zip") && !path.endsWith(".tapture"))) return false
        if (closed) return true
        if (outstanding >= 2) {
            channel.invokeMethod("incomingBundleAvailable", mapOf("error" to "busy"))
            return true
        }
        outstanding++
        val receivedGeneration = generation
        io.execute {
            val target = File(File(context.cacheDir, "incoming-bundles"), "incoming-${UUID.randomUUID()}.zip")
            val payload: Map<String, Any> = try {
                target.parentFile!!.mkdirs()
                val name = name(uri) ?: "package.zip"
                var count = 0L
                context.contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { output ->
                        val chunk = ByteArray(64 * 1024)
                        while (true) {
                            if (closed || receivedGeneration != generation) error("closed")
                            val read = input.read(chunk)
                            if (read < 0) break
                            count += read
                            // Matches AppConstants.bundles.nativeMaxBytes, including unknown provider lengths.
                            if (count > 4_000_000_000L) throw Oversize()
                            output.write(chunk, 0, read)
                        }
                    }
                } ?: error("unreadable")
                mapOf("path" to target.path, "name" to name, "byteLength" to count)
            } catch (_: Oversize) {
                target.delete()
                mapOf("error" to "too_large")
            } catch (_: Exception) {
                target.delete()
                mapOf("error" to "unreadable")
            }
            main.post {
                if (closed || receivedGeneration != generation) target.delete()
                else {
                    val notify = pending.isEmpty()
                    pending.addLast(payload)
                    if (notify) channel.invokeMethod("incomingBundleAvailable", null)
                }
            }
        }
        return true
    }

    /** VIEW opens and single-file SEND shares use the same granted URI boundary. */
    private fun incomingUri(intent: Intent): Uri? = try {
        when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            }
            else -> null
        }
    } catch (_: RuntimeException) {
        // Exported intents can contain a malformed or incorrectly typed parcel.
        null
    }

    private fun name(uri: Uri): String? = if (uri.scheme == "file") File(uri.path.orEmpty()).name else
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        }

    fun take(): Map<String, Any>? {
        if (pending.isEmpty()) return null
        outstanding--
        return pending.removeFirst()
    }

    fun discard() {
        generation++
        for (item in pending) (item["path"] as? String)?.let { File(it).delete() }
        pending.clear()
        outstanding = 0
    }

    fun close() {
        closed = true
        discard()
        io.shutdownNow()
    }

    private class Oversize : Exception()
}
