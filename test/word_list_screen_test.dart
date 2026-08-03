import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_lantern/models/japanese_word.dart';
import 'package:kotoba_lantern/screens/word_list_screen.dart';
import 'package:kotoba_lantern/services/progress_providers.dart';
import 'package:kotoba_lantern/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _words = [
  JapaneseWord(
    japanese: '水',
    kana: 'みず',
    romaji: 'mizu',
    english: 'water',
    order: 1,
  ),
  JapaneseWord(
    japanese: '山',
    kana: 'やま',
    romaji: 'yama',
    english: 'mountain',
    order: 2,
  ),
  JapaneseWord(
    japanese: '食べる',
    kana: 'たべる',
    romaji: 'taberu',
    english: 'to eat',
    order: 3,
  ),
];

Future<void> _pumpList(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const WordListScreen(words: _words),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  testWidgets('shows the whole deck and its size', (tester) async {
    await _pumpList(tester, container);

    expect(find.text('3 words'), findsOneWidget);
    expect(find.text('水'), findsOneWidget);
    expect(find.text('食べる'), findsOneWidget);
  });

  testWidgets('search matches kanji, kana, romaji and the English gloss', (
    tester,
  ) async {
    await _pumpList(tester, container);
    final field = find.byType(TextField);

    for (final (query, expected) in [
      ('みず', '水'),
      ('yama', '山'),
      ('eat', '食べる'),
      ('水', '水'),
    ]) {
      await tester.enterText(field, query);
      await tester.pumpAndSettle();
      // Scoped to the row rather than find.text: the search field is itself
      // a Text once it has content, so searching "水" would otherwise match
      // the query the user just typed as well as the result.
      expect(
        find.widgetWithText(ListTile, expected),
        findsOneWidget,
        reason: 'searching "\$query"',
      );
      expect(find.text('1 of 3 words'), findsOneWidget);
    }
  });

  testWidgets('a search with no matches says so', (tester) async {
    await _pumpList(tester, container);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.textContaining('No words match'), findsOneWidget);
  });

  testWidgets('filters split the deck by learned and favorite', (tester) async {
    await _pumpList(tester, container);
    final progress = container.read(wordProgressProvider.notifier);
    await progress.setLearned(_words[0], true);
    await progress.setFavorite(_words[1], true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Learned'));
    await tester.pumpAndSettle();
    expect(find.text('水'), findsOneWidget);
    expect(find.text('山'), findsNothing);

    await tester.tap(find.text('Not learned'));
    await tester.pumpAndSettle();
    expect(find.text('水'), findsNothing);
    expect(find.text('食べる'), findsOneWidget);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('山'), findsOneWidget);
    expect(find.text('食べる'), findsNothing);
  });

  testWidgets('an empty filter explains itself instead of showing nothing', (
    tester,
  ) async {
    await _pumpList(tester, container);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No favorites yet'), findsOneWidget);
  });
}
