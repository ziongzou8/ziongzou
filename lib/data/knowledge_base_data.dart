const _knowledgeGroups = <String, List<(String, String, String)>>{
  'Windows': [
    (
      'Windows update stuck',
      'Windows Update remains pending or repeatedly fails.',
      'Check free space and update history; restart and retry from Settings.'
    ),
    (
      'Slow startup',
      'Sign-in or desktop takes unusually long to become responsive.',
      'Review Startup apps and Task Manager performance; disable only known nonessential apps.'
    ),
    (
      'Blue screen restart',
      'Windows unexpectedly restarts and shows a stop code.',
      'Record the stop code, check recent drivers and updates, then inspect Reliability Monitor.'
    ),
    (
      'Corrupt system files',
      'Windows features crash or report damaged protected files.',
      'Run DISM RestoreHealth followed by sfc /scannow from elevated Terminal.'
    ),
    (
      'Activation warning',
      'Windows reports that activation is incomplete.',
      'Confirm the installed edition matches the license, check Settings > System > Activation, run the Activation troubleshooter if available, and contact the licensed supplier or Microsoft Support. Avoid unofficial activation scripts.'
    ),
  ],
  'Hardware': [
    (
      'Laptop overheating',
      'The device becomes hot, noisy or slows under load.',
      'Check vents and fan noise, place on a hard surface, and inspect process load.'
    ),
    (
      'No display on boot',
      'Power appears on but the screen remains blank.',
      'Check power and brightness, disconnect peripherals, and test an external display.'
    ),
    (
      'Unexpected shutdown',
      'The computer powers off without a normal shutdown.',
      'Check heat, power adapter and event logs; back up data before hardware diagnostics.'
    ),
    (
      'Memory errors',
      'Applications fail unpredictably or Windows reports memory faults.',
      'Record symptoms and run the vendor memory diagnostic or Windows Memory Diagnostic.'
    ),
    (
      'Storage not detected',
      'A drive is missing from File Explorer or Disk Management.',
      'Check cables and firmware detection; do not initialize a drive containing needed data.'
    ),
  ],
  'Printer': [
    (
      'Printer offline',
      'A reachable printer appears offline on the workstation.',
      'Confirm power and network, clear only stale jobs, then check the selected printer port.'
    ),
    (
      'Print queue stuck',
      'A job remains queued and blocks later documents.',
      'Cancel the user’s stalled job, restart the spooler only with approval, and retry one page.'
    ),
    (
      'Poor print quality',
      'Output has streaks, faded colors or missing lines.',
      'Print a test page and use the printer’s maintenance cycle for the installed cartridge type.'
    ),
    (
      'Printer driver issue',
      'Printer functions are missing or output is misformatted.',
      'Confirm exact printer model and install a vendor-signed compatible driver.'
    ),
    (
      'Network printer unavailable',
      'Multiple users cannot connect to a shared printer.',
      'Check printer IP, server share, name resolution and whether other clients are affected.'
    ),
  ],
  'Network': [
    (
      'No internet access',
      'A device connects to a network but cannot reach public sites.',
      'Check gateway and DNS, compare another device, then test a known public IP and hostname.'
    ),
    (
      'Intermittent Wi-Fi',
      'Wireless connectivity drops or has high latency.',
      'Check signal and interference, test near the access point, and compare wired performance.'
    ),
    (
      'IP address conflict',
      'Windows reports a duplicate address or intermittent access.',
      'Identify the conflicting device and DHCP reservations before changing network settings.'
    ),
    (
      'DNS resolution failure',
      'Hosts cannot be reached by name although IP connectivity works.',
      'Check configured DNS servers and test with nslookup; preserve organization DNS settings.'
    ),
    (
      'Slow network',
      'Throughput or response time is below expected levels.',
      'Test one wired client, note time and destination, and compare local gateway versus internet.'
    ),
  ],
  'AD': [
    (
      'Domain sign-in failure',
      'A domain user cannot sign in to a workstation.',
      'Verify account status, domain connectivity, time synchronization and the exact error.'
    ),
    (
      'Group policy not applying',
      'Expected workstation policy is missing or outdated.',
      'Confirm OU and security filtering, then collect gpresult output for the affected user.'
    ),
    (
      'Account lockout',
      'An account repeatedly becomes locked.',
      'Check approved domain audit logs for source host and stop stale credentials before unlock.'
    ),
    (
      'Computer trust error',
      'Workstation reports a broken secure channel to the domain.',
      'Check DNS and time first; follow the organization’s approved secure-channel repair process.'
    ),
    (
      'Slow domain logon',
      'Domain profile or logon scripts take too long.',
      'Compare another user and workstation, then inspect policy, profile and DNS timings.'
    ),
  ],
  'WiFi': [
    (
      'Cannot join Wi-Fi',
      'The client rejects the wireless network or fails authentication.',
      'Verify SSID, security mode, password and user authorization; forget and rejoin only after approval.'
    ),
    (
      'Weak Wi-Fi signal',
      'Signal quality is low in one room or work area.',
      'Measure at the client location and check access-point placement, obstructions and channel use.'
    ),
    (
      'Wi-Fi connected without internet',
      'Client associates successfully but cannot browse externally.',
      'Check DHCP lease, gateway reachability, DNS and captive portal status.'
    ),
    (
      'Guest Wi-Fi access',
      'A visitor cannot obtain approved guest connectivity.',
      'Confirm guest portal flow and expiry; never place guests on the internal network.'
    ),
    (
      'Roaming interruptions',
      'Calls or sessions drop when moving between access points.',
      'Review coverage overlap, client roaming behavior and controller events with the network owner.'
    ),
  ],
  'Fiber': [
    (
      'ONT LOS alarm',
      'Optical terminal shows loss-of-signal or red LOS indicator.',
      'Check visible patch lead seating and bend radius; do not look into fiber ends. Escalate to carrier.'
    ),
    (
      'Fiber link unstable',
      'Optical service intermittently drops.',
      'Record alarm times and ONT indicators, inspect safe external cabling and request provider line tests.'
    ),
    (
      'Slow fiber service',
      'Measured WAN speed is below the subscribed plan.',
      'Test wired directly to the router, remove VPN/load, record several results and check negotiated link speed.'
    ),
    (
      'ONT has no power',
      'Optical network terminal is dark or repeatedly reboots.',
      'Check approved power adapter and outlet; avoid substituting an unverified adapter.'
    ),
    (
      'Fiber patch damage',
      'Cable is sharply bent, crushed or visibly damaged.',
      'Do not bend, splice or stare into the connector; isolate and contact a qualified fiber technician.'
    ),
  ],
  'CCTV': [
    (
      'Camera offline',
      'One camera is missing from the recorder or viewing client.',
      'Check PoE/link indicators, cabling and IP reachability; compare the switch port with a known camera.'
    ),
    (
      'No CCTV recording',
      'Live view works but playback has no recent footage.',
      'Check recorder storage state, recording schedule, system time and retention configuration.'
    ),
    (
      'Night image too dark',
      'Camera image loses detail after lighting changes.',
      'Inspect IR illumination, lens obstruction and scene lighting; avoid exposing sensors to bright light.'
    ),
    (
      'CCTV remote access failure',
      'Authorized user cannot reach the recorder remotely.',
      'Check approved VPN, WAN and recorder gateway; do not expose recorder ports publicly.'
    ),
    (
      'Camera time mismatch',
      'Camera timestamps differ from the recorder or actual time.',
      'Verify NTP source, timezone and daylight-saving configuration across the recorder and cameras.'
    ),
  ],
  'Software': [
    (
      'Plan a Windows software installation',
      'A user needs an approved desktop application installed on a Windows device.',
      'Confirm the exact application and version, device compatibility, business approval, disk space and license. Prefer Microsoft Store, WinGet, or the software publisher’s official website. Verify the publisher and installer signature, close relevant work, use standard-user permissions where possible, and verify the app opens and updates afterward.'
    ),
    (
      'Install software with WinGet',
      'An approved application is available from the Windows Package Manager source.',
      'Check that WinGet is available with winget --version. Search the app, inspect the exact package ID and publisher with winget show, then install only after confirming the source and prompts. For example, search and inspect 7-Zip before using winget install --id 7zip.7zip --exact --source winget.'
    ),
    (
      'Install from the Microsoft Store',
      'A user needs a Store-distributed application.',
      'Open Microsoft Store using the intended work or personal account, search for the exact app, verify its publisher and requirements, select Get or Install, and approve only expected prompts. Check the app launches and record its version.'
    ),
    (
      'Troubleshoot a failed software installation',
      'An installer exits with an error or the application does not appear after installation.',
      'Record the complete error and installer log, confirm Windows version and processor architecture, available disk space, prerequisites and user permissions. Retry only from the verified publisher or package source. Do not disable antivirus, run unknown scripts, or repeatedly launch an installer without understanding the error.'
    ),
    (
      'Update or remove Windows software',
      'An installed application needs an update or is no longer required.',
      'Check the application’s built-in updater, Microsoft Store, or WinGet package details. Confirm the exact app and version before updating. For removal, prefer Settings > Apps > Installed apps or the publisher’s uninstaller; confirm user data and dependencies are backed up before removal.'
    ),
  ],
};

final knowledgeBaseData = <Map<String, dynamic>>[
  for (final group in _knowledgeGroups.entries)
    for (final guide in group.value)
      {
        'title': guide.$1,
        'problem': guide.$2,
        'causes': <String>[
          'Configuration or connectivity issue',
          'Recent change, update, cabling fault or resource limitation',
          'Hardware or service fault requiring further isolation',
        ],
        'diagnosisSteps': <String>[
          'Confirm scope, user impact, device identity and exact error.',
          'Check power, physical connections, status indicators and recent changes.',
          guide.$3,
          'Record test results and compare with a known-good device or service.',
        ],
        'solution': guide.$3,
        'verification':
            'Repeat the original failing task, confirm normal status, and ask the user to verify service.',
        'precautions':
            'Get approval before disruptive changes. Protect client data and credentials. Stop and escalate if a safety, security or data-loss risk is found.',
        'category': group.key,
      },
];

const knowledgeCategories = <String>[
  'Windows',
  'Hardware',
  'Printer',
  'Network',
  'AD',
  'WiFi',
  'Fiber',
  'CCTV',
  'Software',
];
