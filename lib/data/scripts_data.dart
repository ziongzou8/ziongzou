import 'commands_data.dart';

const _scriptCategories = <String>[
  'Diagnostics',
  'Network',
  'Storage',
  'Repair',
  'Power',
  'Maintenance',
];

final scriptsData = <Map<String, String>>[
  for (var index = 0; index < 60; index++)
    _makeScript(index, commandsData[index]),
];

Map<String, String> _makeScript(int index, CommandEntry command) {
  final risk = switch (command.risk) {
    CommandRisk.safe => 'Safe',
    CommandRisk.medium => 'Medium',
    CommandRisk.advanced => 'Advanced',
  };
  final category = switch (command.category) {
    'Network' => 'Network',
    'Disk' || 'Files' => 'Storage',
    'Repair' => 'Repair',
    'Power' => 'Power',
    'Drivers' || 'Process' => 'Maintenance',
    _ => 'Diagnostics',
  };
  final admin = command.risk == CommandRisk.advanced ||
      command.risk == CommandRisk.medium;
  return {
    'name': '${command.name} ${index + 1}',
    'description': command.descriptionEn,
    'purpose': command.useCaseSw,
    'requiredPermissions': admin ? 'Admin' : 'User',
    'executionInstructions':
        'Review the command first. Open ${admin ? 'an elevated' : 'a'} Command Prompt or PowerShell, paste the command, and press Enter. Do not close the window until it finishes.',
    'expectedOutput': command.exampleOutput,
    'riskLevel': risk,
    'scriptContent': command.command,
    'category': category,
  };
}

const scriptCategories = _scriptCategories;
