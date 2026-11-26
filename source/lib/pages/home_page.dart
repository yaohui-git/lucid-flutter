import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/bridge.dart';
import '../widgets/pet_avatar.dart';
import 'intercept_page.dart';

class HomePage extends StatefulWidget {
  final AppState state;
  const HomePage({super.key, required this.state});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppState get s => widget.state;

  // 对话只在状态档位变化时换一句，避免重绘时闪烁跳变
  PetLevel? _speechLevel;
  String _speechText = '';

  String _speechFor(PetLevel level) {
    if (_speechLevel != level || _speechText.isEmpty) {
      final options = kSpeech[level] ?? kSpeech[PetLevel.thriving]!;
      _speechText = options[Random().nextInt(options.length)];
      _speechLevel = level;
    }
    return _speechText;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final info = s.petInfo;
        final level = info.level;
        final text = _speechFor(level);
        final fog = (100 - s.health) / 100 * 0.75;

        return Scaffold(
          body: Stack(
            children: [
              // 背景光斑
              Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C5CE7).withOpacity(0.12),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(),
                      const SizedBox(height: 8),
                      // 宠物卡片
                      Stack(
                        children: [
                          _petCard(info, text),
                          // 脑雾遮罩
                          if (fog > 0.02)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.75,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF1E1E2D).withOpacity(fog),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (s.manualRecordEnabled) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('记录你的行为'),
                        const SizedBox(height: 10),
                        _actionGrid(),
                      ],
                      const SizedBox(height: 20),
                      _interceptDemo(),
                      const SizedBox(height: 20),
                      _todayStats(),
                      const SizedBox(height: 16),
                      _permBanner(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Text('🧠', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('清醒兽', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFFFF9FF3))),
                Text('LUCID', style: TextStyle(fontSize: 8, letterSpacing: 3, color: Color(0xFF6C6C8A))),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _chip('🔥', '${s.streak}天'),
            const SizedBox(width: 8),
            _chip('✨', '${s.lucidPoints}'),
          ],
        ),
      ],
    );
  }

  Widget _chip(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF242442),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _petCard(PetInfo info, String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF1E1E38)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          PetAvatar(info: info, size: 210),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(info.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF242442),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFD0D0E0)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🧠 脑力值', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${s.health.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00D2D3))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.health / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(
                s.health >= 60
                    ? const Color(0xFF00D2D3)
                    : s.health >= 40
                        ? const Color(0xFFFDCB6E)
                        : const Color(0xFFFF7675),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(info.subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6C6C8A))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA8A8C4)));

  Widget _actionGrid() {
    return Row(
      children: [
        _actionBtn('📱', '刷了一会儿', '宠物变虚弱', const Color(0xFFFF7675), () => s.scroll()),
        const SizedBox(width: 8),
        _actionBtn('🎯', '专注完成', '恢复活力', const Color(0xFF00D2D3), () => s.focus()),
        const SizedBox(width: 8),
        _actionBtn('🌬️', '深呼吸', '快速恢复', const Color(0xFFFDCB6E), () => s.breathe()),
      ],
    );
  }

  Widget _actionBtn(String icon, String label, String desc, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 8, color: Color(0xFF6C6C8A))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _interceptDemo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF7675).withOpacity(0.1),
            const Color(0xFF6C5CE7).withOpacity(0.1),
          ],
        ),
        border: Border.all(color: const Color(0xFFFF7675).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('冲动拦截已就绪', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('开启无障碍服务后，打开目标 APP 会自动弹出挑战', style: TextStyle(fontSize: 10, color: Color(0xFFA8A8C4))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showInterceptSheet(context, s, 'demo', '短视频'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7675),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('测试', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${s.todayScroll}', '刷机次数'),
          _stat('${s.todayFocus}', '专注次数'),
          _stat('${s.todayResist}', '成功拦截'),
          _stat('${s.todayMinutes}', '清醒分钟'),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Column(
        children: [
          Text(v, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFFA29BFE))),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(fontSize: 9, color: Color(0xFF6C6C8A))),
        ],
      );

  Widget _permBanner() {
    // 自动拦截总开关关闭时，直接显示暂停状态，不查权限
    if (!s.autoInterceptEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6C6C8A).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C6C8A).withOpacity(0.3)),
        ),
        child: Row(
          children: const [
            Text('⏸️', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Expanded(
              child: Text('自动拦截已暂停，可在「设置」中开启',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9A9AB0))),
            ),
          ],
        ),
      );
    }
    return FutureBuilder<bool>(
      future: NativeBridge.isAccessibilityEnabled(),
      builder: (context, snap) {
        final on = snap.data == true;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF00B894).withOpacity(0.08) : const Color(0xFFFDCB6E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? const Color(0xFF00B894).withOpacity(0.4) : const Color(0xFFFDCB6E).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Text(on ? '✅' : '⚠️', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  on ? '拦截服务运行中，正在守护你的专注' : '拦截服务未开启，点此去设置',
                  style: TextStyle(fontSize: 11, color: on ? const Color(0xFF00B894) : const Color(0xFFFDCB6E)),
                ),
              ),
              if (!on)
                GestureDetector(
                  onTap: () => NativeBridge.openAccessibilitySettings(),
                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFDCB6E)),
                ),
            ],
          ),
        );
      },
    );
  }
}
