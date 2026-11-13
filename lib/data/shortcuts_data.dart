class ShortcutEntry {
  const ShortcutEntry({
    required this.category,
    required this.keys,
    required this.action,
    required this.descEn,
    required this.descSw,
    required this.tip,
    this.windows = true,
  });

  final String category;
  final List<String> keys;
  final String action;
  final String descEn;
  final String descSw;
  final String tip;
  final bool windows;
}

const shortcutCategories = <String>[
  'General',
  'Explorer',
  'Browser',
  'VSCode',
  'Window',
  'Office',
  'Advanced',
];

const _shortcutTranslations = <String, (String, String)>{
  'Copy': (
    'Copy the selected item or text.',
    'Nakili kipengee au maandishi yaliyochaguliwa.'
  ),
  'Cut': (
    'Move the selected item or text to the clipboard.',
    'Hamisha kipengee au maandishi kwenye ubao wa kunakili.'
  ),
  'Move to Recycle Bin': (
    'Move the selected item to the Recycle Bin.',
    'Hamisha kipengee kilichochaguliwa kwenye Recycle Bin.'
  ),
  'Permanently delete': (
    'Delete the selected item without moving it to the Recycle Bin.',
    'Futa kipengee kilichochaguliwa bila kukipeleka kwenye Recycle Bin.'
  ),
  'Paste': (
    'Insert clipboard contents at the cursor.',
    'Bandika yaliyomo kwenye ubao wa kunakili.'
  ),
  'Undo': ('Reverse the last action.', 'Tendua kitendo cha mwisho.'),
  'Redo': (
    'Restore the action that was undone.',
    'Rudia kitendo kilichotenduliwa.'
  ),
  'Select all': (
    'Select all items or text in the current view.',
    'Chagua vipengee au maandishi yote kwenye mwonekano huu.'
  ),
  'Save': (
    'Save the current document or file.',
    'Hifadhi hati au faili ya sasa.'
  ),
  'Save as': (
    'Save a copy of the current file under a new name or location.',
    'Hifadhi nakala ya faili kwa jina au eneo jipya.'
  ),
  'Bookmark page': (
    'Add the current page to browser bookmarks.',
    'Ongeza ukurasa wa sasa kwenye alamisho za kivinjari.'
  ),
  'Print': (
    'Open the print dialog for the current document.',
    'Fungua kisanduku cha kuchapisha hati ya sasa.'
  ),
  'Find': (
    'Find text or an item in the current view.',
    'Tafuta maandishi au kipengee kwenye mwonekano huu.'
  ),
  'Replace': (
    'Find and replace text in the current document.',
    'Tafuta na ubadilishe maandishi kwenye hati ya sasa.'
  ),
  'New window': (
    'Open a new window in the current application.',
    'Fungua dirisha jipya kwenye programu ya sasa.'
  ),
  'Close tab': ('Close the active tab.', 'Funga kichupo kinachotumika.'),
  'New tab': ('Open a new tab.', 'Fungua kichupo kipya.'),
  'Reopen tab': (
    'Reopen the most recently closed tab.',
    'Fungua tena kichupo kilichofungwa hivi karibuni.'
  ),
  'Refresh': (
    'Refresh the current page or view.',
    'Onyesha upya ukurasa au mwonekano wa sasa.'
  ),
  'Open settings': (
    'Open the application settings.',
    'Fungua mipangilio ya programu.'
  ),
  'Open search': (
    'Focus the search field or open search.',
    'Weka mkazo kwenye sehemu ya utafutaji.'
  ),
  'Open file': ('Open a file picker.', 'Fungua kichagua faili.'),
  'Rename': (
    'Rename the selected file or item.',
    'Badilisha jina la faili au kipengee kilichochaguliwa.'
  ),
  'Create folder': ('Create a new folder.', 'Tengeneza folda mpya.'),
  'Go up one folder': (
    'Navigate to the parent folder.',
    'Nenda kwenye folda mama.'
  ),
  'Navigate back': (
    'Return to the previous page or location.',
    'Rudi kwenye ukurasa au eneo lililopita.'
  ),
  'Navigate forward': (
    'Move forward to the next page or location.',
    'Nenda mbele kwenye ukurasa au eneo linalofuata.'
  ),
  'Show properties': (
    'Open properties for the selected item.',
    'Fungua sifa za kipengee kilichochaguliwa.'
  ),
  'Open a new window': (
    'Open another window for the current location.',
    'Fungua dirisha jingine la eneo la sasa.'
  ),
  'Close window': ('Close the current window.', 'Funga dirisha la sasa.'),
  'Open downloads': (
    'Show the downloads page or folder.',
    'Onyesha ukurasa au folda ya vipakuliwa.'
  ),
  'Open history': ('Show browsing history.', 'Onyesha historia ya kuvinjari.'),
  'Zoom in': (
    'Increase the page or document zoom.',
    'Ongeza ukubwa wa ukurasa au hati.'
  ),
  'Zoom out': (
    'Decrease the page or document zoom.',
    'Punguza ukubwa wa ukurasa au hati.'
  ),
  'Reset zoom': (
    'Return zoom to its default level.',
    'Rudisha ukubwa wa kawaida wa mwonekano.'
  ),
  'Open developer tools': (
    'Open the browser developer tools.',
    'Fungua zana za msanidi kwenye kivinjari.'
  ),
  'Open command palette': (
    'Search for commands and settings.',
    'Tafuta amri na mipangilio.'
  ),
  'Quick open': (
    'Quickly open a file by name.',
    'Fungua faili haraka kwa jina.'
  ),
  'Show Explorer': (
    'Show the file Explorer panel.',
    'Onyesha paneli ya Explorer ya faili.'
  ),
  'Search in files': (
    'Search text across workspace files.',
    'Tafuta maandishi kwenye faili za workspace.'
  ),
  'Toggle terminal': (
    'Show or hide the integrated terminal.',
    'Onyesha au ficha terminal iliyojumuishwa.'
  ),
  'Toggle sidebar': (
    'Show or hide the side bar.',
    'Onyesha au ficha upau wa pembeni.'
  ),
  'Toggle line comment': (
    'Comment or uncomment the current line.',
    'Weka au ondoa maoni kwenye mstari wa sasa.'
  ),
  'Move line up': (
    'Move the current line one line up.',
    'Sogeza mstari wa sasa juu kwa mstari mmoja.'
  ),
  'Move line down': (
    'Move the current line one line down.',
    'Sogeza mstari wa sasa chini kwa mstari mmoja.'
  ),
  'Delete line': ('Delete the current line.', 'Futa mstari wa sasa.'),
  'Go to definition': (
    'Navigate to the selected symbol definition.',
    'Nenda kwenye ufafanuzi wa alama iliyochaguliwa.'
  ),
  'Navigate back in editor': (
    'Return to the previous editor location.',
    'Rudi kwenye eneo la awali la editor.'
  ),
  'Navigate forward in editor': (
    'Move forward in editor history.',
    'Nenda mbele kwenye historia ya editor.'
  ),
  'Show keyboard shortcuts': (
    'Open the keyboard shortcuts reference.',
    'Fungua orodha ya mikato ya kibodi.'
  ),
  'Open Extensions': (
    'Open the extensions view.',
    'Fungua mwonekano wa viendelezi.'
  ),
  'Bold': (
    'Apply or remove bold formatting.',
    'Weka au ondoa maandishi mazito.'
  ),
  'Italic': (
    'Apply or remove italic formatting.',
    'Weka au ondoa maandishi ya mlazo.'
  ),
  'Underline': (
    'Apply or remove underline formatting.',
    'Weka au ondoa mstari chini ya maandishi.'
  ),
  'Insert hyperlink': ('Insert or edit a hyperlink.', 'Weka au hariri kiungo.'),
  'Align left': (
    'Align the paragraph to the left.',
    'Panga aya upande wa kushoto.'
  ),
  'Center paragraph': ('Center-align the paragraph.', 'Panga aya katikati.'),
  'Align right': (
    'Align the paragraph to the right.',
    'Panga aya upande wa kulia.'
  ),
  'Justify paragraph': (
    'Justify the paragraph between both margins.',
    'Sawazisha aya kati ya pambizo zote mbili.'
  ),
  'Save document': (
    'Save the current Office document.',
    'Hifadhi hati ya Office ya sasa.'
  ),
  'Open document': (
    'Open an existing Office document.',
    'Fungua hati ya Office iliyopo.'
  ),
  'Select all text': (
    'Select all text in the document.',
    'Chagua maandishi yote kwenye hati.'
  ),
  'Find in document': (
    'Search for text in the current document.',
    'Tafuta maandishi kwenye hati ya sasa.'
  ),
  'Open new document': (
    'Create a new document or workbook.',
    'Tengeneza hati au workbook mpya.'
  ),
  'Paste special': (
    'Choose a format for pasted content.',
    'Chagua muundo wa maudhui yatakayobandikwa.'
  ),
  'Insert page break': (
    'Insert a page break at the cursor.',
    'Weka mwisho wa ukurasa kwenye sehemu ya mshale.'
  ),
  'Open print dialog': (
    'Open print settings for the document.',
    'Fungua mipangilio ya kuchapisha hati.'
  ),
  'Minimize window': (
    'Minimize the active window.',
    'Punguza dirisha linalotumika.'
  ),
  'Maximize window': (
    'Maximize or restore the active window.',
    'Panua au rudisha ukubwa wa dirisha.'
  ),
  'Snap window left': (
    'Snap the active window to the left half.',
    'Panga dirisha upande wa kushoto wa skrini.'
  ),
  'Snap window right': (
    'Snap the active window to the right half.',
    'Panga dirisha upande wa kulia wa skrini.'
  ),
  'Show all windows': (
    'Open Task View to see open windows.',
    'Fungua Task View kuona madirisha yaliyofunguliwa.'
  ),
  'Show desktop': (
    'Minimize windows to show the desktop.',
    'Punguza madirisha ili kuonyesha desktop.'
  ),
  'Lock PC': (
    'Lock the computer session.',
    'Funga kipindi cha matumizi ya kompyuta.'
  ),
  'Minimize all windows': (
    'Minimize all open windows.',
    'Punguza madirisha yote yaliyofunguliwa.'
  ),
  'Open task switcher': (
    'Switch between open applications.',
    'Badilisha kati ya programu zilizofunguliwa.'
  ),
  'Capture screen region': (
    'Capture a selected area of the screen.',
    'Piga picha ya eneo lililochaguliwa la skrini.'
  ),
  'Open Start menu': ('Open the Start menu.', 'Fungua menyu ya Start.'),
  'Open power user menu': (
    'Open Windows quick administration links.',
    'Fungua viungo vya haraka vya usimamizi wa Windows.'
  ),
  'Open Run dialog': ('Open the Run dialog.', 'Fungua kisanduku cha Run.'),
  'Open Task Manager': ('Open Task Manager.', 'Fungua Task Manager.'),
  'Open security options': (
    'Open Windows security options.',
    'Fungua chaguo za usalama za Windows.'
  ),
  'Open system properties': (
    'Open system information and settings.',
    'Fungua taarifa na mipangilio ya mfumo.'
  ),
  'Open clipboard history': (
    'Show clipboard history if enabled.',
    'Onyesha historia ya clipboard ikiwa imewezeshwa.'
  ),
  'Restart graphics driver': (
    'Refresh the graphics driver without restarting Windows.',
    'Washa upya kiendeshi cha picha bila kuwasha Windows upya.'
  ),
  'Open magnifier': (
    'Open the Windows Magnifier.',
    'Fungua Kikuzaji cha Windows.'
  ),
  'Close magnifier': (
    'Close the Windows Magnifier.',
    'Funga Kikuzaji cha Windows.'
  ),
  'Switch virtual desktop': (
    'Move between virtual desktops.',
    'Badilisha kati ya desktop pepe.'
  ),
  'Create virtual desktop': (
    'Create a new virtual desktop.',
    'Tengeneza desktop pepe mpya.'
  ),
  'Open accessibility settings': (
    'Open Windows Settings.',
    'Fungua Settings za Windows.'
  ),
  'Run as administrator': (
    'Launch the selected application with elevated permissions.',
    'Fungua programu iliyochaguliwa kwa ruhusa za msimamizi.'
  ),
  'Open device security screen': (
    'Open Windows security options.',
    'Fungua chaguo za usalama za Windows.'
  ),
  'Open clipboard': (
    'Open clipboard history if enabled.',
    'Fungua historia ya clipboard ikiwa imewezeshwa.'
  ),
  'Open emoji panel': (
    'Open the emoji and symbols panel.',
    'Fungua paneli ya emoji na alama.'
  ),
  'Open screen snipping': (
    'Open the screen capture toolbar.',
    'Fungua upau wa kupiga picha ya skrini.'
  ),
  'Open system menu': (
    'Open the system quick-link menu.',
    'Fungua menyu ya viungo vya haraka vya mfumo.'
  ),
  'Open context menu': (
    'Open the context menu for the selected item.',
    'Fungua menyu ya muktadha ya kipengee kilichochaguliwa.'
  ),
  'Switch tab': (
    'Move to the next open browser tab.',
    'Nenda kwenye kichupo kinachofuata cha kivinjari.'
  ),
  'Switch application': (
    'Switch to another open application.',
    'Badilisha kwenda programu nyingine iliyofunguliwa.'
  ),
  'Open file explorer': ('Open File Explorer.', 'Fungua File Explorer.'),
  'Open Windows Settings': (
    'Open Windows Settings.',
    'Fungua Settings za Windows.'
  ),
  'Open search panel': ('Open Windows Search.', 'Fungua Utafutaji wa Windows.'),
  'Open accessibility tools': (
    'Open Windows accessibility tools.',
    'Fungua zana za ufikivu za Windows.'
  ),
};

