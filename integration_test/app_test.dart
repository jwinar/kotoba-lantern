import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kotoba_lantern/main.dart';

/// Runs the real app on a real device/simulator - not a mocked widget tree.
/// A clean `flutter build ios` says the code compiles; this says it actually
/// launches, loads the deck off the bundle and responds to taps.
///
/// Waits here are never `pumpAndSettle`: the study card's breathing echo
/// animates forever by design, so "wait until no animation is running" never
/// returns on that screen. They're also never a fixed `pump(Duration)` long
/// enough to "probably" be safe - a debug-mode first frame on a cold
/// simulator can take seconds, and picking a number is how you get a test
/// that passes on your machine and fails in CI. [pumpUntilFound] polls
/// instead: frames until the thing appears, or a real failure with the
/// finder named.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out after $timeout waiting for: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches, opens the study card, pages through the deck',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KotobaLanternApp()));

    // The deck loads off the bundle before the lantern knows its total.
    await pumpUntilFound(tester, find.text('OF 719'));
    expect(find.text('Kotoba Lantern'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);

    // The lantern is the way into the deck.
    await tester.tap(find.text('OF 719'));
    await pumpUntilFound(tester, find.text('1 / 719'));

    expect(find.text('ああ'), findsWidgets);
    expect(find.text('AA'), findsOneWidget);

    await tester.tap(find.byTooltip('Next'));
    await pumpUntilFound(tester, find.text('2 / 719'));

    // Marking a word learned is the one write that has to survive a real
    // platform channel - SharedPreferences on the device, not a mock.
    await tester.tap(find.byTooltip('Mark as learned'));
    await pumpUntilFound(tester, find.byTooltip('Marked as learned'));

    // Back to the dashboard: the two words just opened are now history, so
    // the lantern counts 2 and both show up under Recently viewed.
    await tester.tap(find.byTooltip('Back'));
    await pumpUntilFound(tester, find.text('OF 719'));
    await pumpUntilFound(tester, find.text('ああ'));
    expect(find.text('2'), findsOneWidget);
  });
}
