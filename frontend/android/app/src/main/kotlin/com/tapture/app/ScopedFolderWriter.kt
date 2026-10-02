package com.tapture.app

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

/** Persisted SAF grants are written through ContentResolver, never converted to paths. */
internal class ScopedFolderWriter(private val context: Context) {
    private data class Write(val tree: Uri, var document: Uri, val name: String, val stream: OutputStream)
    private val writes = mutableMapOf<String, Write>()
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val resolver get() = context.contentResolver

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "folderBegin" -> begin(call.argument("folder"), call.argument("name"))
                    "folderAppend" -> {
                        val bytes = call.argument<ByteArray>("bytes") ?: error("bytes")
                        require(bytes.size <= 64 * 1024)
                        write(call.argument("session")).stream.write(bytes)
                        null
                    }
                    "folderFinish" -> finish(call.argument("session"))
                    "folderAbort" -> { abort(call.argument("session")); null }
                    "folderProbe" -> {
                        val id = begin(call.argument("folder"), "tapture-probe-${UUID.randomUUID()}")
                        try {
                            writes.getValue(id).stream.write(byteArrayOf(111, 107))
                            val published = Uri.parse(finish(id))
                            if (!DocumentsContract.deleteDocument(resolver, published)) error("delete probe")
                        }
                        finally { abort(id) }
                        null
                    }
                    else -> error("method")
                }
                main.post { result.success(value) }
            } catch (_: SecurityException) {
                main.post { result.error("grant_lost", "The folder grant is no longer available.", null) }
            } catch (_: Exception) {
                main.post { result.error("write_failed", "Could not write to the chosen folder.", null) }
            }
        }
    }

    private fun begin(folder: String?, name: String?): String {
        require(!name.isNullOrEmpty() && name != "." && name != ".." && !name.contains('/') && !name.contains('\\'))
        val tree = folder?.let(Uri::parse) ?: throw SecurityException()
        if (tree.scheme != "content" || !DocumentsContract.isTreeUri(tree) ||
            resolver.persistedUriPermissions.none { it.uri == tree && it.isReadPermission && it.isWritePermission }) throw SecurityException()
        if (hasName(tree, name)) error("target exists")
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val document = DocumentsContract.createDocument(resolver, parent, "application/octet-stream", ".tapture-${UUID.randomUUID()}.partial") ?: error("create")
        try {
            val stream = resolver.openOutputStream(document, "w") ?: error("stream")
            val id = UUID.randomUUID().toString()
            writes[id] = Write(tree, document, name, stream)
            return id
        } catch (error: Exception) {
            try { DocumentsContract.deleteDocument(resolver, document) } catch (_: Exception) { }
            throw error
        }
    }

    private fun write(id: String?): Write = writes[id] ?: error("session")

    private fun finish(id: String?): String {
        val writing = write(id)
        writing.stream.close()
        if (hasName(writing.tree, writing.name)) error("target exists")
        val published = DocumentsContract.renameDocument(resolver, writing.document, writing.name) ?: error("rename")
        writing.document = published
        val actual = resolver.query(published, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { if (it.moveToFirst()) it.getString(0) else null }
        if (actual != writing.name) error("renamed unexpectedly")
        writes.remove(id)
        return published.toString()
    }

    private fun hasName(tree: Uri, name: String): Boolean {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        return resolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) if (cursor.getString(0) == name) return@use true
            false
        } ?: throw SecurityException()
    }

    private fun abort(id: String?) {
        val writing = writes.remove(id) ?: return
        try { writing.stream.close() }
        finally { DocumentsContract.deleteDocument(resolver, writing.document) }
    }

    fun close() {
        io.execute {
            for (id in writes.keys.toList()) try { abort(id) } catch (_: Exception) { }
        }
        io.shutdown()
    }
}
