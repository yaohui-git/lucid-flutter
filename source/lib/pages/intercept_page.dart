import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models.dart';

/// 弹出全屏拦截挑战页
void showInterceptSheet(BuildContext context, AppState state, String package, String name) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => InterceptPage(state: state, package: package, name: name),
  );
}

enum _ChallengeType { breathe, tap, memory }

class InterceptPage extends StatefulWidget {
  final AppState state;
  final String package;
  final String name;
  const InterceptPage({
    super.key,
    required this.state,
    required this.package,
    required this.name,
  });

  @override
  State<InterceptPage> createState() => _InterceptPageState();
}

class _InterceptPageState extends State<InterceptPage> with SingleTickerProviderStateMixin {
  late final _ChallengeType _type;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  int _tapCount = 0;
  int _breathRound = 0;
  bool _inhale = true;
  Timer? _breathTimer;
  String _memoryCode = '';
  final _memoryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final types = _ChallengeType.values;
    _type = types[Random().nextInt(types.length)];
    if (_type == _ChallengeType.breathe) _startBreathCycle();
    if (_type == _ChallengeType.memory) {
      _memoryCode = (1000 + Random().nextInt(9000)).toString();
    }
  }

  void _startBreathCycle() {
    _breathTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _inhale = !_inhale;
        if (!_inhale) _breathRound += 1;
      });
      if (_breathRound >= 3) {
        _breathTimer?.cancel();
        _win();
      }
    });
  }

  void _win() {
    widget.state.resist();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ 拦截成功！你战胜了冲动，+15 清醒值'),
          backgroundColor: Color(0xFF00B894),
        ),
      );
    }
  }

  void _giveIn() {
    widget.state.scroll();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _pulse.dispose();
    _memoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFF16162A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('😰', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  '等等！你要打开它？',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '清醒兽检测到你正在打开「${widget.name}」\n'
                  '完成一个小挑战，证明你不是下意识点开的',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFA8A8C4), height: 1.6),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '💡 完成后立即放行，你还是可以正常刷；也可以选择放弃',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xFF00B894), height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildChallenge()),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _giveIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C6C8A),
                      side: const BorderSide(color: Color(0xFF33334D)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('😔 还是要刷，放弃抵抗'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallenge() {
    switch (_type) {
      case _ChallengeType.breathe:
        return _breatheChallenge();
      case _ChallengeType.tap:
        return _tapChallenge();
      case _ChallengeType.memory:
        return _memoryChallenge();
    }
  }

  Widget _breatheChallenge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🌬️ 深呼吸挑战', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('跟着圈圈呼吸 3 次', style: TextStyle(fontSize: 12, color: Color(0xFFA8A8C4))),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final scale = _inhale ? 1.0 + _pulse.value * 0.25 : 1.25 - _pulse.value * 0.25;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2D3).withOpacity(0.18),
                  border: Border.all(color: const Color(0xFF00D2D3), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _inhale ? '吸气' : '呼气',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00D2D3)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _breathRound ? const Color(0xFF00D2D3) : Colors.white12,
            ),
          )),
        ),
      ],
    );
  }

  Widget _tapChallenge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('👆 清醒度测试', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('快速点击 10 次，证明你手速在线', style: TextStyle(fontSize: 12, color: Color(0xFFA8A8C4))),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            setState(() => _tapCount++);
            if (_tapCount >= 10) _win();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.5), blurRadius: 20)],
            ),
            alignment: Alignment.center,
            child: Text(
              '$_tapCount / 10',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _memoryChallenge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🧠 记忆挑战', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('记住下面 4 个数字', style: TextStyle(fontSize: 12, color: Color(0xFFA8A8C4))),
        const SizedBox(height: 16),
        Text(
          _memoryCode,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
            color: Color(0xFFFDCB6E),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          child: TextField(
            controller: _memoryCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 10),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _checkMemory(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _checkMemory,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('确认'),
        ),
      ],
    );
  }

  void _checkMemory() {
    if (_memoryCtrl.text.trim() == _memoryCode) {
      _win();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 记错了，再试一次')),
      );
      _memoryCtrl.clear();
    }
  }
}
