import 'commands_data.dart' as legacy;

const cmdCategories = <String>[
  'SystemInfo',
  'Network',
  'Disk',
  'Process',
  'User',
  'File',
  'Repair',
  'Power',
  'Advanced',
  'WMIC',
  'ASCII Animations',
];

final cmdData = <Map<String, String>>[
  for (final entry in legacy.commandsData)
    {
      'cmd': entry.command,
      'desc_sw': entry.descriptionSw,
      'desc_en': entry.descriptionEn,
      'category': _category(entry.category, entry.command),
      'risk': switch (entry.risk) {
        legacy.CommandRisk.safe => 'Safe',
        legacy.CommandRisk.medium => 'Medium',
        legacy.CommandRisk.advanced => 'Advanced',
      },
      'syntax': entry.command,
      'example_output': entry.exampleOutput,
      'use_case_sw': entry.useCaseSw,
    },
];

String _category(String source, String command) {
  if (command.toLowerCase().startsWith('wmic ')) return 'WMIC';
  return switch (source) {
    'System Info & WMIC' || 'Drivers' => 'SystemInfo',
    'User & Security' => 'User',
    'Files' => 'File',
    _ => source,
  };
}
