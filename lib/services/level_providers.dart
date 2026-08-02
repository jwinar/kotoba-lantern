import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/jlpt_repository.dart';

/// Persists which JLPT level the user is studying, so the app opens where
/// they left off rather than resetting to N5 every launch.
class LevelService {
  static const String _key = 'jlptLevel';

  Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt(_key);
    return jlptLevels.contains(level) ? level! : 5;
  }

  Future<void> save(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, level);
  }
}

final levelServiceProvider = Provider<LevelService>((ref) => LevelService());

/// The level currently being studied. Seeded from storage at launch (see
/// main.dart's override) so the first frame is already on the right deck.
class LevelNotifier extends Notifier<int> {
  LevelNotifier([this._initial = 5]);

  final int _initial;

  @override
  int build() => _initial;

  Future<void> setLevel(int level) async {
    if (!jlptLevels.contains(level) || level == state) return;
    state = level;
    await ref.read(levelServiceProvider).save(level);
  }
}

final levelProvider = NotifierProvider<LevelNotifier, int>(LevelNotifier.new);

/// How a level is labelled in the UI.
String levelLabel(int level) => 'N$level';
