import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/bridge.dart';
import '../widgets/pet_avatar.dart';
import 'intercept_page.dart';

class HomePage extends StatefulWidget {
  final AppState state;
  final VoidCallback onGoSettings;
  const HomePage({super.key, required this.state, required this.onGoSettings});

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
                      const SizedBox(height: 20),
                      _guardCard(),
                      if (s.manualRecordEnabled) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('记录你的行为'),
                        const SizedBox(height: 10),
                        _actionGrid(),
                      ],
                      const SizedBox(height: 20),
                      _todayStats(),
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

  Widget _guardCard() {
    return FutureBuilder<List<bool>>(
      future: Future.wait([
        NativeBridge.hasUsageAccess(),
        NativeBridge.isAccessibilityEnabled(),
      ]),
      builder: (context, snap) {
        final usage = snap.data?[0] ?? false;
        final access = snap.data?[1] ?? false;
        final targetCount = s.blockedApps.length;
        final on = s.autoInterceptEnabled;
        // 状态：关闭 / 开启但权限未全 / 正常运行
        final statusText = !on
            ? '已暂停'
            : (access && usage)
                ? '守护中'
                : '待设置权限';
        final statusColor = !on
            ? const Color(0xFF9A9AB0)
            : (access && usage)
                ? const Color(0xFF00B894)
                : const Color(0xFFFDCB6E);
        final statusIcon = !on ? '⏸️' : (access && usage) ? '🟢' : '⚠️';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1E38), Color(0xFF242442)],
            ),
            border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('🛡️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Text('自动拦截', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$statusIcon $statusText',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 通俗说明
              const Text(
                '开启后，每当你点开小红书等目标 App，会立刻弹出一个小挑战拦你一下，'
                '完成就放行。不是按时间强制，只是打断下意识点开。',
                style: TextStyle(fontSize: 11, color: Color(0xFFA8A8C4), height: 1.6),
              ),
              const SizedBox(height: 12),
              // 三项状态
              Row(
                children: [
                  _guardChip('无障碍', access),
                  const SizedBox(width: 8),
                  _guardChip('使用统计', usage),
                  const SizedBox(width: 8),
                  _guardChip('监控 $targetCount 个 App', targetCount > 0),
                ],
              ),
              if (!on || !access || !usage) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDCB6E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    !on
                        ? '自动拦截已关闭，到「设置」打开开关即可启用。'
                        : '权限未齐全，到「设置」按提示开启无障碍和使用统计。',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFFDCB6E), height: 1.5),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showInterceptSheet(context, s, 'demo', '短视频'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7675).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF7675).withOpacity(0.5)),
                        ),
                        child: const Center(
                          child: Text('▶️ 测试拦截效果',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF7675))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onGoSettings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.5)),
                        ),
                        child: const Center(
                          child: Text('⚙️ 去设置',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA29BFE))),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _guardChip(String label, bool ok) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFF00B894).withOpacity(0.1) : const Color(0xFF6C6C8A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 12, color: ok ? const Color(0xFF00B894) : const Color(0xFF6C6C8A)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: ok ? const Color(0xFF00B894) : const Color(0xFF9A9AB0))),
          ],
        ),
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

}
