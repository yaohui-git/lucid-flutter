import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 宠物状态档位
enum PetLevel { thriving, okay, tired, sick, critical }

class PetInfo {
  final PetLevel level;
  final String emoji;
  final String label;
  final String subtitle;
  final int color;

  const PetInfo({
    required this.level,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

const Map<PetLevel, PetInfo> kPetInfo = {
  PetLevel.thriving: PetInfo(
    level: PetLevel.thriving,
    emoji: '🌟',
    label: '生机勃勃',
    subtitle: '状态绝佳，思维清晰',
    color: 0xFFFF9FF3,
  ),
  PetLevel.okay: PetInfo(
    level: PetLevel.okay,
    emoji: '🙂',
    label: '还不错',
    subtitle: '略有疲惫，尚能坚持',
    color: 0xFFA29BFE,
  ),
  PetLevel.tired: PetInfo(
    level: PetLevel.tired,
    emoji: '😵',
    label: '有点晕',
    subtitle: '脑雾聚集，需要休息',
    color: 0xFFFDCB6E,
  ),
  PetLevel.sick: PetInfo(
    level: PetLevel.sick,
    emoji: '🤢',
    label: '生病了',
    subtitle: '脑虫猖獗，急需清醒',
    color: 0xFFB2BEC3,
  ),
  PetLevel.critical: PetInfo(
    level: PetLevel.critical,
    emoji: '☠️',
    label: '濒危',
    subtitle: '危险！清醒兽即将消亡',
    color: 0xFF636E72,
  ),
};

/// 根据脑力值判定状态
PetLevel levelFromHealth(double health) {
  if (health >= 80) return PetLevel.thriving;
  if (health >= 60) return PetLevel.okay;
  if (health >= 40) return PetLevel.tired;
  if (health >= 20) return PetLevel.sick;
  return PetLevel.critical;
}

/// 宠物对话库
const Map<PetLevel, List<String>> kSpeech = {
  PetLevel.thriving: [
    '今天也要一起保持清醒哦！✨',
    '我感觉脑子好清爽！谢谢你 🥰',
    '你专注的样子最帅了！💪',
    '我们一起把脑虫赶跑吧！🌟',
  ],
  PetLevel.okay: [
    '还行吧…继续保持？🤔',
    '别刷太久哦，我会担心的 😶',
    '再专注一会儿我就精神了！💪',
  ],
  PetLevel.tired: [
    '我有点晕…别再刷了 😵',
    '脑子里好像糊了一层雾… 😶‍🌫️',
    '求你了，放下手机休息一下 🥺',
  ],
  PetLevel.sick: [
    '咳咳…脑虫快把我吃掉了… 🤢',
    '我好难受…你就不能清醒一点吗？ 😭',
    '脑雾好重…我看不清了… 💀',
  ],
  PetLevel.critical: [
    '我…我不行了…救救我… 🆘',
    '你已经变成脑虫的奴隶了… ☠️',
    '我快死了…最后求你一次… 😭',
  ],
};

/// 进化形态
class Evolution {
  final String icon;
  final String name;
  final String desc;
  final int needFocus;
  const Evolution(this.icon, this.name, this.desc, this.needFocus);
}

const List<Evolution> kEvolutions = [
  Evolution('🧬', '脑细胞', '最初的形态，一颗脆弱的神经元', 0),
  Evolution('🧠', '小脑灵', '开始有了自我意识，会撒娇了', 5),
  Evolution('🦊', '清醒狐', '机敏聪慧，能嗅到脑虫的气息', 15),
  Evolution('🦉', '智慧鸮', '深夜的守护者，洞察一切分心', 30),
  Evolution('🐉', '觉醒龙', '专注力的终极形态，脑雾克星', 60),
  Evolution('🌟', '纯粹意识', '超越形态，与专注合为一体', 100),
];

/// 成就
class Achievement {
  final String icon;
  final String name;
  final String desc;
  final bool Function(AppState s) check;
  const Achievement(this.icon, this.name, this.desc, this.check);
}

const List<Achievement> kAchievements = [
  Achievement('🌱', '初次清醒', '完成第一次专注', _c1),
  Achievement('🛡️', '拦截新手', '成功拦截一次冲动', _c2),
  Achievement('🔥', '七日连击', '连续专注 7 天', _c3),
  Achievement('💪', '专注十次', '累计专注 10 次', _c4),
  Achievement('🧠', '脑力满格', '脑力值回到 100%', _c5),
  Achievement('🏆', '清醒大师', '清醒值达到 100', _c6),
];

bool _c1(AppState s) => s.totalFocus >= 1;
bool _c2(AppState s) => s.totalResist >= 1;
bool _c3(AppState s) => s.streak >= 7;
bool _c4(AppState s) => s.totalFocus >= 10;
bool _c5(AppState s) => s.health >= 100 && s.totalFocus >= 5;
bool _c6(AppState s) => s.lucidPoints >= 100;

/// 一天的记录
class DayRecord {
  final String date;
  final int scroll;
  final int focus;
  final int resist;
  DayRecord({
    required this.date,
    required this.scroll,
    required this.focus,
    required this.resist,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'scroll': scroll,
        'focus': focus,
        'resist': resist,
      };

  factory DayRecord.fromJson(Map<String, dynamic> j) => DayRecord(
        date: j['date'] ?? '',
        scroll: j['scroll'] ?? 0,
        focus: j['focus'] ?? 0,
        resist: j['resist'] ?? 0,
      );
}

/// 全局状态（ChangeNotifier）
class AppState with ChangeNotifier {
  double health = 100;
  int lucidPoints = 0;
  int streak = 0;
  int totalFocus = 0;
  int totalScroll = 0;
  int totalResist = 0;

  late String todayDate;
  int todayScroll = 0;
  int todayFocus = 0;
  int todayResist = 0;
  int todayMinutes = 0;

  List<String> achievements = [];
  List<DayRecord> history = [];
  List<String> blockedApps = [];

  AppState() {
    todayDate = _dateKey(DateTime.now());
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  PetInfo get petInfo => kPetInfo[levelFromHealth(health)]!;

  void _rollDayIfNeeded() {
    final key = _dateKey(DateTime.now());
    if (key == todayDate) return;
    // 归档昨天
    history.insert(
      0,
      DayRecord(
        date: todayDate,
        scroll: todayScroll,
        focus: todayFocus,
        resist: todayResist,
      ),
    );
    if (history.length > 30) history = history.sublist(0, 30);
    // 计算连续天数：若昨天有专注则延续，否则归零
    if (todayFocus == 0) {
      streak = 0;
    }
    todayDate = key;
    todayScroll = 0;
    todayFocus = 0;
    todayResist = 0;
    todayMinutes = 0;
  }

  void scroll({int times = 1}) {
    _rollDayIfNeeded();
    for (int i = 0; i < times; i++) {
      health = (health - 15).clamp(0, 100);
      lucidPoints = (lucidPoints - 5).clamp(0, 999999);
      todayScroll += 1;
      totalScroll += 1;
    }
    notifyListeners();
  }

  void focus() {
    _rollDayIfNeeded();
    final before = levelFromHealth(health);
    health = (health + 12).clamp(0, 100);
    lucidPoints += 10;
    todayFocus += 1;
    totalFocus += 1;
    todayMinutes += 5;
    if (before != PetLevel.thriving && levelFromHealth(health) == PetLevel.thriving) {
      streak += 1;
    }
    _checkAchievements();
    notifyListeners();
  }

  void resist() {
    _rollDayIfNeeded();
    health = (health + 8).clamp(0, 100);
    lucidPoints += 15;
    todayResist += 1;
    totalResist += 1;
    todayMinutes += 2;
    _checkAchievements();
    notifyListeners();
  }

  void breathe() {
    _rollDayIfNeeded();
    health = (health + 6).clamp(0, 100);
    todayMinutes += 2;
    notifyListeners();
  }

  void addScreenMinutes(int minutes) {
    _rollDayIfNeeded();
    if (minutes > 0) todayMinutes += minutes;
    notifyListeners();
  }

  void _checkAchievements() {
    for (final a in kAchievements) {
      if (a.check(this) && !achievements.contains(a.name)) {
        achievements.add(a.name);
      }
    }
  }

  void setBlockedApps(List<String> apps) {
    blockedApps = List<String>.from(apps);
    notifyListeners();
  }

  void reset() {
    health = 100;
    lucidPoints = 0;
    streak = 0;
    totalFocus = 0;
    totalScroll = 0;
    totalResist = 0;
    todayDate = _dateKey(DateTime.now());
    todayScroll = 0;
    todayFocus = 0;
    todayResist = 0;
    todayMinutes = 0;
    achievements = [];
    history = [];
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'health': health,
        'lucidPoints': lucidPoints,
        'streak': streak,
        'totalFocus': totalFocus,
        'totalScroll': totalScroll,
        'totalResist': totalResist,
        'todayDate': todayDate,
        'todayScroll': todayScroll,
        'todayFocus': todayFocus,
        'todayResist': todayResist,
        'todayMinutes': todayMinutes,
        'achievements': achievements,
        'history': history.map((e) => e.toJson()).toList(),
        'blockedApps': blockedApps,
      };

  void loadFromJson(Map<String, dynamic> j) {
    health = (j['health'] as num?)?.toDouble() ?? 100;
    lucidPoints = j['lucidPoints'] ?? 0;
    streak = j['streak'] ?? 0;
    totalFocus = j['totalFocus'] ?? 0;
    totalScroll = j['totalScroll'] ?? 0;
    totalResist = j['totalResist'] ?? 0;
    todayDate = j['todayDate'] ?? _dateKey(DateTime.now());
    todayScroll = j['todayScroll'] ?? 0;
    todayFocus = j['todayFocus'] ?? 0;
    todayResist = j['todayResist'] ?? 0;
    todayMinutes = j['todayMinutes'] ?? 0;
    achievements = List<String>.from(j['achievements'] ?? []);
    history = ((j['history'] as List?) ?? [])
        .map((e) => DayRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    blockedApps = List<String>.from(j['blockedApps'] ?? defaultBlockedApps);
    _rollDayIfNeeded();
  }

  static const List<String> defaultBlockedApps = [
    'com.ss.android.ugc.aweme', // 抖音
    'com.kuaishou.nebula', // 快手
    'com.xingin.xhs', // 小红书
    'com.tencent.mm', // 微信
    'com.sina.weibo', // 微博
    'tv.danmaku.bili', // B站
  ];

  String toStorageString() => jsonEncode(toJson());

  static Map<String, dynamic> fromStorageString(String s) =>
      Map<String, dynamic>.from(jsonDecode(s));
}
