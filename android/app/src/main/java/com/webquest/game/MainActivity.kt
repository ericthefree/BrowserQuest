package com.webquest.game

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.res.AssetManager
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.TextView
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.FileNotFoundException

class MainActivity : Activity() {
    private lateinit var webView: WebView
    private val preferences by lazy { getSharedPreferences(GameBridge.PREFERENCES, Context.MODE_PRIVATE) }

    @SuppressLint("SetJavaScriptEnabled", "AddJavascriptInterface")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        WebView.setWebContentsDebuggingEnabled(applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0)
        webView = WebView(this).apply {
            setBackgroundColor(Color.BLACK)
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.mediaPlaybackRequiresUserGesture = false
            settings.cacheMode = WebSettings.LOAD_DEFAULT
            settings.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            isHorizontalScrollBarEnabled = false
            isVerticalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
            addJavascriptInterface(GameBridge(preferences), GameBridge.JAVASCRIPT_NAME)
            webViewClient = GameWebViewClient(assets, preferences, ::showLoadError)
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(message: ConsoleMessage): Boolean {
                    Log.d("BrowserQuest JS", "${message.message()} at ${message.sourceId()}:${message.lineNumber()}")
                    return true
                }
            }
        }
        setContentView(webView)
        enterImmersiveMode()
        webView.loadUrl(GameWebViewClient.GAME_URL)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) enterImmersiveMode()
    }

    override fun onResume() {
        super.onResume()
        if (::webView.isInitialized) webView.onResume()
    }

    override fun onPause() {
        if (::webView.isInitialized) webView.onPause()
        super.onPause()
    }

    override fun onDestroy() {
        if (::webView.isInitialized) {
            webView.removeJavascriptInterface(GameBridge.JAVASCRIPT_NAME)
            webView.destroy()
        }
        super.onDestroy()
    }

    @Deprecated("Android framework callback retained for API 26 compatibility")
    override fun onBackPressed() {
        if (::webView.isInitialized && webView.canGoBack()) {
            webView.goBack()
        } else {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }

    private fun enterImmersiveMode() {
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
    }

    private fun showLoadError(message: String) {
        runOnUiThread {
            setContentView(TextView(this).apply {
                setBackgroundColor(Color.BLACK)
                setTextColor(Color.WHITE)
                textSize = 18f
                gravity = android.view.Gravity.CENTER
                text = getString(R.string.load_error, message)
            })
        }
    }
}

class GameBridge(private val preferences: android.content.SharedPreferences) {
    @JavascriptInterface
    fun save(save: String, world: String) {
        preferences.edit()
            .putString(SAVE_KEY, save)
            .putString(WORLD_KEY, world)
            .apply()
    }

    @JavascriptInterface
    fun log(message: String) {
        Log.d("BrowserQuest JS", message)
    }

    companion object {
        const val JAVASCRIPT_NAME = "BrowserQuestAndroid"
        const val PREFERENCES = "browserquest"
        const val SAVE_KEY = "save"
        const val WORLD_KEY = "world"
    }
}

