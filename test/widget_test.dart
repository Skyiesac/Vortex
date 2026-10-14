import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arrival_bell/main.dart';
import 'package:arrival_bell/config/app_constants.dart';

void main() {
  testWidgets('vortex renders its Baroque foundation', (tester) async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(hiveBoxName)) {
      await Hive.openBox<dynamic>(hiveBoxName);
    }
    addTearDown(Hive.close);
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('⚜ vortex ⚜'), findsOneWidget);
    expect(find.text('No Alarms Set'), findsOneWidget);
    expect(
      find.text('Add your first destination to be alerted upon arrival'),
      findsOneWidget,
    );
    expect(find.text('✦ ─────── ⚜ ─────── ✦'), findsOneWidget);
  });
}
