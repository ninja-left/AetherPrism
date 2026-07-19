import 'package:aether_prism/ui/prism_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PrismApp builds', (tester) async {
    await tester.pumpWidget(const PrismApp());
    expect(find.byType(PrismApp), findsOneWidget);
  });
}
