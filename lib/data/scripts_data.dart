import 'commands_data.dart';

const _scriptCategories = <String>[
  'Diagnostics',
  'Network',
  'Storage',
  'Repair',
  'Power',
  'Maintenance',
  'Activation',
  'Software',
];

final scriptsData = <Map<String, String>>[
  for (var index = 0; index < 60; index++)
    _makeScript(index, commandsData[index]),
  {
    'name': 'Check and activate Windows',
    'description':
        'Checks the Windows license status and requests online activation using an existing valid digital license or product key. Official guidance: https://support.microsoft.com/windows/activate-windows-c39005d4-95ee-b91e-b399-2820fda32227',
    'purpose':
        'Use for Windows activation troubleshooting on a properly licensed device.',
    'requiredPermissions': 'Admin',
    'executionInstructions':
        'Open an elevated Command Prompt. Review the commands; /ato only attempts activation for an existing valid license. Follow the official support link if activation fails.',
    'expectedOutput':
        'Windows displays the license expiration/activation status and the result of the activation attempt.',
    'riskLevel': 'Medium',
    'scriptContent': 'slmgr.vbs /xpr\nslmgr.vbs /ato',
    'category': 'Activation',
  },
  {
    'name': 'Check and activate volume-licensed Office',
    'description':
        'Checks activation status and attempts activation for volume-licensed Office installations. For Microsoft 365 Apps or other editions, use the Office account activation flow. Official guidance: https://support.microsoft.com/office/activate-office-5bd38f38-db92-448b-a982-ad170b1e187e',
    'purpose':
        'Troubleshoot Office activation using the installed volume license and the organization’s configured activation service.',
    'requiredPermissions': 'Admin',
    'executionInstructions':
        'Open PowerShell as an administrator. This method is for volume-licensed Office only; it does not bypass licensing. Sign in or use the official Office support link for Microsoft 365 and other editions.',
    'expectedOutput':
        'Office license status and the result of its activation request are displayed. An existing valid Office license is required.',
    'riskLevel': 'Advanced',
    'scriptContent':
        r'''$roots = @($env:ProgramFiles, [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')) | Where-Object { $_ }
$ospp = $roots | ForEach-Object {
  Join-Path $_ 'Microsoft Office\root\Office16\OSPP.VBS'
  Join-Path $_ 'Microsoft Office\Office16\OSPP.VBS'
} | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ospp) { throw 'OSPP.VBS not found. This command is for volume-licensed Office; use the Office account activation flow for Microsoft 365.' }
cscript.exe //nologo $ospp /dstatus
cscript.exe //nologo $ospp /act''',
    'category': 'Activation',
  },
  {
    'name': 'Install 7-Zip with WinGet',
    'description':
        'Installs 7-Zip using the Windows Package Manager WinGet source. Review the package publisher and details before proceeding.',
    'purpose':
        'Demonstrate a package-manager installation using a specific package ID and source.',
    'requiredPermissions': 'User',
    'executionInstructions':
        'First run `winget show --id 7zip.7zip --exact` and verify the package and publisher. Then run this command in Command Prompt. Review any installer prompt and cancel if the details do not match. On managed devices, follow your organization’s software approval process.',
    'expectedOutput':
        'WinGet reports the installation result. Verify 7-Zip appears in the Start menu and opens successfully.',
    'riskLevel': 'Medium',
    'scriptContent': 'winget install --id 7zip.7zip --exact --source winget',
    'category': 'Software',
  },
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
    'Software' => 'Software',
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
