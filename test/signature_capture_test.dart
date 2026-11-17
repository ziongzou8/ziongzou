import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ziongzou/features/report/report_generator_page.dart';

void main() {
  testWidgets('report offers a freehand signature pad that can be cleared',
      (tester) async {
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
    final signatureType = find.byKey(
      const ValueKey('signature-type-selector'),
    );
    await tester.ensureVisible(signatureType);
    await tester.pumpAndSettle();

    await tester.tap(signatureType);
    await tester.pumpAndSettle();
    expect(find.text('Fingerprint verification'), findsNothing);
    await tester.tap(find.text('Freehand drawing').last);
    await tester.pumpAndSettle();

    final signaturePad = find.byKey(const ValueKey('signature-pad'));
    await tester.ensureVisible(signaturePad);
    await tester.pumpAndSettle();
    final padDecoration =
        tester.widget<Container>(signaturePad).decoration! as BoxDecoration;
    expect(padDecoration.color, Colors.white);
    expect(padDecoration.border, isNotNull);
    await tester.drag(signaturePad, const Offset(140, 24));
    await tester.pumpAndSettle();
    final clearButton = find.byKey(const ValueKey('clear-signature-drawing'));
    expect(tester.widget<TextButton>(clearButton).onPressed, isNotNull);

    await tester.tap(find.text('Clear drawing'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(clearButton).onPressed, isNull);
  });
}
