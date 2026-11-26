import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/bridge.dart';

/// 首次启动引导：让用户自己选择开启哪些功能，而不是强制所有权限。
class OnboardingPage extends StatefulWidget {
  final AppState state;
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.state, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // 页面 0=欢迎 1=选模式 2=权限引导
  int _step = 0;
  bool _manual = true;
  bool _auto = false;
  bool _usageOn = false;
  bool _accessOn = false;

  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _manual = s.manualRecordEnabled;
    _auto = s.autoInterceptEnabled;
  }

  Future<void> _refreshPerms() async {
    final usage = await NativeBridge.hasUsageAccess();
    final acc = await NativeBridge.isAccessibilityEnabled();
    if (!mounted) return;
    setState(() {
      _usageOn = usage;
      _accessOn = acc;
    });
  }

  void _nextFromMode() {
    s.setManualRecordEnabled(_manual);
    s.setAutoInterceptEnabled(_auto);
    NativeBridge.syncAutoIntercept(_auto);
    if (_auto) {
      _refreshPerms();
      setState(() => _step = 2);
    } else {
      _finish();
    }
  }

  void _finish() {
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: IndexedStack(
            index: _step,
            children: [_welcome(), _chooseMode(), _permissions()],
          ),
        ),
      ),
    );
  }

  Widget _welcome() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🧠', textAlign: TextAlign.center, style: TextStyle(fontSize: 92)),
        const SizedBox(height: 16),
        const Text('清醒兽', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF9FF3))),
        const SizedBox(height: 6),
        const Text('L U C I D', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, letterSpacing: 6, color: Color(0xFF6C6C8A))),
        const SizedBox(height: 30),
        const Text('把「少刷手机」变成养一只脑宠。\n你每一次放下手机，都在喂养它。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFFC8C8DC), height: 1.8)),
        const SizedBox(height: 50),
        _primaryBtn('开始设置', () => setState(() => _step = 1)),
      ],
    );
  }

  Widget _chooseMode() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text('你想怎么使用清醒兽？',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('两种模式可自由组合，之后都能在设置里改。',
              style: TextStyle(fontSize: 13, color: Color(0xFF9A9AB0))),
          const SizedBox(height: 28),
          _modeCard(
            emoji: '✍️',
            title: '主动记录',
            tag: '无需权限 · 推荐先开',
            desc: '刷完手机自己点一下打卡，专注、深呼吸都能记录，宠物据此变化。零门槛，装好就能玩。',
            value: _manual,
            accent: const Color(0xFF00D2D3),
            onChanged: (v) => setState(() => _manual = v),
          ),
          const SizedBox(height: 16),
          _modeCard(
            emoji: '🛡️',
            title: '自动拦截',
            tag: '需系统权限',
            desc: '打开抖音/小红书等目标 App 时自动弹出挑战拦你一下。需要开启无障碍服务和使用情况访问权。',
            value: _auto,
            accent: const Color(0xFFFF7675),
            onChanged: (v) => setState(() => _auto = v),
          ),
          const SizedBox(height: 36),
          _primaryBtn(
            _auto ? '下一步 · 开启权限' : '完成，开始使用',
            _nextFromMode,
            disabled: !_manual && !_auto,
          ),
          if (!_manual && !_auto)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('至少选择一种模式', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFFFF7675))),
            ),
        ],
      ),
    );
  }

  Widget _permissions() {
    final allOn = _usageOn && _accessOn;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text('开启自动拦截所需权限',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('点击下面两项，在系统设置里打开「清醒兽」的开关，然后返回这里。',
              style: TextStyle(fontSize: 13, color: Color(0xFF9A9AB0), height: 1.6)),
          const SizedBox(height: 28),
          _permCard(
            emoji: '📊',
            title: '使用情况访问权',
            desc: '统计各 App 使用时长',
            on: _usageOn,
            onTap: () async {
              await NativeBridge.openUsageSettings();
              _refreshPerms();
            },
          ),
          const SizedBox(height: 14),
          _permCard(
            emoji: '🛡️',
            title: '无障碍服务',
            desc: '检测目标 App 打开并弹挑战',
            on: _accessOn,
            onTap: () async {
              await NativeBridge.openAccessibilitySettings();
              _refreshPerms();
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _refreshPerms,
            child: const Text('⟳ 已开启，点此刷新状态',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFFA29BFE))),
          ),
          const SizedBox(height: 40),
          _primaryBtn(
            allOn ? '全部就绪，开始使用' : '跳过权限，先用主动记录',
            () {
              if (!allOn) s.setAutoInterceptEnabled(false);
              NativeBridge.syncAutoIntercept(s.autoInterceptEnabled);
              _finish();
            },
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required String emoji,
    required String title,
    required String tag,
    required String desc,
    required bool value,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: value ? accent : Colors.white.withOpacity(0.08), width: value ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 9, color: accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFFA8A8C4), height: 1.6)),
                ],
              ),
            ),
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? accent : const Color(0xFF6C6C8A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permCard({
    required String emoji,
    required String title,
    required String desc,
    required bool on,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: on ? const Color(0xFF00B894).withOpacity(0.5) : const Color(0xFFFDCB6E).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFFA8A8C4))),
                ],
              ),
            ),
            Icon(
              on ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 18,
              color: on ? const Color(0xFF00B894) : const Color(0xFFFDCB6E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap, {bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(colors: [Color(0xFF7BE0D0), Color(0xFF4FB8C9)]),
          color: disabled ? const Color(0xFF2A2A44) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: disabled ? const Color(0xFF6C6C8A) : const Color(0xFF0F2027),
              )),
        ),
      ),
    );
  }
}