private class GameWebViewClient(
    private val assets: AssetManager,
    private val preferences: android.content.SharedPreferences,
    private val onLoadError: (String) -> Unit
) : WebViewClient() {
    override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
        val uri = request.url
        if (uri.scheme != APP_SCHEME || uri.host != APP_HOST) return null
        val path = safeAssetPath(uri) ?: return errorResponse(403, "Forbidden")
        return try {
            if (path == INDEX_PATH) {
                val html = assets.open(path).bufferedReader(Charsets.UTF_8).use { it.readText() }
                val page = html.replaceFirst("<head>", "<head><script>${bootstrapScript()}</script>")
                WebResourceResponse("text/html", "UTF-8", ByteArrayInputStream(page.toByteArray()))
            } else {
                WebResourceResponse(mimeType(path), encoding(path), assets.open(path))
            }
        } catch (_: FileNotFoundException) {
            errorResponse(404, "Missing asset: $path")
        } catch (error: Exception) {
            Log.e("BrowserQuest asset", "Unable to load $path", error)
            errorResponse(500, "Unable to load asset")
        }
    }

    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val uri = request.url
        if (uri.scheme == APP_SCHEME && uri.host == APP_HOST) return false
        return try {
            view.context.startActivity(Intent(Intent.ACTION_VIEW, uri))
            true
        } catch (_: Exception) {
            true
        }
    }

    override fun onReceivedError(view: WebView, request: WebResourceRequest, error: android.webkit.WebResourceError) {
        super.onReceivedError(view, request, error)
        if (request.isForMainFrame) onLoadError(error.description.toString())
    }

    private fun safeAssetPath(uri: Uri): String? {
        val segments = uri.pathSegments
        if (segments.isEmpty() || segments.any { it.isBlank() || it == "." || it == ".." }) return null
        return segments.joinToString("/")
    }

    private fun bootstrapScript(): String {
        val save = preferences.getString(GameBridge.SAVE_KEY, null)?.let(::javascriptString) ?: "null"
        val world = preferences.getString(GameBridge.WORLD_KEY, null)?.let(::javascriptObject) ?: "null"
        return """
            window.BROWSERQUEST_OFFLINE = true;
            window.BROWSERQUEST_CLOUD_SAVE = $save;
            window.BROWSERQUEST_OFFLINE_WORLD = $world;
            window.BrowserQuestCloud = {
                save: function(save, world) { window.${GameBridge.JAVASCRIPT_NAME}.save(save, world); }
            };
            (function() {
                function report(kind, message) {
                    window.${GameBridge.JAVASCRIPT_NAME}.log(kind + ": " + message);
                }
                var originalError = console.error;
                console.error = function() {
                    var message = Array.prototype.map.call(arguments, String).join(" ");
                    report("console.error", message);
                    originalError.apply(console, arguments);
                };
                window.addEventListener("error", function(event) {
                    report("window.error", event.message + " at " + event.filename + ":" + event.lineno);
                });
                window.addEventListener("unhandledrejection", function(event) {
                    report("unhandledrejection", String(event.reason));
                });
            }());
        """.trimIndent()
    }

    private fun javascriptString(value: String): String = escapeScript(JSONObject.quote(value))

    private fun javascriptObject(value: String): String = try {
        escapeScript(JSONObject(value).toString())
    } catch (_: Exception) {
        "null"
    }

    private fun escapeScript(value: String): String = value
        .replace("<", "\\u003c")
        .replace(">", "\\u003e")
        .replace("&", "\\u0026")

    private fun mimeType(path: String): String = when (path.substringAfterLast('.', "").lowercase()) {
        "css" -> "text/css"
        "gif" -> "image/gif"
        "html" -> "text/html"
        "ico" -> "image/x-icon"
        "jpeg", "jpg" -> "image/jpeg"
        "js" -> "text/javascript"
        "json" -> "application/json"
        "mp3" -> "audio/mpeg"
        "ogg" -> "audio/ogg"
        "png" -> "image/png"
        "svg" -> "image/svg+xml"
        "ttf" -> "font/ttf"
        "wav" -> "audio/wav"
        "woff" -> "font/woff"
        else -> "application/octet-stream"
    }

    private fun encoding(path: String): String? = when (path.substringAfterLast('.', "").lowercase()) {
        "css", "html", "js", "json", "svg" -> "UTF-8"
        else -> null
    }

    private fun errorResponse(status: Int, message: String): WebResourceResponse = WebResourceResponse(
        "text/plain",
        "UTF-8",
        status,
        message,
        mapOf("Cache-Control" to "no-store"),
        ByteArrayInputStream(message.toByteArray())
    )

    companion object {
        private const val APP_SCHEME = "https"
        private const val APP_HOST = "browserquest.local"
        private const val INDEX_PATH = "client/index.html"
        const val GAME_URL = "$APP_SCHEME://$APP_HOST/$INDEX_PATH"
    }
}
