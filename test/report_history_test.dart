import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ziongzou/features/report/report_generator_page.dart';

Map<String, String> _reportRecord(String filePath) => {
      'reference': 'REPORT-001',
      'client': 'Test Client',
      'site': 'Test Site',
      'date': '2026-11-13',
      'status': 'Completed',
      'path': filePath,
      'savedAt': '2026-11-13T00:00:00.000',
    };

void main() {
  testWidgets('recent report history can be cleared without deleting PDFs',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'report_history': [jsonEncode(_reportRecord(r'C:\reports\sample.pdf'))],
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportGeneratorPage(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Recent Reports'),
      find.byType(CustomScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Saved PDF files will not be deleted.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();

    expect(preferences.getStringList('report_history'), isEmpty);
    expect(find.text('Saved reports appear here.'), findsOneWidget);
  });

  testWidgets('report content sections can be renamed, hidden and restored',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportGeneratorPage(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renameButton = find.byTooltip('Rename Problem reported');
    await tester.tap(renameButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Site findings');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide Site findings'), findsOneWidget);
    final hideButton = find.byTooltip('Hide Site findings');
    await tester.ensureVisible(hideButton);
    await tester.pumpAndSettle();
    await tester.tap(hideButton);
    await tester.pumpAndSettle();

    expect(find.text('Hidden report sections'), findsOneWidget);
    final restoreButton = find.byTooltip('Restore Site findings');
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide Site findings'), findsOneWidget);
  });

  testWidgets('tapping a recent report opens its PDF preview', (tester) async {
    final directory = await Directory.systemTemp.createTemp('report-preview');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}\\sample.pdf');
    final document = pw.Document()
      ..addPage(
        pw.Page(
          build: (_) => pw.Center(child: pw.Text('Saved report')),
        ),
      );
    await file.writeAsBytes(await document.save());

    SharedPreferences.setMockInitialValues({
      'report_history': [jsonEncode(_reportRecord(file.path))],
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportGeneratorPage(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.textContaining('REPORT-001'),
      find.byType(CustomScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('REPORT-001'));
    await tester.pump();

    expect(find.byType(PdfPreview), findsOneWidget);
    expect(find.text('REPORT-001'), findsOneWidget);
  });
}
