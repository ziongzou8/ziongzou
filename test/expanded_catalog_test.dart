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
    expect(cmdData, hasLength(126));
    expect(scriptsData, hasLength(63));
    expect(knowledgeBaseData, hasLength(45));
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

  test('activation scripts include licensed commands and official guidance',
      () {
    final windows = scriptsData.singleWhere(
      (script) => script['name'] == 'Check and activate Windows',
    );
    expect(windows['scriptContent'], contains('slmgr.vbs /ato'));
    expect(windows['description'], contains('support.microsoft.com/windows/'));

    final office = scriptsData.singleWhere(
      (script) => script['name'] == 'Check and activate volume-licensed Office',
    );
    expect(office['scriptContent'], contains('/dstatus'));
    expect(office['scriptContent'], contains('/act'));
    expect(office['description'], contains('support.microsoft.com/office/'));
    expect(office['category'], 'Activation');
  });

  test('software installation guidance uses WinGet and verified sources', () {
    final installCommand = cmdData.singleWhere(
      (command) =>
          command['cmd'] ==
          'winget install --id 7zip.7zip --exact --source winget',
    );
    expect(installCommand['category'], 'Software');
    expect(installCommand['risk'], 'Medium');

    final script = scriptsData.singleWhere(
      (item) => item['name'] == 'Install 7-Zip with WinGet',
    );
    expect(script['scriptContent'], installCommand['cmd']);
    expect(script['executionInstructions'], contains('verify the package'));

    final guide = knowledgeBaseData.singleWhere(
      (item) => item['title'] == 'Install software with WinGet',
    );
    expect(guide['category'], 'Software');
    expect(guide['solution'], contains('winget show'));
    expect(guide['solution'], contains('winget install'));

    expect(
      cmdData.any((command) => command['cmd'] == 'slmgr.vbs /ato'),
      isTrue,
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
        attempt < 5 && find.text('Report attachments').evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Report attachments'), findsOneWidget);
    expect(find.text('Add files or images'), findsOneWidget);
  });

  testWidgets('proposal and BOQ are separate Tools options', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(ZiongZouApp(preferences: preferences));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tools').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Proposal'));
    await tester.tap(find.text('Proposal'));
    await tester.pumpAndSettle();
    expect(find.text('Proposal Generator'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Generate & Save Word Proposal'),
      find.byType(CustomScrollView).last,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('Generate & Save Word Proposal'), findsOneWidget);

    await tester.ensureVisible(find.text('BOQ'));
    await tester.tap(find.text('BOQ'));
    await tester.pumpAndSettle();
    expect(find.text('BOQ Generator'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Generate & Save Excel BOQ'),
      find.byType(CustomScrollView).last,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('Generate & Save Excel BOQ'), findsOneWidget);
  });
}
