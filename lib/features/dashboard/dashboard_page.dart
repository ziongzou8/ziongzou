import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/system_snapshot.dart';
import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';
import '../../data/cmd_data.dart';
import '../../data/knowledge_base_data.dart';
import '../../data/mobile_tricks_data.dart';
import '../../data/scripts_data.dart';
import '../../data/shortcuts_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.preferences,
    required this.onSearchOpen,
    required this.onQuickAction,
    required this.active,
  });

  final SharedPreferences preferences;
  final void Function(String query, int tab, int toolTab) onSearchOpen;
  final ValueChanged<String> onQuickAction;
  final bool active;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _search = TextEditingController();
  Timer? _infoTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<SystemSnapshot>? _snapshot;
  SystemSnapshot? _currentSnapshot;
  bool _systemUnavailable = false;
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.none];
  bool _connectivityUnavailable = false;

  bool get _online =>
      _connectivity.any((result) => result != ConnectivityResult.none);

  @override
  void initState() {
    super.initState();
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _activate();
      } else {
        _infoTimer?.cancel();
        _infoTimer = null;
        _connectivitySubscription?.cancel();
        _connectivitySubscription = null;
      }
    }
  }

  void _activate() {
    _refreshSystem();
    _watchConnectivity();
    _infoTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refreshSystem();
    });
  }

  Future<void> _watchConnectivity() async {
    try {
      final connectivity = Connectivity();
      final initial = await connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _connectivity = initial;
          _connectivityUnavailable = false;
        });
      }
      await _connectivitySubscription?.cancel();
      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen((results) {
        if (mounted) {
          setState(() {
            _connectivity = results;
            _connectivityUnavailable = false;
          });
        }
      }, onError: (Object _) {
        if (mounted) setState(() => _connectivityUnavailable = true);
      });
    } catch (_) {
      if (mounted) setState(() => _connectivityUnavailable = true);
    }
  }

  void _refreshSystem() {
    final request = readSystemSnapshot();
    setState(() {
      _snapshot = request;
      _systemUnavailable = false;
    });
    request.then(
      (value) {
        if (mounted) setState(() => _currentSnapshot = value);
      },
      onError: (Object _) {
        if (mounted) setState(() => _systemUnavailable = true);
      },
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _infoTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  List<_SearchHit> _searchHits(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    final hits = <_SearchHit>[];
    void addMatches(
      Iterable<Map<String, dynamic>> entries,
      int tab,
      int toolTab,
      String Function(Map<String, dynamic>) title,
      String Function(Map<String, dynamic>) text,
    ) {
      for (final entry in entries) {
        if (text(entry).toLowerCase().contains(normalized)) {
          hits.add(_SearchHit(title(entry), text(entry), tab, toolTab));
          if (hits.length >= 24) return;
        }
      }
    }

    addMatches(shortcutsData, 1, 0, (e) => '${e['keys']} · ${e['action']}',
        (e) => e.values.join(' '));
    addMatches(mobileTricksData, 4, 1, (e) => e['title'] as String,
        (e) => e.values.join(' '));
    addMatches(
        cmdData, 2, 0, (e) => e['cmd'] as String, (e) => e.values.join(' '));
    addMatches(scriptsData, 4, 2, (e) => e['name'] as String,
        (e) => e.values.join(' '));
    addMatches(
      knowledgeBaseData,
      4,
      3,
      (e) => e['title'] as String,
      (e) => e.values.join(' '),
    );
    return hits.take(24).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hits = _searchHits(_search.text);
    final toolkitCount = shortcutsData.length +
        mobileTricksData.length +
        cmdData.length +
        scriptsData.length +
        knowledgeBaseData.length;
    return PageScaffold(
      title: 'ZIONGZOU - Technician Toolkit',
      subtitle: 'AHEAD AFRICA · One Toolkit. Every Technician.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: ToolkitColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.handyman_outlined, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AHEAD AFRICA',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('One Toolkit. Every Technician.',
                          style: TextStyle(color: ToolkitColors.muted)),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(
                    _online ? Icons.cloud_done : Icons.cloud_off,
                    color: _online ? ToolkitColors.primary : Colors.orange,
                    size: 18,
                  ),
                  label: Text(
                    _connectivityUnavailable
                        ? 'Status unavailable'
                        : _online
                            ? 'Online'
                            : 'Offline',
                  ),
                ),
              ],
            ),
          ),
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search all offline toolkit content',
            suffixIcon: IconButton(
              onPressed: () {
                _search.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
            ),
          ),
        ),
        if (_search.text.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (final hit in hits)
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(hit.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(hit.description,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => widget.onSearchOpen(
                      _search.text,
                      hit.tab,
                      hit.toolTab,
                    ),
                  ),
                if (hits.isEmpty)
                  const ListTile(title: Text('No matching offline content')),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 850
                ? 4
                : constraints.maxWidth > 540
                    ? 2
                    : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: columns == 1 ? 3.4 : 1.8,
              children: [
                _StatCard(
                  label: 'Shortcuts',
                  value: '${shortcutsData.length}',
                  icon: Icons.keyboard_alt_outlined,
                  onTap: () => widget.onSearchOpen('', 1, 0),
                ),
                _StatCard(
                  label: 'Commands',
                  value: '${cmdData.length}',
                  icon: Icons.terminal,
                  onTap: () => widget.onSearchOpen('', 2, 0),
                ),
                _StatCard(
                  label: 'System Health',
                  value: _healthLabel,
                  icon: Icons.monitor_heart_outlined,
                  onTap: () => widget.onSearchOpen('', 4, 0),
                ),
                _StatCard(
                  label: 'Toolkit items',
                  value: '$toolkitCount',
                  icon: Icons.inventory_2_outlined,
                  onTap: () => widget.onSearchOpen('', 4, 1),
                ),
              ],
            );
          },
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _QuickAction(
              icon: Icons.speed,
              title: 'Fix Slow PC',
              onTap: () => widget.onQuickAction('slow'),
            ),
            _QuickAction(
              icon: Icons.wifi_password,
              title: 'WiFi Password',
              onTap: () => widget.onQuickAction('wifi'),
            ),
            _QuickAction(
              icon: Icons.info_outline,
              title: 'System Info',
              onTap: () => widget.onQuickAction('system'),
            ),
            _QuickAction(
              icon: Icons.cleaning_services_outlined,
              title: 'Disk Cleanup',
              onTap: () => widget.onQuickAction('disk'),
            ),
          ],
        ),
        Text('Live System Information',
            style: Theme.of(context).textTheme.titleLarge),
        FutureBuilder<SystemSnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('System information unavailable'),
                  subtitle: Text('${snapshot.error}'),
                  trailing: IconButton(
                    onPressed: _refreshSystem,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              );
            }
            final value = snapshot.data;
            return Card(
              child: Column(
                children: [
                  _InfoRow(
                      'Operating system',
                      value == null
                          ? 'Reading…'
                          : '${value.os} ${value.version}'),
                  _InfoRow('Hostname', value?.hostname ?? 'Reading…'),
                  _InfoRow('Processor', value?.processor ?? 'Reading…'),
                  _InfoRow(
                    'RAM total / available',
                    value == null
                        ? 'Reading…'
                        : '${formatBytes(value.totalRam)} / ${formatBytes(value.freeRam)}',
                  ),
                  _InfoRow(
                    'Storage total / available',
                    value == null
                        ? 'Reading…'
                        : '${formatBytes(value.totalDisk)} / ${formatBytes(value.freeDisk)}',
                  ),
                ],
              ),
            );
          },
        ),
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: FutureBuilder<List<String>>(
            future: Future.value(
              widget.preferences.getStringList('recent_activity') ?? const [],
            ),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <String>[];
              if (items.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.history),
                  title:
                      Text('Activity will appear here as you use the toolkit.'),
                );
              }
              return Column(
                children: [
                  for (final item in items.take(5))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history),
                      title: Text(item),
                    ),
                ],
              );
            },
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.sync),
            title: Text('Sync status'),
            subtitle: Text(
                'Offline-first toolkit · local data ready · sync queue is empty'),
          ),
        ),
      ],
    );
  }

  String get _healthLabel {
    final value = _currentSnapshot;
    if (_systemUnavailable) return 'Unavailable';
    if (value == null) return 'Checking';
    if ((value.cpuUsage != null && value.cpuUsage! >= 95) ||
        (value.ramUsage != null && value.ramUsage! >= .95) ||
        (value.diskUsage != null && value.diskUsage! >= .98)) {
      return 'Attention';
    }
    if (value.cpuUsage == null &&
        value.ramUsage == null &&
        value.diskUsage == null) {
      return 'Unavailable';
    }
    if ((value.cpuUsage != null && value.cpuUsage! >= 80) ||
        (value.ramUsage != null && value.ramUsage! >= .85) ||
        (value.diskUsage != null && value.diskUsage! >= .9)) {
      return 'Monitor';
    }
    return 'Normal';
  }
}

class _SearchHit {
  const _SearchHit(this.title, this.description, this.tab, this.toolTab);

  final String title;
  final String description;
  final int tab;
  final int toolTab;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 30, color: ToolkitColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(value,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(label,
                          style: const TextStyle(color: ToolkitColors.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(label),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Text(value, textAlign: TextAlign.end),
        ),
      );
}
