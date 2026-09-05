import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifoflash_app/main.dart';
import 'package:tifoflash_app/core/services/sync_engine_service.dart';

void main() {
  testWidgets('TifoFlash App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TifoFlashApp());
    expect(find.text('TIFO FLASH'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    SyncEngineService().dispose();
  });
}
