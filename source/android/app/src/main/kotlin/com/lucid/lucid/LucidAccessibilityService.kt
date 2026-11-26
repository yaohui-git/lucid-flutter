package com.lucid.lucid

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent

/**
 * 核心拦截服务：监听窗口切换，当检测到用户打开「拦截目标 APP」时，
 * 通过 EventChannel 通知 Flutter 弹出全屏拦截挑战页。
 */
class LucidAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var blockedApps: Set<String> = emptySet()
    private var autoInterceptEnabled = true
    private var lastInterceptTime = 0L
    private var lastPackage = ""
    private var lastEventTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        refreshBlockedApps()
        MainActivity.addDiag(this, "Service", "onServiceConnected 服务已连接, 名单=${blockedApps.size}个, 开关=$autoInterceptEnabled")
        // 重要：不再用 new AccessibilityServiceInfo() 覆盖系统配置。
        // 之前那样做会把 flags/canRetrieveWindowContent 等清成默认值，部分机型会因此收不到事件或行为异常。
        // 事件类型、feedbackType、notificationTimeout 全部由 res/xml/accessibility_service_config.xml 声明。
        // 另外：无障碍服务由系统保活，无需 startForeground()（新版 Android 上会崩）。
    }

    private fun refreshBlockedApps() {
        val stored = prefs.getStringSet(MainActivity.KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
        // 名单为空时用默认名单兜底，避免同步未完成/被清空导致永不拦截
        blockedApps = if (stored.isEmpty()) DEFAULT_BLOCKED else stored
        autoInterceptEnabled = prefs.getBoolean(MainActivity.KEY_AUTO_INTERCEPT, true)
    }

    companion object {
        private const val COOL_DOWN_MS = 60_000L // 同一 APP 冷却 60 秒，避免频繁打扰
        private val DEFAULT_BLOCKED = setOf(
            "com.ss.android.ugc.aweme", // 抖音
            "com.kuaishou.nebula", // 快手
            "com.xingin.xhs", // 小红书
            "com.tencent.mm", // 微信
            "com.sina.weibo", // 微博
            "tv.danmaku.bili", // B站
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {
            if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
            val pkg = event.packageName?.toString() ?: return
            if (pkg.isEmpty()) return

            val now = System.currentTimeMillis()

            // 去重：同一包名在极短时间内重复事件忽略
            if (pkg == lastPackage && now - lastEventTime < 800) return
            lastPackage = pkg
            lastEventTime = now

            // 忽略本应用自身
            if (pkg == packageName) return

            refreshBlockedApps()
            MainActivity.addDiag(this, "Event", "窗口切换到 $pkg (名单${blockedApps.size}个/开关$autoInterceptEnabled)")

            // 用户可在 App 内关闭「自动拦截」总开关，关闭后服务不弹出挑战
            if (!autoInterceptEnabled) {
                MainActivity.addDiag(this, "Event", "跳过:自动拦截开关=关")
                return
            }
            if (!blockedApps.contains(pkg)) {
                MainActivity.addDiag(this, "Event", "跳过:$pkg 不在名单")
                return
            }

            // 冷却期
            if (now - lastInterceptTime < COOL_DOWN_MS) {
                MainActivity.addDiag(this, "Event", "跳过:$pkg 冷却期内(剩余${(COOL_DOWN_MS - (now - lastInterceptTime)) / 1000}s)")
                return
            }
            lastInterceptTime = now

            val appName = try {
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
            } catch (e: Exception) {
                pkg
            }

            MainActivity.addDiag(this, "Hit", "★命中目标 $appName($pkg), 准备拉起App")
            val payload = mapOf("package" to pkg, "name" to appName)
            // 关键：必须无条件把清醒兽拉到前台，拦截页才能盖在目标 App 上面。
            val launch = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("intercept_package", pkg)
                putExtra("intercept_name", appName)
            }
            MainActivity.pendingIntercept = payload
            try {
                startActivity(launch)
                MainActivity.addDiag(this, "Hit", "startActivity已调用 pkg=$pkg")
            } catch (e: Exception) {
                MainActivity.addDiag(this, "Hit", "startActivity失败: ${e.message}")
            }
        } catch (e: Exception) {
            MainActivity.addDiag(this, "Event", "onAccessibilityEvent异常: ${e.message}")
        }
    }

    override fun onInterrupt() {}
}
