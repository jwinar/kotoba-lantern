import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'services/theme_mode_providers.dart';
import 'services/theme_mode_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read before runApp so the first frame is already in the right theme -
  // otherwise a dark-mode user gets a flash of the light hero panel.
  final savedThemeMode = await ThemeModeService().load();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => ThemeModeNotifier(savedThemeMode)),
      ],
      child: const KotobaLanternApp(),
    ),
  );
}

class KotobaLanternApp extends ConsumerWidget {
  const KotobaLanternApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Kotoba Lantern',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
