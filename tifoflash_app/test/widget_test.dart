import 'package:flutter_test/flutter_test.dart';
import 'package:tifoflash_app/main.dart';

void main() {
  testWidgets('TifoFlash App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TifoFlashApp());
    expect(find.text('TIFO FLASH'), findsOneWidget);
  });
}
