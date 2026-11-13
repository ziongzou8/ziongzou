final _mobileGroups = <String, List<(String, String, String, String, String)>>{
  'USSD': [
    (
      '*#06#',
      'Show device IMEI',
      'Onyesha IMEI ya kifaa',
      'Android/iOS phones',
      'IMEI is sensitive; share only with your carrier.'
    ),
    (
      '*#*#4636#*#*',
      'Android testing information',
      'Taarifa za majaribio ya Android',
      'Many Android devices',
      'Menu availability varies; do not change radio settings.'
    ),
    (
      '*#*#225#*#*',
      'Calendar storage information',
      'Taarifa za hifadhi ya kalenda',
      'Some Android builds',
      'May not be supported by the installed dialer.'
    ),
    (
      '*#*#426#*#*',
      'Google Play services diagnostics',
      'Utambuzi wa Google Play services',
      'Some Android builds',
      'Read-only diagnostics; avoid changing settings.'
    ),
    (
      '*#*#759#*#*',
      'Google partner setup information',
      'Taarifa za usanidi wa Google partner',
      'Some Android builds',
      'Availability depends on Google services version.'
    ),
    (
      '*#0*#',
      'Samsung hardware test menu',
      'Menyu ya majaribio ya maunzi ya Samsung',
      'Some Samsung devices',
      'Samsung-specific; do not select factory reset options.'
    ),
    (
      '*#1234#',
      'Samsung firmware version',
      'Toleo la firmware la Samsung',
      'Some Samsung devices',
      'Samsung-specific; displays model software details.'
    ),
    (
      '*#0228#',
      'Samsung battery status screen',
      'Hali ya betri ya Samsung',
      'Some Samsung devices',
      'Do not use battery reset/calibration options without guidance.'
    ),
    (
      '*#0011#',
      'Samsung service network screen',
      'Hali ya mtandao wa Samsung',
      'Some Samsung devices',
      'Service screen; do not change radio settings.'
    ),
    (
      '*#9900#',
      'Samsung system dump menu',
      'Menyu ya system dump ya Samsung',
      'Some Samsung devices',
      'Do not select delete-dump or logging changes without a reason.'
    ),
    (
      '*#0808#',
      'Samsung USB configuration menu',
      'Mipangilio ya USB ya Samsung',
      'Some Samsung devices',
      'Leave defaults unchanged unless following a repair procedure.'
    ),
    (
      '*#0283#',
      'Samsung audio loopback test',
      'Jaribio la sauti la Samsung',
      'Some Samsung devices',
      'Use only for a brief microphone/speaker test.'
    ),
    (
      '*#2663#',
      'Samsung touchscreen firmware info',
      'Taarifa za firmware ya skrini ya kugusa',
      'Some Samsung devices',
      'Do not update firmware from this menu unless instructed.'
    ),
    (
      '*#7353#',
      'Samsung quick hardware tests',
      'Majaribio ya haraka ya maunzi ya Samsung',
      'Some older Samsung devices',
      'Menu may be disabled on current models.'
    ),
    (
      'Carrier-provided balance code',
      'Check airtime balance',
      'Angalia salio kwa msimbo wa mtoa huduma',
      'Carrier-specific',
      'Use the current code published by your mobile operator.'
    ),
    (
      'Carrier-provided data code',
      'Check mobile data balance',
      'Angalia salio la data',
      'Carrier-specific',
      'USSD codes and charges vary by operator and plan.'
    ),
    (
      'Carrier-provided support code',
      'Open operator support menu',
      'Fungua menyu ya msaada wa mtandao',
      'Carrier-specific',
      'Verify the official code with your operator.'
    ),
    (
      'Carrier-provided top-up code',
      'Top up prepaid airtime',
      'Ongeza salio la simu',
      'Carrier-specific',
      'Never enter a voucher into an untrusted USSD prompt.'
    ),
    (
      'Carrier-provided SIM status code',
      'Check SIM account status',
      'Angalia hali ya akaunti ya SIM',
      'Carrier-specific',
      'Use official operator documentation only.'
    ),
    (
      'Carrier-provided voicemail code',
      'Check voicemail options',
      'Angalia chaguo za voicemail',
      'Carrier-specific',
      'Forwarding changes may affect call charges.'
    ),
  ],
  'Diagnostic': [
    (
      'Settings > About phone',
      'Review model, Android version and build',
      'Kagua modeli na toleo la Android',
      'Android',
      'Hide serial numbers and IMEI before sharing screenshots.'
    ),
    (
      'Settings > About phone > Status',
      'Review SIM and network status',
      'Kagua hali ya SIM na mtandao',
      'Android',
      'Do not publish phone numbers or identifiers.'
    ),
    (
      'Settings > Network & internet',
      'Review active network connection',
      'Kagua muunganisho wa mtandao',
      'Android',
      'Names vary by Android manufacturer.'
    ),
    (
      'Settings > Wi-Fi > network details',
      'Review Wi-Fi link properties',
      'Kagua maelezo ya Wi-Fi',
      'Android',
      'Avoid sharing private SSIDs publicly.'
    ),
    (
      'Settings > Apps > See all apps',
      'Inspect installed app permissions',
      'Kagua ruhusa za programu',
      'Android',
      'Revoke permissions only when you understand app impact.'
    ),
    (
      'Settings > Security & privacy',
      'Review security warnings and updates',
      'Kagua tahadhari za usalama',
      'Android',
      'Install updates from device settings only.'
    ),
    (
      'Settings > System > Software update',
      'Check available system updates',
      'Angalia masasisho ya mfumo',
      'Android',
      'Use a trusted Wi-Fi connection and adequate battery.'
    ),
    (
      'Settings > Storage',
      'Inspect used storage by category',
      'Kagua nafasi iliyotumika',
      'Android',
      'Review files before deleting.'
    ),
    (
      'Settings > Developer options > Running services',
      'Inspect active services',
      'Kagua huduma zinazoendelea',
      'Some Android devices',
      'Developer options may not be enabled; do not stop unknown services.'
    ),
    (
      'Settings > Battery > Battery usage',
      'Find apps using battery',
      'Tambua programu zinazotumia betri',
      'Android',
      'Usage estimates depend on recent activity.'
    ),
    (
      'Settings > Accessibility',
      'Check accessibility service status',
      'Kagua huduma za ufikivu',
      'Android',
      'Only enable trusted accessibility services.'
    ),
    (
      'Settings > Privacy dashboard',
      'Review recent permission access',
      'Kagua matumizi ya ruhusa',
      'Recent Android versions',
      'Menu availability depends on Android version.'
    ),
    (
      'Settings > SIMs / Mobile network',
      'Inspect SIM registration and preferred network',
      'Kagua SIM na aina ya mtandao',
      'Android',
      'Carrier options vary.'
    ),
    (
      'Settings > Sound & vibration',
      'Test notification and media volume',
      'Jaribu sauti ya arifa na media',
      'Android',
      'Check silent and Do Not Disturb modes first.'
    ),
    (
      'Settings > Display > Screen timeout',
      'Check display timeout behavior',
      'Kagua muda wa kuzima skrini',
      'Android',
      'Short timeouts can look like display faults.'
    ),
    (
      'Settings > System > Reset options',
      'Review available network reset options',
      'Kagua chaguo za kurejesha mtandao',
      'Android',
      'Reset may remove saved Wi-Fi and Bluetooth pairings.'
    ),
    (
      'Settings > Connected devices',
      'Review Bluetooth pairings',
      'Kagua vifaa vya Bluetooth',
      'Android',
      'Remove only devices you recognize.'
    ),
    (
      'Settings > Apps > Default apps',
      'Check default browser and phone apps',
      'Kagua programu chaguomsingi',
      'Android',
      'Changing defaults does not uninstall applications.'
    ),
    (
      'Settings > Security > Google Play system update',
      'Check Google system component update',
      'Angalia sasisho la Google Play system',
      'Supported Android versions',
      'Exact menu location varies by manufacturer.'
    ),
    (
      'Restart after saving work',
      'Clear transient faults with a normal restart',
      'Washa upya baada ya kuhifadhi kazi',
      'Android phones',
      'Save open work and avoid interrupting updates.'
    ),
  ],
  'Battery': [
    (
      'Settings > Battery > Battery usage',
      'Identify recent battery consumers',
      'Tambua matumizi ya betri',
      'Android',
      'Battery-use history may reset after a system update.'
    ),
    (
      'Settings > Battery > Battery Saver',
      'Enable the built-in power saving mode',
      'Washa Battery Saver',
      'Android',
      'Background sync and performance can be reduced.'
    ),
    (
      'Settings > Apps > app > Battery',
      'Review per-app background activity',
      'Kagua matumizi ya app nyuma',
      'Android',
      'Restricting essential messaging apps can delay alerts.'
    ),
    (
      'Settings > Display > Brightness',
      'Reduce screen brightness when appropriate',
      'Punguza mwangaza inapofaa',
      'Android',
      'Do not obscure safety alerts or visibility.'
    ),
    (
      'Settings > Display > Smooth display',
      'Review high refresh rate setting',
      'Kagua refresh rate ya skrini',
      'Some Android devices',
      'Lower refresh rate can reduce smoothness.'
    ),
    (
      'Settings > Location',
      'Disable unused location access',
      'Zima location isiyotumika',
      'Android',
      'Navigation and emergency features may need location.'
    ),
    (
      'Settings > Network > Hotspot',
      'Turn off hotspot when no longer needed',
      'Zima hotspot usipoitumia',
      'Android',
      'Connected devices will lose internet access.'
    ),
    (
      'Settings > Connected devices > Bluetooth',
      'Disable Bluetooth when not needed',
      'Zima Bluetooth usipoitumia',
      'Android',
      'Wearables and accessories may disconnect.'
    ),
    (
      'Settings > Network > Mobile data',
      'Review mobile data use by app',
      'Kagua matumizi ya data kwa app',
      'Android',
      'Do not disable data for critical services.'
    ),
    (
      'Settings > Battery > Adaptive Battery',
      'Review adaptive battery optimization',
      'Kagua Adaptive Battery',
      'Supported Android versions',
      'Some apps may receive notifications later.'
    ),
    (
      'Settings > Apps > unused app > Uninstall',
      'Remove apps you no longer need',
      'Ondoa programu zisizohitajika',
      'Android',
      'Back up app data before uninstalling.'
    ),
    (
      'Settings > Storage > Free up space',
      'Use Android storage recommendations',
      'Tumia mapendekezo ya nafasi',
      'Android',
      'Inspect selected items before confirming cleanup.'
    ),
    (
      'Settings > System > Software update',
      'Install vendor power-management updates',
      'Sasisha mfumo kutoka kwa mtengenezaji',
      'Android',
      'Use official updates and adequate charge.'
    ),
    (
      'Settings > Battery > Charging optimization',
      'Review charging protection options',
      'Kagua ulinzi wa kuchaji',
      'Some Android devices',
      'Feature names and availability vary.'
    ),
    (
      'Use a certified charger',
      'Check charger and cable compatibility',
      'Tumia chaja iliyoidhinishwa',
      'Android phones',
      'Stop using damaged, hot, or swollen-battery devices.'
    ),
    (
      'Keep device ventilated while charging',
      'Avoid heat-related battery stress',
      'Epuka joto wakati wa kuchaji',
      'Android phones',
      'Do not cover a charging device with bedding.'
    ),
    (
      'Settings > Sound & vibration > Haptics',
      'Review vibration and haptic feedback',
      'Kagua mtetemo wa haptic',
      'Android',
      'Turning off haptics changes user feedback.'
    ),
    (
      'Settings > Accounts > Sync',
      'Review unnecessary account sync tasks',
      'Kagua usawazishaji wa akaunti',
      'Android',
      'Keep security and work account sync enabled as needed.'
    ),
    (
      'Restart after app updates',
      'Refresh services after updates if battery drain starts',
      'Washa upya baada ya sasisho',
      'Android',
      'Check battery usage again before removing apps.'
    ),
    (
      'Settings > Battery > Battery health',
      'Review battery health where supported',
      'Kagua afya ya betri inapopatikana',
      'Some Android devices',
      'If swelling or overheating occurs, stop using the device.'
    ),
  ],
  'Hidden': [
    (
      'Settings > tap Build number 7 times',
      'Enable Developer options',
      'Washa Developer options',
      'Many Android devices',
      'Changes can affect security and stability; turn off when done.'
    ),
    (
      'Developer options > USB debugging',
      'Enable debugging for a trusted workstation',
      'Washa USB debugging kwa kompyuta salama',
      'Android',
      'Disable after use and never approve unknown computers.'
    ),
    (
      'Developer options > Stay awake',
      'Keep screen on while charging for testing',
      'Weka skrini wazi wakati wa majaribio',
      'Android',
      'Increases power use and may expose screen contents.'
    ),
    (
      'Developer options > Show taps',
      'Display touch feedback during demonstrations',
      'Onyesha miguso wakati wa mafunzo',
      'Android',
      'Disable after recording or demonstration.'
    ),
    (
      'Developer options > Pointer location',
      'Visualize touch coordinates',
      'Onyesha nafasi ya mguso',
      'Android',
      'Overlay can interfere with normal screen use.'
    ),
    (
      'Developer options > Smallest width',
      'Inspect display scaling value',
      'Kagua kiwango cha display',
      'Android',
      'Changing density can make controls unusable.'
    ),
    (
      'Developer options > Animation scales',
      'Adjust animation speed for testing',
      'Rekebisha kasi ya animation',
      'Android',
      'Restore defaults if the UI feels abnormal.'
    ),
    (
      'Settings > System > Multiple users',
      'Review guest and user profiles',
      'Kagua akaunti za watumiaji',
      'Some Android devices',
      'Switching users can expose separate user data.'
    ),
    (
      'Settings > Security > App pinning',
      'Pin an app for supervised kiosk use',
      'Funga app moja kwa matumizi ya kiosk',
      'Supported Android versions',
      'Learn the unpin gesture before enabling.'
    ),
    (
      'Settings > Accessibility > Magnification',
      'Enable screen magnification shortcut',
      'Washa njia ya kukuza skrini',
      'Android',
      'Shortcut behavior varies by device.'
    ),
    (
      'Settings > Notifications > Notification history',
      'Review recently dismissed alerts',
      'Kagua arifa zilizofutwa hivi karibuni',
      'Recent Android versions',
      'Enable history before the event to collect entries.'
    ),
    (
      'Settings > Privacy > Permission manager',
      'Review app access by permission type',
      'Kagua ruhusa kwa aina',
      'Android',
      'Revoking access may disable app features.'
    ),
    (
      'Settings > Security > Find My Device',
      'Review lost-device recovery settings',
      'Kagua mipangilio ya kutafuta kifaa',
      'Android with Google services',
      'Requires account setup and may share location with your account.'
    ),
    (
      'Settings > Network > Private DNS',
      'Inspect encrypted DNS provider setting',
      'Kagua Private DNS',
      'Android 9+',
      'A wrong provider can prevent DNS resolution.'
    ),
    (
      'Settings > Security > Screen lock',
      'Review lock screen protection',
      'Kagua ulinzi wa skrini iliyofungwa',
      'Android',
      'Use a strong PIN and keep recovery options current.'
    ),
    (
      'Settings > System > Languages & input',
      'Review keyboard and input methods',
      'Kagua kibodi na njia za kuingiza',
      'Android',
      'Only enable trusted input method apps.'
    ),
    (
      'Settings > Apps > Special app access',
      'Review install and overlay permissions',
      'Kagua ruhusa maalum za programu',
      'Android',
      'Grant special access only to trusted apps.'
    ),
    (
      'Settings > Accounts',
      'Review accounts signed in on the device',
      'Kagua akaunti zilizoingia',
      'Android',
      'Remove accounts only with the owner’s approval.'
    ),
    (
      'Settings > Security & privacy > Updates',
      'Review security update date',
      'Kagua tarehe ya sasisho la usalama',
      'Recent Android versions',
      'Older patch levels may require vendor support.'
    ),
    (
      'Settings > About phone > Regulatory labels',
      'Find device certification information',
      'Pata taarifa za uthibitishaji wa kifaa',
      'Many Android devices',
      'Labels may be electronic or printed on the device.'
    ),
  ],
};

final mobileTricksData = <Map<String, String>>[
  for (final group in _mobileGroups.entries)
    for (final item in group.value)
      {
        'code': item.$1,
        'title': item.$2,
        'desc_sw': item.$3,
        'desc_en': item.$2,
        'category': group.key,
        'warning': item.$5,
        'worksOn': item.$4,
      },
];

const mobileTrickCategories = <String>[
  'USSD',
  'Diagnostic',
  'Battery',
  'Hidden',
];