List<ShortcutEntry> _buildShortcuts(
  String category,
  List<(List<String>, String)> entries,
) {
  return entries.map((entry) {
    final translation = _shortcutTranslations[entry.$2] ??
        ('Use this keyboard shortcut.', 'Tumia mkato huu wa kibodi.');
    return ShortcutEntry(
      category: category,
      keys: entry.$1,
      action: entry.$2,
      descEn: translation.$1,
      descSw: translation.$2,
      tip: 'Hold modifier keys first, then press the final key.',
    );
  }).toList(growable: false);
}

final _shortcutEntries = <ShortcutEntry>[
  ..._buildShortcuts('General', const [
    (['Ctrl', 'C'], 'Copy'),
    (['Ctrl', 'X'], 'Cut'),
    (['Ctrl', 'V'], 'Paste'),
    (['Ctrl', 'Z'], 'Undo'),
    (['Ctrl', 'Y'], 'Redo'),
    (['Ctrl', 'A'], 'Select all'),
    (['Ctrl', 'S'], 'Save'),
    (['Ctrl', 'P'], 'Print'),
    (['Ctrl', 'F'], 'Find'),
    (['Ctrl', 'H'], 'Replace'),
    (['Ctrl', 'N'], 'New window'),
    (['Ctrl', 'W'], 'Close tab'),
    (['Ctrl', 'O'], 'Open file'),
    (['Ctrl', 'Shift', 'S'], 'Save as'),
    (['Alt', 'F4'], 'Close window'),
  ]),
  ..._buildShortcuts('File Explorer', const [
    (['Win', 'E'], 'Open file explorer'),
    (['Alt', 'Up'], 'Go up one folder'),
    (['Alt', 'Left'], 'Navigate back'),
    (['Alt', 'Right'], 'Navigate forward'),
    (['Ctrl', 'L'], 'Open search'),
    (['F2'], 'Rename'),
    (['Ctrl', 'Shift', 'N'], 'Create folder'),
    (['Alt', 'Enter'], 'Show properties'),
    (['Ctrl', 'N'], 'Open a new window'),
    (['Ctrl', 'W'], 'Close window'),
    (['F5'], 'Refresh'),
    (['Ctrl', 'F'], 'Open search'),
    (['Delete'], 'Move to Recycle Bin'),
    (['Shift', 'Delete'], 'Permanently delete'),
    (['Shift', 'F10'], 'Open context menu'),
  ]),
  ..._buildShortcuts('Browser', const [
    (['Ctrl', 'T'], 'New tab'),
    (['Ctrl', 'Shift', 'T'], 'Reopen tab'),
    (['Ctrl', 'W'], 'Close tab'),
    (['Ctrl', 'Tab'], 'Switch tab'),
    (['Ctrl', 'L'], 'Open search'),
    (['Ctrl', 'R'], 'Refresh'),
    (['Ctrl', 'D'], 'Bookmark page'),
    (['Ctrl', 'J'], 'Open downloads'),
    (['Ctrl', 'H'], 'Open history'),
    (['Ctrl', '+'], 'Zoom in'),
    (['Ctrl', '-'], 'Zoom out'),
    (['Ctrl', '0'], 'Reset zoom'),
    (['Ctrl', 'Shift', 'I'], 'Open developer tools'),
    (['Alt', 'Left'], 'Navigate back'),
    (['Alt', 'Right'], 'Navigate forward'),
  ]),
  ..._buildShortcuts('VS Code', const [
    (['Ctrl', 'Shift', 'P'], 'Open command palette'),
    (['Ctrl', 'P'], 'Quick open'),
    (['Ctrl', 'Shift', 'E'], 'Show Explorer'),
    (['Ctrl', 'Shift', 'F'], 'Search in files'),
    (['Ctrl', '`'], 'Toggle terminal'),
    (['Ctrl', 'B'], 'Toggle sidebar'),
    (['Ctrl', '/'], 'Toggle line comment'),
    (['Alt', 'Up'], 'Move line up'),
    (['Alt', 'Down'], 'Move line down'),
    (['Ctrl', 'Shift', 'K'], 'Delete line'),
    (['F12'], 'Go to definition'),
    (['Alt', 'Left'], 'Navigate back in editor'),
    (['Alt', 'Right'], 'Navigate forward in editor'),
    (['Ctrl', 'K', 'Ctrl', 'S'], 'Show keyboard shortcuts'),
    (['Ctrl', 'Shift', 'X'], 'Open Extensions'),
    (['Ctrl', 'Shift', 'N'], 'Open new window'),
    (['Ctrl', 'Shift', 'W'], 'Close window'),
    (['Ctrl', 'F'], 'Find'),
    (['Ctrl', 'H'], 'Replace'),
    (['Ctrl', 'Shift', '`'], 'Toggle terminal'),
  ]),
  ..._buildShortcuts('Office', const [
    (['Ctrl', 'B'], 'Bold'),
    (['Ctrl', 'I'], 'Italic'),
    (['Ctrl', 'U'], 'Underline'),
    (['Ctrl', 'K'], 'Insert hyperlink'),
    (['Ctrl', 'L'], 'Align left'),
    (['Ctrl', 'E'], 'Center paragraph'),
    (['Ctrl', 'R'], 'Align right'),
    (['Ctrl', 'J'], 'Justify paragraph'),
    (['Ctrl', 'S'], 'Save document'),
    (['Ctrl', 'O'], 'Open document'),
  ]),
  ..._buildShortcuts('Window Management', const [
    (['Win', 'Down'], 'Minimize window'),
    (['Win', 'Up'], 'Maximize window'),
    (['Win', 'Left'], 'Snap window left'),
    (['Win', 'Right'], 'Snap window right'),
    (['Win', 'Tab'], 'Show all windows'),
    (['Win', 'D'], 'Show desktop'),
    (['Win', 'L'], 'Lock PC'),
    (['Win', 'M'], 'Minimize all windows'),
    (['Alt', 'Tab'], 'Open task switcher'),
    (['Win', 'Shift', 'S'], 'Capture screen region'),
    (['Win'], 'Open Start menu'),
    (['Win', 'X'], 'Open power user menu'),
    (['Alt', 'Space'], 'Open system menu'),
    (['Alt', 'F4'], 'Close window'),
    (['Win', 'Shift', 'Left'], 'Switch virtual desktop'),
  ]),
  ..._buildShortcuts('Advanced', const [
    (['Ctrl', 'Shift', 'Esc'], 'Open Task Manager'),
    (['Win', 'R'], 'Open Run dialog'),
    (['Ctrl', 'Alt', 'Delete'], 'Open security options'),
    (['Win', 'V'], 'Open clipboard history'),
    (['Win', 'Ctrl', 'Shift', 'B'], 'Restart graphics driver'),
    (['Win', 'Ctrl', 'Left'], 'Switch virtual desktop'),
    (['Win', 'Ctrl', 'Right'], 'Switch virtual desktop'),
    (['Win', 'Ctrl', 'D'], 'Create virtual desktop'),
    (['Win', 'I'], 'Open Windows Settings'),
    (['Win', '.'], 'Open emoji panel'),
  ]),
];

final shortcutsData = <Map<String, dynamic>>[
  for (final entry in _shortcutEntries)
    {
      'keys': entry.keys,
      'action': entry.action,
      'desc_en': entry.descEn,
      'desc_sw': entry.descSw,
      'category': switch (entry.category) {
        'File Explorer' => 'Explorer',
        'VS Code' => 'VSCode',
        'Window Management' => 'Window',
        _ => entry.category,
      },
      'example': '${entry.keys.join(' + ')} → ${entry.action}',
      'windows': true,
    },
];

extension ShortcutMapCompatibility on Map<String, dynamic> {
  String get command => this['action'] as String;
  String get category => this['category'] as String;
}
