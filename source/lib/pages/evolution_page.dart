import 'package:flutter/material.dart';
import '../core/models.dart';

class EvolutionPage extends StatelessWidget {
  final AppState state;
  const EvolutionPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            final currentIdx = kEvolutions.indexWhere((e) => state.totalFocus < e.needFocus) - 1;
            final current = currentIdx < 0 ? 0 : currentIdx;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  const Text('🧬 进化图鉴', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('你的专注力会改变清醒兽的形态', style: TextStyle(fontSize: 12, color: Color(0xFFA8A8C4))),
                  const SizedBox(height: 8),
                  Text(
                    '当前形态：${kEvolutions[current].name} · 累计专注 ${state.totalFocus} 次',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF00D2D3), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(kEvolutions.length, (i) {
                    final ev = kEvolutions[i];
                    final unlocked = state.totalFocus >= ev.needFocus;
                    final isCurrent = i == current;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: unlocked
                              ? const Color(0xFF00D2D3).withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.4,
                        child: Row(
                          children: [
                            Text(ev.icon, style: const TextStyle(fontSize: 38)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(ev.desc, style: const TextStyle(fontSize: 10, color: Color(0xFFA8A8C4))),
                                  const SizedBox(height: 4),
                                  Text('需专注 ${ev.needFocus} 次', style: const TextStyle(fontSize: 9, color: Color(0xFFFDCB6E))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? const Color(0xFF00D2D3).withOpacity(0.15)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isCurrent ? '当前' : unlocked ? '已解锁' : '未解锁',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? const Color(0xFF00D2D3) : const Color(0xFF6C6C8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
