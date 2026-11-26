import 'package:flutter/material.dart';
import '../core/bridge.dart';

/// 拦截链路诊断页：把原生每一环的状态和日志可视化，方便定位「打开目标App没弹窗」的问题。
class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  Map<String, dynamic> _snap = {};
  String _log = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final snap = await NativeBridge.diagSnapshot();
    final log = await NativeBridge.getDiagLog();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _log = log.isEmpty ? '（暂无日志）' : log;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await NativeBridge.clearDiagLog();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final access = _snap['accessibilityEnabled'] == true;
    final usage = _snap['usageAccess'] == true;
    final auto = _snap['autoIntercept'] == true;
    final sink = _snap['eventSinkReady'] == true;
    final List<dynamic> blocked = (_snap['blockedApps'] as List?) ?? [];
    final pending = (_snap['pendingIntercept'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14142A),
        title: const Text('🔍 拦截诊断', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空日志',
            onPressed: _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _guideCard(),
              const SizedBox(height: 16),
              _section('① 权限与开关', [
                _row('无障碍服务', access, access ? '已开启' : '未开启（拦截无法工作）'),
                _row('使用情况访问权', usage, usage ? '已授予' : '未授予'),
                _row('自动拦截总开关', auto, auto ? '开' : '关（不会拦截）'),
                _row('Flutter事件通道', sink, sink ? '已连接' : '未连接'),
              ]),
              const SizedBox(height: 12),
              _infoRow('拦截名单', '${blocked.length} 个: ${blocked.join(', ')}'),
              const SizedBox(height: 4),
              _infoRow('待发送事件', pending.isEmpty ? '无' : pending),
              const SizedBox(height: 16),
              _section('② 全链路日志（最近 ${_log.contains('\n') ? _log.split('\n').length : 1} 行）', [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0A0A14),
                  child: SelectableText(
                    _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFB8F5D0),
                      height: 1.5,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              const Text(
                '把上面「权限与开关」和「日志」的内容截图发给开发者，就能定位卡在哪一步。',
                style: TextStyle(fontSize: 11, color: Color(0xFF8FB0B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('怎么测（30 秒）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA29BFE))),
          SizedBox(height: 8),
          Text(
            '1. 先点右上角🗑️清空日志\n'
            '2. 完全退出小红书，从桌面重新点开它\n'
            '3. 回到这个页面点右上角🔄刷新\n'
            '4. 看下面日志里有没有「★命中目标」这一行',
            style: TextStyle(fontSize: 12, color: Color(0xFFC8C8DC), height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFA8A8C4))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ],
    );
  }

  Widget _row(String label, bool ok, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error, size: 18, color: ok ? const Color(0xFF00B894) : const Color(0xFFFF7675)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(status, style: TextStyle(fontSize: 11, color: ok ? const Color(0xFF00B894) : const Color(0xFFFF7675))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFFA8A8C4))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFFC8C8DC)))),
        ],
      ),
    );
  }
}
