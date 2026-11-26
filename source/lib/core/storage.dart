import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// 本地持久化
class Storage {
  static const _keyState = 'lucid_state_v1';
  static const _keyOnboarded = 'lucid_onboarded_v1';
  static final Storage instance = Storage._internal();
  Storage._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<AppState> loadState() async {
    final state = AppState();
    final raw = _prefs?.getString(_keyState);
    if (raw != null && raw.isNotEmpty) {
      try {
        state.loadFromJson(AppState.fromStorageString(raw));
      } catch (_) {
        // 数据损坏时回退到默认
      }
    } else {
      state.setBlockedApps(AppState.defaultBlockedApps);
    }
    return state;
  }

  Future<void> saveState(AppState state) async {
    await _prefs?.setString(_keyState, state.toStorageString());
  }

  Future<bool> isOnboarded() async => _prefs?.getBool(_keyOnboarded) ?? false;

  Future<void> setOnboarded() async => await _prefs?.setBool(_keyOnboarded, true);

  Future<void> clear() async {
    await _prefs?.remove(_keyState);
  }
}
