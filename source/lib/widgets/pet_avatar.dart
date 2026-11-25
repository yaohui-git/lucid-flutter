import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';

/// 自绘清醒兽：状态不同 → 颜色、眼睛、嘴巴变化，带呼吸浮动动画
class PetAvatar extends StatefulWidget {
  final PetInfo info;
  final double size;
  const PetAvatar({super.key, required this.info, this.size = 220});

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.info.level;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final float = math.sin(_c.value * math.pi * 2) * 6;
        return Transform.translate(
          offset: Offset(0, -float),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PetPainter(info: widget.info, t: _c.value),
          ),
        );
      },
    );
  }
}

class _PetPainter extends CustomPainter {
  final PetInfo info;
  final double t;
  _PetPainter({required this.info, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 4;
    final s = w / 240;
    final base = Color(info.color);
    final level = info.level;
    final lvlIndex = PetLevel.values.indexOf(level);

    // 抖动：生病/濒危时轻微抖动
    double shake = 0;
    if (lvlIndex >= 3) {
      shake = math.sin(t * 40) * (lvlIndex == 4 ? 3 : 1.5);
    }
    canvas.save();
    canvas.translate(shake, 0);

    // 光晕
    final glow = Paint()
      ..color = base.withOpacity(lvlIndex >= 3 ? 0.12 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, cy), 92.0 * s, glow);

    // 触角
    final antenna = Paint()
      ..color = const Color(0xFF00D2D3).withOpacity(lvlIndex >= 3 ? 0.3 : 1)
      ..strokeWidth = 3.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 25.0 * s, cy - 68.0 * s)
        ..quadraticBezierTo(cx - 32.0 * s, cy - 92.0 * s, cx - 20.0 * s, cy - 100.0 * s),
      antenna,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 25.0 * s, cy - 68.0 * s)
        ..quadraticBezierTo(cx + 32.0 * s, cy - 92.0 * s, cx + 20.0 * s, cy - 100.0 * s),
      antenna,
    );
    final dot = Paint()..color = const Color(0xFF00D2D3).withOpacity(lvlIndex >= 3 ? 0.3 : 1);
    canvas.drawCircle(Offset(cx - 20.0 * s, cy - 101.0 * s), 5.0 * s, dot);
    canvas.drawCircle(Offset(cx + 20.0 * s, cy - 101.0 * s), 5.0 * s, dot);

    // 身体
    final body = Paint()..color = base;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 152.0 * s, height: 144.0 * s),
      body,
    );

    // 脑回纹路
    final fold = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 3.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final p in <List<double>>[
      [0.0, -62, -18, -32, 0, -2],
      [-38.0, -38, -50, -16, -32, 8],
      [38.0, -38, 50, -16, 32, 8],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx + p[0] * s, cy + p[1] * s)
          ..quadraticBezierTo(cx + p[2] * s, cy + p[3] * s, cx + p[4] * s, cy + p[5] * s),
        fold,
      );
    }

    // 眼睛
    final blink = (t * 2) % 1 > 0.94 ? 0.15 : 1.0; // 偶尔眨眼
    final eyeY = cy - 8.0 * s;
    final eyeOpen = (lvlIndex >= 2 ? 8 : 18) * s * blink;
    if (lvlIndex == 4) {
      // X 眼
      final xeye = Paint()
        ..color = const Color(0xFFFF7675)
        ..strokeWidth = 3.5 * s
        ..strokeCap = StrokeCap.round;
      _drawX(canvas, cx - 28.0 * s, eyeY, 9.0 * s, xeye);
      _drawX(canvas, cx + 28.0 * s, eyeY, 9.0 * s, xeye);
    } else {
      // 白眼球
      final white = Paint()..color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 28.0 * s, eyeY), width: 30.0 * s, height: eyeOpen * 2),
        white,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 28.0 * s, eyeY), width: 30.0 * s, height: eyeOpen * 2),
        white,
      );
      // 瞳孔
      final pupil = Paint()..color = const Color(0xFF2D3436);
      final pr = lvlIndex >= 3 ? 5.0 * s : 7.0 * s;
      canvas.drawCircle(Offset(cx - 26.0 * s, eyeY + 2.0 * s), pr, pupil);
      canvas.drawCircle(Offset(cx + 30.0 * s, eyeY + 2.0 * s), pr, pupil);
      if (blink > 0.5) {
        final shine = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx - 23.0 * s, eyeY - 1.0 * s), 2.5 * s, shine);
        canvas.drawCircle(Offset(cx + 33.0 * s, eyeY - 1.0 * s), 2.5 * s, shine);
      }
    }

    // 腮红
    final blush = Paint()..color = const Color(0xFFFF7675).withOpacity(0.45);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 52.0 * s, cy + 12.0 * s), width: 18.0 * s, height: 10.0 * s), blush);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 52.0 * s, cy + 12.0 * s), width: 18.0 * s, height: 10.0 * s), blush);

    // 嘴巴
    final mouth = Paint()
      ..color = const Color(0xFF2D3436)
      ..strokeWidth = 3.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final my = cy + 24.0 * s;
    if (level == PetLevel.thriving || level == PetLevel.okay) {
      // 微笑
      canvas.drawPath(
        Path()..moveTo(cx - 12.0 * s, my).quadraticBezierTo(cx, my + 14.0 * s, cx + 12.0 * s, my),
        mouth,
      );
    } else if (level == PetLevel.tired) {
      // 平嘴
      canvas.drawLine(Offset(cx - 8.0 * s, my + 4.0 * s), Offset(cx + 8.0 * s, my + 4.0 * s), mouth);
    } else {
      // 难过
      canvas.drawPath(
        Path()..moveTo(cx - 12.0 * s, my + 6.0 * s).quadraticBezierTo(cx, my - 8.0 * s, cx + 12.0 * s, my + 6.0 * s),
        mouth,
      );
    }

    // 小脚
    final foot = Paint()..color = base;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 26.0 * s, cy + 70.0 * s), width: 28.0 * s, height: 14.0 * s), foot);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 26.0 * s, cy + 70.0 * s), width: 28.0 * s, height: 14.0 * s), foot);

    canvas.restore();
  }

  void _drawX(Canvas c, double x, double y, double r, Paint p) {
    c.drawLine(Offset(x - r, y - r), Offset(x + r, y + r), p);
    c.drawLine(Offset(x + r, y - r), Offset(x - r, y + r), p);
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) => old.t != t || old.info.level != info.level;
}
