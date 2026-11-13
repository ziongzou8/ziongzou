import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ziongzou/data/cmd_data.dart';
import 'package:ziongzou/data/knowledge_base_data.dart';
import 'package:ziongzou/data/mobile_tricks_data.dart';
import 'package:ziongzou/data/scripts_data.dart';
import 'package:ziongzou/data/shortcuts_data.dart';
import 'package:ziongzou/main.dart';

void main() {
  test('AHEAD AFRICA logo is bundled as a PNG asset', () async {
    final data = await rootBundle.load('assets/ahead_africa_logo.png');
    expect(data.lengthInBytes, greaterThan(8));
    expect(
      data.buffer.asUint8List().take(8),
      equals([137, 80, 78, 71, 13, 10, 26, 10]),
    );
  });

  test('offline catalogs have the requested content counts', () {
    expect(shortcutsData, hasLength(100));
    expect(mobileTricksData, hasLength(80));
    expect(cmdData, hasLength(120));
    expect(scriptsData, hasLength(60));
    expect(knowledgeBaseData, hasLength(40));
    expect(
      shortcutsData.map((item) => item['category']).toSet(),
      containsAll(shortcutCategories),
    );
    expect(
      cmdData.map((item) => item['category']).toSet(),
      containsAll(cmdCategories),
    );
    expect(
      knowledgeBaseData.map((item) => item['category']).toSet(),
      containsAll(knowledgeCategories),
    );
  });

  testWidgets('mobile navigation opens the tools and report form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(ZiongZouApp(preferences: preferences));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Tools').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Service Report Generator'), findsOneWidget);
    expect(find.text('Problem reported'), findsOneWidget);
    for (var attempt = 0;
        attempt < 5 && find.text('Image evidence').evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Image evidence'), findsOneWidget);
    expect(find.text('Add images'), findsOneWidget);
  });
}
