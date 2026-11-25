import 'package:flutter/material.dart';
import '../core/models.dart';

class StatsPage extends StatelessWidget {
  final AppState state;
  const StatsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            final days = _last7Days();
            final values = days.map((r) => r.focus).toList();
            final max = values.fold<int>(1, (a, b) => a > b ? a : b);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  const Text('📊 清醒报告', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('看看你的专注力变化趋势', style: TextStyle(fontSize: 12, color: Color(0xFFA8A8C4))),
                  const SizedBox(height: 20),
                  // 柱状图
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('近 7 天专注次数', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (i) {
                              final v = values[i];
                              final h = (v / max * 120).clamp(4.0, 120.0);
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('$v', style: const TextStyle(fontSize: 9, color: Color(0xFFA8A8C4))),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 22,
                                    height: h,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(days[i].date.substring(5), style: const TextStyle(fontSize: 8, color: Color(0xFF6C6C8A))),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 总览
                  Row(
                    children: [
                      _summaryCard('${state.totalFocus}', '总专注'),
                      const SizedBox(width: 10),
                      _summaryCard('${state.totalResist}', '总拦截'),
                      const SizedBox(width: 10),
                      _summaryCard('${state.streak}', '连续天'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('🏆 成就徽章', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: kAchievements.length,
                    itemBuilder: (context, i) {
                      final a = kAchievements[i];
                      final unlocked = a.check(state);
                      return Opacity(
                        opacity: unlocked ? 1 : 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: unlocked
                                  ? const Color(0xFFFDCB6E).withOpacity(0.4)
                                  : Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(unlocked ? a.icon : '🔒', style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(a.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFA29BFE))),
              Text(l, style: const TextStyle(fontSize: 9, color: Color(0xFF6C6C8A))),
            ],
          ),
        ),
      );

  List<DayRecord> _last7Days() {
    final now = DateTime.now();
    final map = {for (final r in state.history) r.date: r};
    final list = <DayRecord>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (key == state.todayDate) {
        list.add(DayRecord(date: key, scroll: state.todayScroll, focus: state.todayFocus, resist: state.todayResist));
      } else {
        list.add(map[key] ?? DayRecord(date: key, scroll: 0, focus: 0, resist: 0));
      }
    }
    return list;
  }
}
