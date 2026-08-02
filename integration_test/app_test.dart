import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kotoba_lantern/main.dart';

/// Runs the real app on a real device/simulator - not a mocked widget tree.
/// A clean `flutter build ios` says the code compiles; this says it actually
/// launches, loads the deck off the bundle and responds to taps.
///
/// Every wait here is `pump(Duration)`, never `pumpAndSettle`: the study
/// card's breathing echo animates forever by design, so "wait until no
/// animation is running" never returns on that screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches, opens the study card, pages through the deck',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KotobaLanternApp()));
    // Asset load + the ring's draw-in.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Kotoba Lantern'), findsOneWidget);
    expect(find.text('OF 150 STUDIED'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);

    // The ring is the way into the deck.
    await tester.tap(find.text('OF 150 STUDIED'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1 / 150'), findsOneWidget);
    expect(find.text('わたし'), findsOneWidget);
    expect(find.text('私は学生です。'), findsOneWidget);

    await tester.tap(find.byTooltip('Next'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('2 / 150'), findsOneWidget);

    // Marking a word learned is the one write that has to survive a real
    // platform channel - SharedPreferences on the device, not a mock.
    await tester.tap(find.byTooltip('Mark as learned'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byTooltip('Marked as learned'), findsOneWidget);

    // Back to the dashboard: the two words just opened are now history.
    await tester.tap(find.byTooltip('Back'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2', findRichText: false), findsWidgets);
    expect(find.text('わたし'), findsOneWidget);
  });
}
