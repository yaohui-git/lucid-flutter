package com.lucid.lucid

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.content.SharedPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.lucid.lucid/bridge"
        private const val EVENT_CHANNEL = "com.lucid.lucid/events"
        const val PREFS_NAME = "lucid_prefs"
        const val KEY_BLOCKED_APPS = "blocked_apps"
        const val KEY_AUTO_INTERCEPT = "auto_intercept"
        private const val KEY_DIAG_LOG = "diag_log"
        private const val MAX_DIAG_LINES = 120

        @Volatile
        var eventSink: EventChannel.EventSink? = null

        @Volatile
        var pendingIntercept: Map<String, String>? = null

        /** 追加一条诊断日志（环形缓冲，保留最近 [MAX_DIAG_LINES] 行） */
        @Synchronized
        fun addDiag(context: Context, tag: String, msg: String) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val old = prefs.getString(KEY_DIAG_LOG, "") ?: ""
                val ts = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                val line = "[$ts][$tag] $msg"
                val lines = (old + "\n" + line).split("\n").filter { it.isNotBlank() }
                val kept = lines.takeLast(MAX_DIAG_LINES).joinToString("\n")
                prefs.edit().putString(KEY_DIAG_LOG, kept).apply()
            } catch (_: Exception) { }
        }

        fun getDiag(context: Context): String =
            try { context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).getString(KEY_DIAG_LOG, "") ?: "" }
            catch (_: Exception) { "" }

        fun clearDiag(context: Context) {
            try { context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().putString(KEY_DIAG_LOG, "").apply() }
            catch (_: Exception) { }
        }
    }

    private lateinit var prefs: SharedPreferences
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleInterceptIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleInterceptIntent(intent)
    }

    /** 处理从无障碍服务拉起时携带的拦截信息（冷启动 onNewIntent 都会走这里） */
    private fun handleInterceptIntent(intent: Intent?) {
        val pkg = intent?.getStringExtra("intercept_package") ?: return
        val name = intent.getStringExtra("intercept_name") ?: pkg
        val payload = mapOf("package" to pkg, "name" to name)
        addDiag(this, "Activity", "收到拦截intent pkg=$pkg name=$name sinkReady=${eventSink != null}")
        // 清除 extra，避免旋转屏幕时重复触发
        intent.removeExtra("intercept_package")
        intent.removeExtra("intercept_name")
        // Flutter 通道已就绪就直接弹；否则存起来，等 EventChannel.onListen 时再发
        eventSink?.let { sink ->
            try {
                sink.success(payload)
                pendingIntercept = null
                addDiag(this, "Activity", "事件已send到Flutter pkg=$pkg")
            } catch (e: Exception) {
                pendingIntercept = payload
                addDiag(this, "Activity", "send异常已转pending: ${e.message}")
            }
        } ?: run {
            pendingIntercept = payload
            addDiag(this, "Activity", "Flutter未连上,存pending pkg=$pkg")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).also { it.setMethodCallHandler { call, result -> handleMethod(call.method, call.arguments, result) } }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                eventSink = events
                addDiag(this@MainActivity, "Channel", "EventChannel已连接(onListen), pending=${pendingIntercept != null}")
                pendingIntercept?.let {
                    try {
                        events.success(it)
                        addDiag(this@MainActivity, "Channel", "补发pending事件 pkg=${it["package"]}")
                    } catch (e: Exception) {
                        addDiag(this@MainActivity, "Channel", "补发pending异常: ${e.message}")
                    }
                    pendingIntercept = null
                }
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                addDiag(this@MainActivity, "Channel", "EventChannel断开(onCancel)")
            }
        })
    }

    private fun handleMethod(method: String, args: Any?, result: MethodChannel.Result) {
        when (method) {
            "hasUsageAccess" -> result.success(hasUsageAccess())
            "openUsageSettings" -> {
                try {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
                        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    else Intent(Settings.ACTION_SECURITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) { result.error("OPEN_SETTINGS", e.message, null) }
            }
            "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
            "openAccessibilitySettings" -> {
                try {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                } catch (e: Exception) { result.error("OPEN_SETTINGS", e.message, null) }
            }
            "syncBlockedApps" -> {
                @Suppress("UNCHECKED_CAST")
                val packages = (args as? Map<String, Any>)?.get("packages") as? List<String> ?: emptyList()
                prefs.edit().putStringSet(KEY_BLOCKED_APPS, packages.toSet()).apply()
                result.success(true)
            }
            "syncAutoIntercept" -> {
                val enabled = (args as? Map<String, Any>)?.get("enabled") as? Boolean ?: true
                prefs.edit().putBoolean(KEY_AUTO_INTERCEPT, enabled).apply()
                result.success(true)
            }
            "getInstalledApps" -> result.success(getInstalledApps())
            "todayUsageMinutes" -> result.success(todayUsageMinutes())
            "getDiagLog" -> result.success(getDiag(this))
            "clearDiagLog" -> { clearDiag(this); result.success(true) }
            "diagSnapshot" -> result.success(mapOf(
                "accessibilityEnabled" to isAccessibilityEnabled(),
                "usageAccess" to hasUsageAccess(),
                "autoIntercept" to (prefs.getBoolean(KEY_AUTO_INTERCEPT, true)),
                "blockedApps" to (prefs.getStringSet(KEY_BLOCKED_APPS, emptySet())?.toList() ?: emptyList<String>()),
                "eventSinkReady" to (eventSink != null),
                "pendingIntercept" to (pendingIntercept?.get("package") ?: "")
            ))
            else -> result.notImplemented()
        }
    }

    /** 判断是否授予使用情况访问权 */
    private fun hasUsageAccess(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) { false }
    }

    /** 判断无障碍服务是否开启 */
    private fun isAccessibilityEnabled(): Boolean {
        val enabled = Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED, 0
        )
        if (enabled == 0) return false
        val colon = android.provider.Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val component = "$packageName/${LucidAccessibilityService::class.java.name}"
        return colon.split(":").any { it.equals(component, ignoreCase = true) }
    }

    /** 今天各应用使用时长（分钟） */
    private fun todayUsageMinutes(): Map<String, Int> {
        if (!hasUsageAccess()) return emptyMap()
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        val start = cal.timeInMillis
        val end = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, start, end
        ) ?: return emptyMap()
        val result = mutableMapOf<String, Int>()
        for (s in stats) {
            val minutes = (s.totalTimeInForeground / 60000).toInt()
            if (minutes > 0) result[s.packageName] = minutes
        }
        return result
    }

    /** 已安装且可启动的应用列表 */
    private fun getInstalledApps(): List<Map<String, String>> {
        val pm: PackageManager = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong())
            )
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        }
        return resolveInfos.map { ri ->
            mapOf(
                "package" to ri.activityInfo.packageName,
                "name" to ri.loadLabel(pm).toString()
            )
        }.sortedBy { it["name"] }
    }
}
