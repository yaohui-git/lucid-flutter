package com.lucid.lucid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log

/**
 * 开机自启：无障碍服务由系统自动恢复，这里只做保底处理（提示用户服务状态）。
 * 真正的拦截能力依赖用户在系统设置中开启无障碍服务，系统会在重启后自动重新绑定。
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            try {
                // 检查无障碍是否已启用；若启用，系统会自动重启服务，这里无需额外操作
                val enabled = Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                ) ?: ""
                val component = "${context.packageName}/${LucidAccessibilityService::class.java.name}"
                Log.d("LucidBoot", "accessibility enabled=$enabled contains=${
                    enabled.contains(component, ignoreCase = true)
                }")
            } catch (e: Exception) {
                Log.e("LucidBoot", "boot check failed", e)
            }
        }
    }
}
