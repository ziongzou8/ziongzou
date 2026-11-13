import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/toolkit_utils.dart';
import 'features/cmd/cmd_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/network/network_doctor_page.dart';
import 'features/shortcuts/shortcuts_page.dart';
import 'features/tools/tools_page.dart';

const _footer =
    'AHEAD AFRICA SOLUTION LTD | Garden Ave & Ohio Street, Dar es-Salaam 11101 | '
    '+255 690 255 556 | GPS -6.82235,39.27704';

const _navigation = <(String, IconData)>[
  ('Home', Icons.dashboard_outlined),
  ('Shortcuts', Icons.keyboard_alt_outlined),
  ('Commands', Icons.terminal_outlined),
  ('Network', Icons.wifi_tethering_outlined),
  ('Tools', Icons.build_circle_outlined),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(ZiongZouApp(preferences: preferences));
}

class ZiongZouApp extends StatefulWidget {
  const ZiongZouApp({
    super.key,
    required this.preferences,
    this.systemInfoLoader,
  });

  final SharedPreferences preferences;
  final Future<Map<String, String>> Function()? systemInfoLoader;

  @override
  State<ZiongZouApp> createState() => _ZiongZouAppState();
}

class _ZiongZouAppState extends State<ZiongZouApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  int _tab = 0;
  int _toolTab = 0;
  int _revision = 0;
  String _query = '';

  void _navigate(int tab, [int toolTab = 0, String query = '']) {
    if (tab < 0 || tab >= _navigation.length) return;
    setState(() {
      _tab = tab;
      _toolTab = toolTab;
      _query = query;
      _revision++;
    });
  }

  void _quickAction(String action) {
    late final int tab;
    late final int toolTab;
    late final String commands;
    late final String activity;
    switch (action) {
      case 'slow':
        tab = 2;
        toolTab = 0;
        activity = 'Quick action: Fix Slow PC';
        commands =
            'sfc /scannow && DISM /Online /Cleanup-Image /RestoreHealth && chkdsk C: /scan';
      case 'wifi':
        tab = 3;
        toolTab = 0;
        activity = 'Quick action: Wi-Fi profile instructions';
        commands = 'netsh wlan show profiles';
      case 'system':
        tab = 4;
        toolTab = 0;
        activity = 'Quick action: System information';
        commands = 'systeminfo && wmic cpu get name';
      case 'disk':
        tab = 2;
        toolTab = 0;
        activity = 'Quick action: Disk cleanup';
        commands =
            'cleanmgr && DISM /Online /Cleanup-Image /StartComponentCleanup';
      default:
        showToolkitMessage(
          context,
          'Unknown quick action: $action',
        );
        return;
    }
    _navigate(tab, toolTab, action == 'disk' ? 'cleanmgr' : '');
    saveRecentActivity(widget.preferences, activity);
    _copyForQuickAction(commands);
    if (action == 'wifi') {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Profiles command copied. Use it on your Windows PC, then inspect an authorized profile in Network.',
          ),
        ),
      );
    }
  }

  Future<void> _copyForQuickAction(String command) async {
    try {
      await Clipboard.setData(ClipboardData(text: command));
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Commands copied')));
    } catch (error) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Could not copy commands: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return MaterialApp(
      title: 'ZIONGZOU TECHNICIAN TOOLKIT',
      debugShowCheckedModeBanner: false,
      theme: buildToolkitTheme(),
      scaffoldMessengerKey: _messengerKey,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!mobile)
                      NavigationRail(
                        selectedIndex: _tab,
                        onDestinationSelected: (index) => _navigate(index),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: ToolkitColors.card,
                        destinations: [
                          for (final item in _navigation)
                            NavigationRailDestination(
                              icon: Icon(item.$2),
                              label: Text(item.$1),
                            ),
                        ],
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          DashboardPage(
                            preferences: widget.preferences,
                            active: _tab == 0,
                            onSearchOpen: (query, tab, toolTab) =>
                                _navigate(tab, toolTab, query),
                            onQuickAction: _quickAction,
                          ),
                          ShortcutsPage(
                            preferences: widget.preferences,
                            initialQuery: _query,
                            revision: _revision,
                          ),
                          CmdPage(initialQuery: _query, revision: _revision),
                          NetworkDoctorPage(active: _tab == 3),
                          ToolsPage(
                            preferences: widget.preferences,
                            initialTab: _toolTab,
                            initialQuery: _query,
                            revision: _revision,
                            active: _tab == 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _CompanyFooter(),
            ],
          ),
        ),
        bottomNavigationBar: mobile
            ? NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (index) => _navigate(index),
                destinations: [
                  for (final item in _navigation)
                    NavigationDestination(
                      icon: Icon(item.$2),
                      label: item.$1,
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

class _CompanyFooter extends StatelessWidget {
  const _CompanyFooter();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: ToolkitColors.card,
        child: const Text(
          _footer,
          textAlign: TextAlign.center,
          style: TextStyle(color: ToolkitColors.muted, fontSize: 10),
        ),
      );
}
