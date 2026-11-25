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

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.lucid.lucid/bridge"
        private const val EVENT_CHANNEL = "com.lucid.lucid/events"
        private const val PREFS_NAME = "lucid_prefs"
        const val KEY_BLOCKED_APPS = "blocked_apps"

        @Volatile
        var eventSink: EventChannel.EventSink? = null

        @Volatile
        var pendingIntercept: Map<String, String>? = null
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

    /** 处理从无障碍服务冷启动拉起时携带的拦截信息 */
    private fun handleInterceptIntent(intent: Intent?) {
        val pkg = intent?.getStringExtra("intercept_package") ?: return
        val name = intent.getStringExtra("intercept_name") ?: pkg
        pendingIntercept = mapOf("package" to pkg, "name" to name)
        // 清除 extra，避免旋转屏幕时重复触发
        intent.removeExtra("intercept_package")
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
                pendingIntercept?.let { events.success(it); pendingIntercept = null }
            }
            override fun onCancel(arguments: Any?) { eventSink = null }
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
            "getInstalledApps" -> result.success(getInstalledApps())
            "todayUsageMinutes" -> result.success(todayUsageMinutes())
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
