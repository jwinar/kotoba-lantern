import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotoba_lantern/main.dart';
import 'package:kotoba_lantern/screens/word_screen.dart';
import 'package:kotoba_lantern/services/level_providers.dart';
import 'package:kotoba_lantern/services/word_providers.dart';
import 'package:kotoba_lantern/theme/app_theme.dart';

IconButton _iconButtonFor(WidgetTester tester, IconData icon) {
  return tester.widget<IconButton>(
    find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
  );
}

void main() {
  late ProviderContainer container;

  setUp(() {
    // Progress and view history both go through shared_preferences; an
    // empty in-memory store keeps each test independent.
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    // Works around rootBundle's cross-test asset-loading cache causing
    // pumpAndSettle to hang on the second and later tests in this file.
    rootBundle.clear();
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const KotobaLanternApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpWordScreen(WidgetTester tester) async {
    // The study card's breathing echo loops continuously while mounted, so
    // it never stops scheduling frames - pumpAndSettle would hang forever
    // waiting for it to settle. Exercise the same reduced-motion path real
    // users can enable, which holds the echo at its resting opacity.
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const WordScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('app shell renders the dashboard home screen', (tester) async {
    final n5 = (await container.read(wordsProvider.future)).length;
    await pumpApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Kotoba Lantern'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);
    expect(find.text('OF $n5'), findsOneWidget);
    expect(find.text('0% lit — $n5 words still dark'), findsOneWidget);
    // Every level is offered, N5 first.
    expect(find.text('N5'), findsOneWidget);
    expect(find.text('N1'), findsOneWidget);
  });

  testWidgets('the study card shows the word, its reading and its example', (
    tester,
  ) async {
    await pumpWordScreen(tester);

    // N5's first word by list order.
    expect(find.text('ああ'), findsWidgets); // headword + breathing echo
    expect(find.text('AA'), findsOneWidget);
    expect(find.text('Ah!, Oh!'), findsOneWidget);
  });

  testWidgets('browses the deck via Prev/Next', (tester) async {
    final n5 = (await container.read(wordsProvider.future)).length;
    await pumpWordScreen(tester);

    expect(find.text('1 / $n5'), findsOneWidget);

    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2 / $n5'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('1 / $n5'), findsOneWidget);
  });

  testWidgets('Previous is disabled at the first word', (tester) async {
    await pumpWordScreen(tester);

    expect(_iconButtonFor(tester, Icons.arrow_back_ios).onPressed, isNull);
  });

  testWidgets('switching level swaps the deck and resets the position', (
    tester,
  ) async {
    final n5 = (await container.read(wordsProvider.future)).length;
    await pumpApp(tester);
    expect(find.text('OF $n5'), findsOneWidget);

    // Jump into the deck first, so the reset is observable.
    container.read(currentWordIndexProvider.notifier).jumpTo(200, n5);
    await tester.tap(find.text('N1'));
    await tester.pumpAndSettle();

    final n1 = (await container.read(wordsProvider.future)).length;
    expect(find.text('OF $n1'), findsOneWidget);
    expect(n1, greaterThan(n5));
    expect(container.read(currentWordIndexProvider), 0);
    expect(container.read(levelProvider), 1);
  });

  testWidgets('Next is disabled at the last word', (tester) async {
    final words = await container.read(wordsProvider.future);
    container
        .read(currentWordIndexProvider.notifier)
        .jumpTo(words.length - 1, words.length);

    await pumpWordScreen(tester);

    expect(find.text('${words.length} / ${words.length}'), findsOneWidget);
    expect(_iconButtonFor(tester, Icons.arrow_forward_ios).onPressed, isNull);
  });
}
