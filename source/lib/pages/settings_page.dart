import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/bridge.dart';
import '../core/storage.dart';

class SettingsPage extends StatefulWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppState get s => widget.state;
  List<Map<String, String>> _installed = [];
  bool _usageGranted = false;
  bool _accessOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usage = await NativeBridge.hasUsageAccess();
    final acc = await NativeBridge.isAccessibilityEnabled();
    final apps = await NativeBridge.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _accessOn = acc;
      _installed = apps;
    });
  }

  void _persist() => Storage.instance.saveState(s);

  Future<void> _checkPermissionsHint() async {
    final usage = await NativeBridge.hasUsageAccess();
    final acc = await NativeBridge.isAccessibilityEnabled();
    if (usage && acc) return;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text('需要开启权限', style: TextStyle(fontSize: 16)),
        content: Text(
          '自动拦截需要下面${!acc ? '「无障碍服务」' : ''}${!usage && !acc ? '和' : ''}${!usage ? '「使用情况访问权」' : ''}。'
          '\n\n请在下方「自动拦截所需权限」里点开对应项目，按提示在系统设置中开启后返回。',
          style: const TextStyle(fontSize: 12, color: Color(0xFFC8C8DC), height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
        ],
      ),
    );
  }

  void _toggleBlock(String pkg) {
    final list = List<String>.from(s.blockedApps);
    if (list.contains(pkg)) {
      list.remove(pkg);
    } else {
      list.add(pkg);
    }
    s.setBlockedApps(list);
    NativeBridge.syncBlockedApps(list);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('⚙️ 设置', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _section('功能模式（自己选）', [
                _switchTile(
                  icon: '✍️',
                  title: '主动记录',
                  desc: '在首页手动打卡：刷了一会儿 / 专注完成 / 深呼吸。无需任何权限',
                  value: s.manualRecordEnabled,
                  onChanged: (v) {
                    s.setManualRecordEnabled(v);
                    _persist();
                  },
                ),
                _switchTile(
                  icon: '🛡️',
                  title: '自动拦截',
                  desc: '打开目标 APP 时自动弹出挑战。需要开启下方两项权限',
                  value: s.autoInterceptEnabled,
                  onChanged: (v) {
                    s.setAutoInterceptEnabled(v);
                    NativeBridge.syncAutoIntercept(v);
                    _persist();
                    if (v) _checkPermissionsHint();
                  },
                ),
              ]),
              const SizedBox(height: 20),
              _section('自动拦截所需权限', [
                _permTile(
                  icon: '📊',
                  title: '使用情况访问权',
                  desc: '用于统计各 APP 使用时长，自动记录刷机',
                  granted: _usageGranted,
                  onTap: () async {
                    await NativeBridge.openUsageSettings();
                    _load();
                  },
                ),
                _permTile(
                  icon: '🛡️',
                  title: '无障碍服务',
                  desc: '核心功能：打开目标 APP 时自动弹出拦截挑战',
                  granted: _accessOn,
                  onTap: () async {
                    await NativeBridge.openAccessibilitySettings();
                    _load();
                  },
                ),
              ]),
              const SizedBox(height: 20),
              _section('拦截目标 APP（点击切换）', _installed.isEmpty
                  ? [const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('未获取到应用列表，请授予使用情况访问权后重试', style: TextStyle(fontSize: 12, color: Color(0xFFA8A8C4))),
                    )]
                  : _installed.map((app) {
                      final pkg = app['package'] ?? '';
                      final name = app['name'] ?? pkg;
                      final on = s.blockedApps.contains(pkg);
                      return _appTile(name, pkg, on);
                    }).toList()),
              const SizedBox(height: 20),
              _aboutCard(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E38),
                      title: const Text('重置所有数据？'),
                      content: const Text('这会清空你的所有进度，且无法恢复。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定重置', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    s.reset();
                    await Storage.instance.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7675).withOpacity(0.15),
                  foregroundColor: const Color(0xFFFF7675),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('重置所有数据'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA8A8C4))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _permTile({
    required String icon,
    required String title,
    required String desc,
    required bool granted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFFA8A8C4))),
                ],
              ),
            ),
            Icon(
              granted ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 18,
              color: granted ? const Color(0xFF00B894) : const Color(0xFFFDCB6E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFFA8A8C4), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C5CE7),
            inactiveThumbColor: const Color(0xFF6C6C8A),
          ),
        ],
      ),
    );
  }

  Widget _appTile(String name, String pkg, bool on) {
    return GestureDetector(
      onTap: () => _toggleBlock(pkg),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              on ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: on ? const Color(0xFF6C5CE7) : const Color(0xFF6C6C8A),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(pkg, style: const TextStyle(fontSize: 8, color: Color(0xFF6C6C8A)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('ℹ️ 关于清醒兽', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA29BFE))),
          SizedBox(height: 8),
          Text(
            '把「少刷手机」变成一场养成游戏。你每一次放下手机，都是在喂养一只属于你的清醒兽。\n\n'
            '所有数据仅保存在本机，不上传任何服务器。',
            style: TextStyle(fontSize: 11, color: Color(0xFFA8A8C4), height: 1.7),
          ),
        ],
      ),
    );
  }
}
