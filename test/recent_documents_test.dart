import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ziongzou/features/boq/boq_generator_page.dart';
import 'package:ziongzou/features/proposal/proposal_generator_page.dart';

void main() {
  testWidgets('tapping a recent BOQ opens its saved file', (tester) async {
    SharedPreferences.setMockInitialValues({
      'boq_history': [
        jsonEncode({
          'title': 'Network upgrade',
          'subtitle': 'BOQ · Example Client',
          'path': r'C:\documents\BOQ-001.xlsx',
          'savedAt': '2026-11-16T10:00:00.000',
        }),
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    String? openedPath;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoqGeneratorPage(
            preferences: preferences,
            documentOpener: (path) async {
              openedPath = path;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Network upgrade'),
      find.byType(CustomScrollView),
      const Offset(0, -600),
    );
    await tester.tap(find.text('Network upgrade').last);
    await tester.pumpAndSettle();

    expect(openedPath, r'C:\documents\BOQ-001.xlsx');
  });

  testWidgets('tapping a recent proposal opens its saved file', (tester) async {
    SharedPreferences.setMockInitialValues({
      'proposal_history': [
        jsonEncode({
          'title': 'Office network · PROP-001',
          'subtitle': 'Proposal · Example Client',
          'path': r'C:\documents\PROP-001.docx',
          'savedAt': '2026-11-16T10:00:00.000',
        }),
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    String? openedPath;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalGeneratorPage(
            preferences: preferences,
            documentOpener: (path) async {
              openedPath = path;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Office network · PROP-001'),
      find.byType(CustomScrollView),
      const Offset(0, -700),
    );
    await tester.tap(find.text('Office network · PROP-001'));
    await tester.pumpAndSettle();

    expect(openedPath, r'C:\documents\PROP-001.docx');
  });

  testWidgets('proposal sections can be renamed, hidden, and restored',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalGeneratorPage(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var attempt = 0;
        attempt < 5 &&
            tester
                    .getCenter(
                      find.byTooltip(
                          'Rename Proposed solution / Scope of work'),
                    )
                    .dy >
                tester.view.physicalSize.height / tester.view.devicePixelRatio;
        attempt++) {
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(
      find.byTooltip('Rename Proposed solution / Scope of work'),
    );
    await tester.pumpAndSettle();

    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogField, 'Recommended approach');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide Recommended approach'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Hide Recommended approach'));
    await tester.tap(find.byTooltip('Hide Recommended approach'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Rename Recommended approach'), findsNothing);

    for (var attempt = 0;
        attempt < 6 && find.text('Hidden proposal sections').evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Hidden proposal sections'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore Recommended approach'));
    await tester.pumpAndSettle();
    for (var attempt = 0;
        attempt < 6 &&
            find.byTooltip('Rename Recommended approach').evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, 700),
      );
      await tester.pumpAndSettle();
    }
    expect(find.byTooltip('Rename Recommended approach'), findsOneWidget);
  });
}
