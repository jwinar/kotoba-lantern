import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_service.dart';

final themeModeServiceProvider = Provider<ThemeModeService>((ref) {
  return ThemeModeService();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier([this._initial = ThemeMode.system]);

  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModeServiceProvider).save(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
