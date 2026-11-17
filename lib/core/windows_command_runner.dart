import 'dart:io';

import 'package:flutter/material.dart';

import 'toolkit_utils.dart';

typedef WindowsCommandLauncher = Future<void> Function(String command);

Future<void> runWindowsCommand(
  BuildContext context, {
  required String title,
  required String command,
  required String riskLevel,
  bool requiresAdministrator = false,
  WindowsCommandLauncher? launcher,
}) async {
  if (riskLevel != 'Safe' && riskLevel != 'Medium') {
    showToolkitMessage(context, 'Advanced commands remain copy-only.');
    return;
  }
  if (!Platform.isWindows && launcher == null) {
    showToolkitMessage(context, 'Windows commands can only run on Windows.');
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Run $title?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            riskLevel == 'Medium'
                ? 'This command may change system settings.'
                : 'Review this command before running.',
          ),
          const SizedBox(height: 8),
          const Text(
            'It opens a Command Prompt using the toolkit’s current permissions. '
            'It will not request administrator access.',
          ),
          if (requiresAdministrator) ...[
            const SizedBox(height: 8),
            const Text(
              'This item requires administrator permissions. If it fails, '
              'close the toolkit and reopen it as an administrator.',
            ),
          ],
          const SizedBox(height: 12),
          SelectableText(command),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Run in Command Prompt'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await (launcher ?? _launchWindowsCommand)(command);
    if (context.mounted) {
      showToolkitMessage(context, 'Started $title in Command Prompt.');
    }
  } on ProcessException catch (error) {
    if (context.mounted) {
      showToolkitMessage(context, 'Could not start $title: ${error.message}');
    }
  }
}

Future<void> openWindowsTool(
  BuildContext context, {
  required String title,
  required String command,
}) async {
  if (!Platform.isWindows) {
    showToolkitMessage(context, 'Windows tools can only open on Windows.');
    return;
  }

  final executable = Platform.environment['ComSpec'] ?? 'cmd.exe';
  final arguments = ['/d', '/c', 'start', '', command];
  try {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      final details = result.stderr.toString().trim();
      throw ProcessException(
        executable,
        arguments,
        details.isEmpty ? '$title could not be opened.' : details,
        result.exitCode,
      );
    }
    if (context.mounted) showToolkitMessage(context, 'Opened $title.');
  } on ProcessException catch (error) {
    if (context.mounted) {
      showToolkitMessage(context, 'Could not open $title: ${error.message}');
    }
  }
}

Future<void> _launchWindowsCommand(String command) async {
  final normalizedCommand = command.trim().replaceAll(RegExp(r'\r?\n'), ' & ');
  if (normalizedCommand.isEmpty) {
    throw ArgumentError.value(command, 'command', 'Command cannot be empty.');
  }
  final executable = Platform.environment['ComSpec'] ?? 'cmd.exe';
  final arguments = [
    '/d',
    '/c',
    'start',
    '',
    'cmd.exe',
    '/d',
    '/k',
    normalizedCommand,
  ];
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    final details = result.stderr.toString().trim();
    throw ProcessException(
      executable,
      arguments,
      details.isEmpty ? 'Command Prompt could not be opened.' : details,
      result.exitCode,
    );
  }
}
