enum CommandRisk { safe, medium, advanced }

class CommandEntry {
  const CommandEntry({
    required this.category,
    required this.command,
    required this.name,
    required this.descriptionEn,
    required this.descriptionSw,
    required this.exampleOutput,
    required this.risk,
    required this.useCaseSw,
  });

  final String category;
  final String command;
  final String name;
  final String descriptionEn;
  final String descriptionSw;
  final String exampleOutput;
  final CommandRisk risk;
  final String useCaseSw;

  String get cmd => command;
  String get descEn => descriptionEn;
  String get descSw => descriptionSw;
}

class _CommandGroup {
  const _CommandGroup({
    required this.category,
    required this.example,
    required this.useCaseSw,
    required this.entries,
  });

  final String category;
  final String example;
  final String useCaseSw;
  final List<(String, String, CommandRisk)> entries;
}

const commandCategories = <String>[
  'System Info & WMIC',
  'Drivers',
  'Network',
  'Disk',
  'Process',
  'User & Security',
  'Files',
  'Repair',
  'Power',
  'Advanced',
  'Activation',
  'Software',
  'ASCII Animations',
];

final _commandGroups = <_CommandGroup>[
  _CommandGroup(
    category: 'System Info & WMIC',
    example: 'Name: Intel(R) Core(TM) Processor\nNumberOfCores: 8',
    useCaseSw:
        'Tumia taarifa hizi kutambua maunzi na toleo la Windows wakati wa uchunguzi.',
    entries: const [
      ('wmic cpu get name', 'Show processor model', CommandRisk.safe),
      (
        'wmic bios get serialnumber',
        'Show BIOS serial number',
        CommandRisk.safe
      ),
      (
        'wmic computersystem get manufacturer,model',
        'Show computer make and model',
        CommandRisk.safe
      ),
      (
        'wmic computersystem get totalphysicalmemory',
        'Show installed memory in bytes',
        CommandRisk.safe
      ),
      (
        'wmic os get caption,version,buildnumber',
        'Show Windows edition and build',
        CommandRisk.safe
      ),
      (
        'wmic diskdrive get model,size,status',
        'Show disk model, size, and status',
        CommandRisk.safe
      ),
      ('systeminfo', 'Display detailed system information', CommandRisk.safe),
      ('hostname', 'Display the computer hostname', CommandRisk.safe),
      ('ver', 'Display the Windows version', CommandRisk.safe),
      ('whoami', 'Display the current account name', CommandRisk.safe),
      (
        'wmic logicaldisk get caption,freespace,size',
        'Show drive capacity and free space',
        CommandRisk.safe
      ),
      (
        'wmic product get name,version',
        'List registered installed products',
        CommandRisk.safe
      ),
      (
        'wmic memorychip get capacity',
        'Show installed memory module capacities',
        CommandRisk.safe
      ),
      (
        'wmic cpu get numberofcores,numberoflogicalprocessors',
        'Show processor core and thread counts',
        CommandRisk.safe
      ),
      (
        'wmic computersystem get username',
        'Show the currently signed-in user',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Drivers',
    example:
        'Module Name     Display Name                 Driver Type\nnetwtw10.sys    Intel(R) Wi-Fi Driver          Kernel',
    useCaseSw:
        'Kagua viendeshi vilivyopo kabla ya kusasisha au kutatua tatizo la kifaa.',
    entries: const [
      ('driverquery', 'List installed drivers', CommandRisk.safe),
      ('driverquery /v', 'Show detailed driver information', CommandRisk.safe),
      (
        'driverquery /fo table',
        'Format driver list as a table',
        CommandRisk.safe
      ),
      (
        'driverquery /fo csv',
        'Export driver list as CSV text',
        CommandRisk.safe
      ),
      (
        'pnputil /enum-drivers',
        'List driver packages in the driver store',
        CommandRisk.safe
      ),
      (
        'pnputil /enum-devices /connected',
        'List connected Plug and Play devices',
        CommandRisk.safe
      ),
      ('sc query type= driver', 'Show driver service states', CommandRisk.safe),
      ('sc query state= all', 'Show all service states', CommandRisk.safe),
      ('dxdiag', 'Open DirectX diagnostic information', CommandRisk.safe),
      ('msinfo32', 'Open System Information', CommandRisk.safe),
      ('devmgmt.msc', 'Open Device Manager', CommandRisk.safe),
      (
        'pnputil /?',
        'Show PnPUtil help and supported options',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Network',
    example: 'IPv4 Address: 192.168.1.25\nDefault Gateway: 192.168.1.1',
    useCaseSw:
        'Tumia amri hizi kuchunguza muunganisho, DNS, na usanidi wa mtandao.',
    entries: const [
      ('ipconfig', 'Show network adapter addresses', CommandRisk.safe),
      (
        'ipconfig /all',
        'Show detailed adapter configuration',
        CommandRisk.safe
      ),
      (
        'ipconfig /flushdns',
        'Clear the local DNS resolver cache',
        CommandRisk.medium
      ),
      ('ipconfig /displaydns', 'Display cached DNS records', CommandRisk.safe),
      (
        'ipconfig /release',
        'Release the current DHCP address',
        CommandRisk.medium
      ),
      ('ipconfig /renew', 'Request a new DHCP address', CommandRisk.medium),
      (
        'ping 8.8.8.8',
        'Test connectivity to a public IP address',
        CommandRisk.safe
      ),
      (
        'tracert 8.8.8.8',
        'Trace the route to a public IP address',
        CommandRisk.safe
      ),
      ('nslookup example.com', 'Query DNS for a hostname', CommandRisk.safe),
      (
        'netstat -ano',
        'Show network connections and process IDs',
        CommandRisk.safe
      ),
      (
        'netsh wlan show profiles',
        'List saved Wi-Fi profile names',
        CommandRisk.safe
      ),
      (
        'netsh winsock reset',
        'Reset the Winsock catalog',
        CommandRisk.advanced
      ),
      ('ping google.com', 'Test connectivity to a hostname', CommandRisk.safe),
      (
        'ping google.com -t',
        'Continuously test connectivity to google.com',
        CommandRisk.safe
      ),
      (
        'netsh interface ipv4 show interfaces',
        'List IPv4 network interfaces',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Disk',
    example: 'Drive C: NTFS\nTotal: 476 GB    Free: 128 GB',
    useCaseSw:
        'Kagua nafasi na afya ya hifadhi. Hifadhi nakala kabla ya ukaguzi wa kurekebisha diski.',
    entries: const [
      (
        'wmic diskdrive get status',
        'Check the reported disk health status',
        CommandRisk.safe
      ),
      (
        'wmic logicaldisk get caption,freespace,size',
        'Show free space for each drive',
        CommandRisk.safe
      ),
      ('chkdsk C:', 'Check drive C for file-system errors', CommandRisk.safe),
      (
        'chkdsk C: /f',
        'Schedule file-system error repair on drive C',
        CommandRisk.advanced
      ),
      (
        'chkdsk C: /f /r',
        'Repair errors and scan for bad sectors',
        CommandRisk.advanced
      ),
      ('defrag C: /A', 'Analyze drive optimization status', CommandRisk.safe),
      ('defrag C: /O', 'Optimize the selected drive', CommandRisk.medium),
      (
        'fsutil volume diskfree C:',
        'Show free and total drive space',
        CommandRisk.safe
      ),
      ('mountvol', 'List volume mount points', CommandRisk.safe),
      (
        'diskpart /?',
        'Show DiskPart help without changing disks',
        CommandRisk.safe
      ),
      (
        'manage-bde -status',
        'Show BitLocker drive protection status',
        CommandRisk.safe
      ),
      ('format /?', 'Show format command help only', CommandRisk.safe),
    ],
  ),
  _CommandGroup(
    category: 'Process',
    example: 'Image Name      PID     Session\nexplorer.exe    4120    Console',
    useCaseSw:
        'Tambua programu zinazotumia rasilimali kabla ya kuzifunga au kurekebisha.',
    entries: const [
      ('tasklist', 'List running processes', CommandRisk.safe),
      ('tasklist /v', 'Show detailed process information', CommandRisk.safe),
      (
        'tasklist /svc',
        'Show services hosted by each process',
        CommandRisk.safe
      ),
      ('tasklist /fo csv', 'Format process list as CSV text', CommandRisk.safe),
      ('taskmgr', 'Open Task Manager', CommandRisk.safe),
      ('resmon', 'Open Resource Monitor', CommandRisk.safe),
      ('perfmon', 'Open Performance Monitor', CommandRisk.safe),
      (
        'wmic process get name,processid',
        'List process names and IDs',
        CommandRisk.safe
      ),
      (
        'wmic cpu get loadpercentage',
        'Show reported CPU load percentage',
        CommandRisk.safe
      ),
      (
        'wmic os get freephysicalmemory,totalvisiblememorysize',
        'Show memory totals in KB',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'User & Security',
    example:
        'User accounts for \\\\WORKSTATION\nAdministrator    DefaultAccount    Technician',
    useCaseSw:
        'Kagua akaunti, sera, na hali ya usalama bila kuonyesha nywila au taarifa za siri.',
    entries: const [
      (
        'whoami /all',
        'Show current account groups and privileges',
        CommandRisk.safe
      ),
      (
        'whoami /user',
        'Show the current account security identifier',
        CommandRisk.safe
      ),
      ('net user', 'List local user account names', CommandRisk.safe),
      ('net localgroup', 'List local group names', CommandRisk.safe),
      (
        'net localgroup Administrators',
        'List local administrator members',
        CommandRisk.safe
      ),
      ('gpresult /r', 'Show applied Group Policy summary', CommandRisk.safe),
      (
        'gpresult /scope computer /r',
        'Show computer policy summary',
        CommandRisk.safe
      ),
      ('secpol.msc', 'Open Local Security Policy', CommandRisk.safe),
      ('eventvwr.msc', 'Open Event Viewer', CommandRisk.safe),
      (
        'Get-MpComputerStatus',
        'Show Microsoft Defender status in PowerShell',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Files',
    example:
        ' Directory of C:\\Support\n<DIR>          Logs\n               1,024 notes.txt',
    useCaseSw:
        'Tumia amri hizi kuorodhesha, kutafuta, na kukagua faili bila kuzifuta.',
    entries: const [
      ('dir', 'List files in the current folder', CommandRisk.safe),
      ('dir /a', 'List files including hidden entries', CommandRisk.safe),
      (
        'dir /s',
        'List files in the current folder and subfolders',
        CommandRisk.safe
      ),
      ('tree', 'Show the folder tree', CommandRisk.safe),
      ('cd', 'Show the current folder path', CommandRisk.safe),
      (
        'where notepad.exe',
        'Find an executable on the search path',
        CommandRisk.safe
      ),
      (
        'where /r C:\\Windows notepad.exe',
        'Search a folder tree for a file',
        CommandRisk.safe
      ),
      (
        'attrib',
        'Show file attributes in the current folder',
        CommandRisk.safe
      ),
      ('fc file1.txt file2.txt', 'Compare two text files', CommandRisk.safe),
      (
        'findstr /s /i "error" *.log',
        'Search log files for matching text',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Repair',
    example:
        'Windows Resource Protection did not find any integrity violations.',
    useCaseSw:
        'Anza na ukaguzi salama. Amri za kurekebisha zinaweza kuchukua muda na zinahitaji ruhusa za msimamizi.',
    entries: const [
      (
        'sfc /scannow',
        'Scan and repair protected Windows system files',
        CommandRisk.advanced
      ),
      (
        'DISM /Online /Cleanup-Image /CheckHealth',
        'Check whether the Windows image is flagged as damaged',
        CommandRisk.safe
      ),
      (
        'DISM /Online /Cleanup-Image /ScanHealth',
        'Scan the Windows image for component-store corruption',
        CommandRisk.medium
      ),
      (
        'DISM /Online /Cleanup-Image /RestoreHealth',
        'Repair the Windows component store',
        CommandRisk.advanced
      ),
      (
        'DISM /Online /Cleanup-Image /StartComponentCleanup',
        'Clean up superseded Windows components',
        CommandRisk.advanced
      ),
      (
        'chkdsk C: /scan',
        'Scan drive C online for file-system issues',
        CommandRisk.medium
      ),
      (
        'msdt.exe /?',
        'Show help for the legacy diagnostics launcher',
        CommandRisk.safe
      ),
      (
        'DISM /Online /Get-CurrentEdition',
        'Show the current Windows edition',
        CommandRisk.safe
      ),
      (
        'DISM /Online /Get-TargetEditions',
        'Show Windows edition upgrade targets',
        CommandRisk.safe
      ),
      (
        'sfc /verifyonly',
        'Verify system files without repairing them',
        CommandRisk.safe
      ),
      (
        'DISM /Online /Cleanup-Image /AnalyzeComponentStore',
        'Analyze component store cleanup recommendations',
        CommandRisk.safe
      ),
      (
        'chkdsk /scan',
        'Scan the system drive online for file-system issues',
        CommandRisk.medium
      ),
      (
        r'sfc /scanfile=C:\Windows\System32\ntdll.dll',
        'Scan and repair one protected system file',
        CommandRisk.advanced
      ),
      (
        r'sfc /verifyfile=C:\Windows\System32\ntdll.dll',
        'Verify one protected system file without repair',
        CommandRisk.safe
      ),
      (
        'DISM /Online /Cleanup-Image /Get-OSUninstallWindow',
        'Show the Windows rollback availability period',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Power',
    example:
        'Battery report saved to file path C:\\Users\\Technician\\battery-report.html',
    useCaseSw:
        'Kagua matumizi ya nishati na betri kabla ya kubadilisha mipangilio ya power.',
    entries: const [
      (
        'powercfg /batteryreport',
        'Generate a battery usage report',
        CommandRisk.safe
      ),
      (
        'powercfg /energy',
        'Analyze energy efficiency and create a report',
        CommandRisk.safe
      ),
      ('powercfg /a', 'Show available sleep states', CommandRisk.safe),
      (
        'powercfg /getactivescheme',
        'Show the active power plan',
        CommandRisk.safe
      ),
      ('powercfg /list', 'List power plans', CommandRisk.safe),
      (
        'powercfg /requests',
        'Show applications preventing sleep',
        CommandRisk.safe
      ),
      (
        'powercfg /lastwake',
        'Show the source of the last wake event',
        CommandRisk.safe
      ),
      ('powercfg /waketimers', 'List active wake timers', CommandRisk.safe),
      (
        'powercfg /devicequery wake_armed',
        'List devices allowed to wake the PC',
        CommandRisk.safe
      ),
      (
        'shutdown /a',
        'Abort a pending shutdown when possible',
        CommandRisk.medium
      ),
    ],
  ),
  _CommandGroup(
    category: 'Advanced',
    example: 'InterfaceAlias: Ethernet\nIPv4Address: 192.168.1.25',
    useCaseSw:
        'Amri za uchunguzi wa kina. Kagua matokeo na athari zake kabla ya kutumia chaguo za mabadiliko.',
    entries: const [
      (
        'netsh int ip reset',
        'Reset TCP/IP configuration',
        CommandRisk.advanced
      ),
      (
        'netsh advfirewall show allprofiles',
        'Show Windows Firewall profile status',
        CommandRisk.safe
      ),
      (
        'netsh interface show interface',
        'List network interfaces and states',
        CommandRisk.safe
      ),
      (
        'netsh wlan show interfaces',
        'Show current wireless interface details',
        CommandRisk.safe
      ),
      ('route print', 'Show the local IP routing table', CommandRisk.safe),
      ('arp -a', 'Show the local ARP neighbor cache', CommandRisk.safe),
      (
        'Get-NetAdapter',
        'List network adapters in PowerShell',
        CommandRisk.safe
      ),
      (
        'Get-NetIPConfiguration',
        'Show IP configuration in PowerShell',
        CommandRisk.safe
      ),
      (
        'Get-Service | Sort-Object Status,DisplayName',
        'List Windows services in PowerShell',
        CommandRisk.safe
      ),
      (
        'auditpol /get /category:*',
        'Show the current audit policy',
        CommandRisk.safe
      ),
      (
        'wevtutil qe System /c:10 /rd:true /f:text',
        'Read the latest 10 System event log entries',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'Activation',
    example: 'Windows is in notification mode or is permanently activated.',
    useCaseSw:
        'Kagua au jaribu kuwezesha Windows kwa leseni halali iliyopo. Usitumie zana zisizo rasmi za activation.',
    entries: const [
      (
        'slmgr.vbs /xpr',
        'Check Windows activation expiration status',
        CommandRisk.safe
      ),
      (
        'slmgr.vbs /ato',
        'Request Windows activation using an existing valid license',
        CommandRisk.medium
      ),
    ],
  ),
  _CommandGroup(
    category: 'Software',
    example: 'Name: 7-Zip\nId: 7zip.7zip\nSource: winget',
    useCaseSw:
        'Tumia WinGet kupata programu kutoka chanzo kinachoaminika; hakiki jina la mchapishaji na kitambulisho cha kifurushi kabla ya kusakinisha.',
    entries: const [
      (
        'winget search 7zip',
        'Search WinGet for 7-Zip packages',
        CommandRisk.safe
      ),
      (
        'winget show --id 7zip.7zip --exact',
        'Review the exact 7-Zip package details before installation',
        CommandRisk.safe
      ),
      (
        'winget install --id 7zip.7zip --exact --source winget',
        'Install 7-Zip from the WinGet source',
        CommandRisk.medium
      ),
      (
        'winget list --name 7-Zip',
        'Check whether 7-Zip is installed',
        CommandRisk.safe
      ),
    ],
  ),
  _CommandGroup(
    category: 'ASCII Animations',
    example: 'Animated ASCII frames stream in Command Prompt for 30 seconds.',
    useCaseSw:
        'Tazama uhuishaji wa ASCII unaotiririshwa kutoka ascii.live. Muunganisho unakoma wenyewe baada ya sekunde 30.',
    entries: const [
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/parrot',
        'Show the live ASCII parrot animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/earth',
        'Show the live ASCII Earth animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/donut',
        'Show the live ASCII donut animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/nyan',
        'Show the live ASCII Nyan Cat animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/forrest',
        'Show the live ASCII forest animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/clock',
        'Show the live ASCII clock animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/batman',
        'Show the live ASCII Batman animation',
        CommandRisk.safe
      ),
      (
        'curl.exe --no-buffer --max-time 30 https://ascii.live/can-you-hear-me',
        'Show the live ASCII signal animation',
        CommandRisk.safe
      ),
    ],
  ),
];

final commandsData = <CommandEntry>[
  for (final group in _commandGroups)
    for (final entry in group.entries)
      CommandEntry(
        category: group.category,
        command: entry.$1,
        name: entry.$2,
        descriptionEn:
            '${entry.$2}. Review the output and check the target before taking action.',
        descriptionSw:
            '${_swahiliCommandDescription(group.category)} Kagua matokeo kabla ya kuchukua hatua.',
        exampleOutput: group.example,
        risk: entry.$3,
        useCaseSw: group.useCaseSw,
      ),
];

String _swahiliCommandDescription(String category) {
  return switch (category) {
    'System Info & WMIC' => 'Tumia amri hii kupata taarifa za mfumo.',
    'Drivers' => 'Tumia amri hii kukagua viendeshi vya vifaa.',
    'Network' => 'Tumia amri hii kuchunguza muunganisho wa mtandao.',
    'Disk' => 'Tumia amri hii kukagua hifadhi na mfumo wa faili.',
    'Process' => 'Tumia amri hii kukagua programu zinazoendeshwa.',
    'User & Security' =>
      'Tumia amri hii kukagua akaunti na usalama bila kuonyesha siri.',
    'Files' => 'Tumia amri hii kutafuta au kukagua faili.',
    'Repair' => 'Tumia amri hii kuchunguza au kurekebisha Windows.',
    'Power' => 'Tumia amri hii kukagua matumizi ya nishati.',
    'Activation' => 'Tumia amri hii kwa Windows yenye leseni halali pekee.',
    'Software' =>
      'Kagua mchapishaji na kifurushi cha programu kabla ya kusakinisha.',
    'ASCII Animations' =>
      'Tazama uhuishaji wa ASCII kwa kutumia muunganisho wa intaneti.',
    _ => 'Tumia amri hii kwa uchunguzi wa kina wa mfumo.',
  };
}
