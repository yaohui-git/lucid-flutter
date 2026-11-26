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

    companion object {
        private const val COOL_DOWN_MS = 60_000L // 同一 APP 冷却 60 秒，避免频繁打扰
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        refreshBlockedApps()

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info
        // 注意：无障碍服务由系统保活，无需 startForeground()。
        // targetSdk>=34 时调用 startForeground() 必须声明 foregroundServiceType，
        // 否则抛 MissingForegroundServiceTypeException 导致服务崩溃（表现为「此服务出现故障」）。
    }

    private fun refreshBlockedApps() {
        blockedApps = prefs.getStringSet(MainActivity.KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
        autoInterceptEnabled = prefs.getBoolean(MainActivity.KEY_AUTO_INTERCEPT, true)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
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
        // 用户可在 App 内关闭「自动拦截」总开关，关闭后服务不弹出挑战
        if (!autoInterceptEnabled) return
        if (!blockedApps.contains(pkg)) return

        // 冷却期
        if (now - lastInterceptTime < COOL_DOWN_MS) return
        lastInterceptTime = now

        val appName = try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
        } catch (e: Exception) {
            pkg
        }

        val payload = mapOf("package" to pkg, "name" to appName)
        // 关键：必须无条件把清醒兽拉到前台，拦截页才能盖在目标 App 上面。
        // 旧逻辑只在 Flutter 通道未就绪时才拉起，导致 App 在后台时拦截页弹在后台，用户看不到。
        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("intercept_package", pkg)
            putExtra("intercept_name", appName)
        }
        // 先把事件存好，Activity 拉起后由它决定立即发送还是等 Flutter 连上再发
        MainActivity.pendingIntercept = payload
        startActivity(launch)
    }

    override fun onInterrupt() {}
}
