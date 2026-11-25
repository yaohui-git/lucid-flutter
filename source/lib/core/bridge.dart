import 'dart:async';
import 'package:flutter/services.dart';

/// 与 Android 原生层通信的桥接
///
/// 原生端提供以下能力：
///  - 使用情况访问（UsageStats）检测各 APP 使用时长
///  - 无障碍服务监听目标 APP 打开事件
///  - 查询已安装应用列表
///  - 跳转系统设置页
class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.lucid.lucid/bridge');
  static const EventChannel _event = EventChannel('com.lucid.lucid/events');

  static StreamSubscription<dynamic>? _interceptSub;

  /// 是否已授予「使用情况访问」权限
  static Future<bool> hasUsageAccess() async {
    try {
      final r = await _channel.invokeMethod<bool>('hasUsageAccess');
      return r ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 打开「使用情况访问」授权设置页
  static Future<void> openUsageSettings() async {
    await _channel.invokeMethod('openUsageSettings');
  }

  /// 无障碍服务是否已开启
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final r = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return r ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 打开无障碍设置页
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// 把需要拦截的包名列表同步给原生无障碍服务
  static Future<void> syncBlockedApps(List<String> packages) async {
    await _channel.invokeMethod('syncBlockedApps', {'packages': packages});
  }

  /// 获取已安装应用（返回 {name, package} 列表）
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final list = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (list == null) return [];
      return list
          .map((e) => Map<String, String>.from(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// 获取今天各应用使用时长（分钟），仅包名 -> 分钟
  static Future<Map<String, int>> todayUsageMinutes() async {
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('todayUsageMinutes');
      if (map == null) return {};
      return map.map((k, v) => MapEntry<String, int>(k.toString(), (v as num).toInt()));
    } on PlatformException {
      return {};
    }
  }

  /// 监听「用户打开了目标 APP」事件
  /// [onIntercept] 收到 {package, name}
  static void listenIntercept(void Function(String package, String name) onIntercept) {
    _interceptSub?.cancel();
    _interceptSub = _event.receiveBroadcastStream().listen((event) {
      final m = Map<String, dynamic>.from(event as Map);
      onIntercept(
        (m['package'] ?? '').toString(),
        (m['name'] ?? '未知应用').toString(),
      );
    });
  }

  static void dispose() {
    _interceptSub?.cancel();
    _interceptSub = null;
  }
}
