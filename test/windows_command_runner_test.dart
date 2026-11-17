import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziongzou/core/windows_command_runner.dart';

void main() {
  testWidgets('a command launches only after confirmation', (tester) async {
    String? launchedCommand;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runWindowsCommand(
                context,
                title: 'hostname',
                command: 'hostname',
                riskLevel: 'Safe',
                launcher: (command) async => launchedCommand = command,
              ),
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    expect(launchedCommand, isNull);

    await tester.tap(find.text('Run in Command Prompt'));
    await tester.pumpAndSettle();
    expect(launchedCommand, 'hostname');
  });

  testWidgets('Advanced commands remain copy-only', (tester) async {
    String? launchedCommand;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runWindowsCommand(
                context,
                title: 'advanced command',
                command: 'dangerous-command',
                riskLevel: 'Advanced',
                launcher: (command) async => launchedCommand = command,
              ),
              child: const Text('Try advanced command'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Try advanced command'));
    await tester.pumpAndSettle();

    expect(launchedCommand, isNull);
    expect(find.text('Advanced commands remain copy-only.'), findsOneWidget);
  });
}
