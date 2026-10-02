package com.tapture.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/** The system browser owns authentication; only the registered callback returns here. */
internal class CloudSignIn(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var redirect: Uri? = null
    private var departed = false
    private val main = Handler(Looper.getMainLooper())

    fun start(authorize: String?, callback: String?, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A cloud sign-in is already open.", null)
            return
        }
        val url = authorize?.let(Uri::parse)
        val expected = callback?.let(Uri::parse)
        if (url?.scheme != "https" || expected?.scheme != "tapture" ||
            expected.host != "oauth" || !expected.path.isNullOrEmpty()) {
            result.error("sign_in_failed", "Cloud sign-in could not start.", null)
            return
        }
        pending = result
        redirect = expected
        departed = false
        try {
            activity.startActivity(Intent(Intent.ACTION_VIEW, url).addCategory(Intent.CATEGORY_BROWSABLE))
        } catch (_: Exception) {
            finishError("sign_in_failed", "Cloud sign-in could not start.")
        }
    }

    fun receive(intent: Intent): Boolean {
        val uri = intent.data ?: return false
        val expected = redirect ?: return false
        if (uri.scheme != expected.scheme || uri.host != expected.host ||
            uri.path.orEmpty() != expected.path.orEmpty() || uri.port != -1 ||
            !uri.userInfo.isNullOrEmpty()) return false
        val result = pending ?: return false
        clear()
        result.success(uri.toString())
        return true
    }

    fun paused() { if (pending != null) departed = true }

    fun resumed() {
        if (!departed) return
        val returning = pending ?: return
        // onNewIntent receives a valid callback before the queued resume action.
        main.post { if (pending === returning) cancel() }
    }

    fun cancel() = finishError("cancelled", "Cloud sign-in was cancelled.")

    private fun finishError(code: String, message: String) {
        val result = pending
        clear()
        result?.error(code, message, null)
    }

    private fun clear() { pending = null; redirect = null; departed = false }
}
