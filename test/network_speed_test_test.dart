import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziongzou/features/network/network_doctor_page.dart';

void main() {
  testWidgets('speed test runs in-app and displays the returned measurements',
      (tester) async {
    var started = false;
    const result = NetworkSpeedTestResult(
      latencyMilliseconds: 12.5,
      downloadMegabitsPerSecond: 120.0,
      uploadMegabitsPerSecond: 24.0,
      downloadBytes: 5000000,
      uploadBytes: 1000000,
      isp: 'Example ISP',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NetworkDoctorPage(
            active: false,
            speedTestRunner: () async {
              started = true;
              return result;
            },
          ),
        ),
      ),
    );

    final speedTestTitle = find.text('Speed test');
    await tester.dragUntilVisible(
      speedTestTitle,
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('speed-test-button')));
    await tester.pumpAndSettle();

    expect(started, isTrue);
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();
    final output = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(output.data, contains('Download: 120.0 Mbps'));
    expect(output.data, contains('Upload: 24.0 Mbps'));
    expect(output.data, contains('Internet ISP'));
    expect(output.data, contains('Example ISP'));
    expect(find.textContaining('fast.com'), findsNothing);
  });
}
