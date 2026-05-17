import 'package:atmos/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Atmos app loads splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AtmosApp()));
    await tester.pump();
    expect(find.text('Atmos'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
  });
}
