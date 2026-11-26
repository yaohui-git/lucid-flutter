import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/models.dart';
import 'core/storage.dart';
import 'core/bridge.dart';
import 'pages/home_page.dart';
import 'pages/evolution_page.dart';
import 'pages/stats_page.dart';
import 'pages/settings_page.dart';
import 'pages/intercept_page.dart';
import 'pages/onboarding_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LucidApp());
}

class LucidApp extends StatefulWidget {
  const LucidApp({super.key});

  @override
  State<LucidApp> createState() => _LucidAppState();
}

class _LucidAppState extends State<LucidApp> {
  final AppState state = AppState();
  bool _ready = false;
  bool _onboarded = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Storage.instance.init();
    _onboarded = await Storage.instance.isOnboarded();
    final loaded = await Storage.instance.loadState();
    state.loadFromJson(loaded.toJson());
    // 同步拦截名单与开关给原生
    await NativeBridge.syncBlockedApps(state.blockedApps);
    await NativeBridge.syncAutoIntercept(state.autoInterceptEnabled);
    // 监听原生拦截事件
    NativeBridge.listenIntercept((package, name) {
      if (!mounted) return;
      showInterceptSheet(context, state, package, name);
    });
    // 定时读取屏幕使用时长
    _startUsagePolling();
    setState(() => _ready = true);
  }

  Timer? _pollTimer;
  void _startUsagePolling() {
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final usage = await NativeBridge.todayUsageMinutes();
      final blocked = state.blockedApps;
      int total = 0;
      blocked.forEach((p) {
        total += usage[p] ?? 0;
      });
      if (total > 0) {
        // 每累计 5 分钟目标应用使用，记一次刷机
        final sessions = total ~/ 5;
        if (sessions > state.todayScroll) {
          final delta = sessions - state.todayScroll;
          state.scroll(times: delta > 3 ? 3 : delta);
          await Storage.instance.saveState(state);
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    NativeBridge.dispose();
    super.dispose();
  }

  void _persist() => Storage.instance.saveState(state);

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F0F1A),
          body: Center(child: CircularProgressIndicator(color: Color(0xFFA29BFE))),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '清醒兽 · Lucid',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C5CE7),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C5CE7),
          secondary: const Color(0xFF00D2D3),
        ),
        useMaterial3: true,
      ),
      home: _onboarded
          ? MainShell(state: state, onPersist: _persist)
          : OnboardingPage(
              state: state,
              onDone: () async {
                await Storage.instance.saveState(state);
                await Storage.instance.setOnboarded();
                if (!mounted) return;
                setState(() => _onboarded = true);
              },
            ),
    );
  }
}

/// 底部导航 + 页面容器
class MainShell extends StatefulWidget {
  final AppState state;
  final VoidCallback onPersist;
  const MainShell({super.key, required this.state, required this.onPersist});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _pages.addAll([
      HomePage(state: widget.state),
      EvolutionPage(state: widget.state),
      StatsPage(state: widget.state),
      SettingsPage(state: widget.state),
    ]);
  }

  void _onStateChanged() => widget.onPersist();

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      Icons.pets_rounded,
      Icons.psychology_rounded,
      Icons.bar_chart_rounded,
      Icons.settings_rounded,
    ];
    const labels = ['宠物', '进化', '数据', '设置'];

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF14142A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final active = i == _index;
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i], color: active ? const Color(0xFFA29BFE) : const Color(0xFF6C6C8A), size: 24),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            color: active ? const Color(0xFFA29BFE) : const Color(0xFF6C6C8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
