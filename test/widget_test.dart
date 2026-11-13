import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ziongzou/data/commands_data.dart';
import 'package:ziongzou/data/shortcuts_data.dart';
import 'package:ziongzou/main.dart';

void main() {
  test('local catalogs meet the required sizes', () {
    expect(shortcutsData.length, greaterThanOrEqualTo(100));
    expect(commandsData.length, greaterThanOrEqualTo(120));
    expect(shortcutCategories, hasLength(7));
    expect(commandCategories, hasLength(10));

    final commands = commandsData.map((entry) => entry.command).toSet();
    expect(
      commands,
      containsAll([
        'wmic bios get serialnumber',
        'driverquery',
        'ipconfig /flushdns',
        'netsh wlan show profiles',
        'chkdsk C: /f /r',
        'sfc /scannow',
        'DISM /Online /Cleanup-Image /RestoreHealth',
        'tasklist',
        'netsh winsock reset',
        'powercfg /batteryreport',
      ]),
    );
  });

  testWidgets('dashboard displays the toolkit and company footer',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ZiongZouApp(
        preferences: preferences,
        systemInfoLoader: () async => const {
          'os': 'Windows Test',
          'cpu': 'Test CPU',
          'ram': '16 GB',
          'hostname': 'TEST-PC',
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ZIONGZOU - Technician Toolkit'), findsOneWidget);
    expect(find.textContaining('AHEAD AFRICA SOLUTION LTD |'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.wifi_tethering_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Diagnostic Output'), findsOneWidget);
  });
}
