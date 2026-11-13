import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/system_snapshot.dart';
import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key, this.active = true});

  final bool active;

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  Timer? _timer;
  SystemSnapshot? _snapshot;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(covariant SystemMonitorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _activate();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  void _activate() {
    _refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final value = await readSystemSnapshot();
      if (mounted) {
        setState(() {
          _snapshot = value;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return PageScaffold(
      title: 'System Monitor',
      subtitle: 'Live platform metrics · refreshes every 2 seconds',
      children: [
        if (_error != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.orange),
              title: const Text('Some system metrics are unavailable'),
              subtitle: Text('$_error'),
              trailing: IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        Card(
          child: Column(
            children: [
              _Info('OS name', snapshot?.os ?? 'Reading…'),
              _Info('Version', snapshot?.version ?? 'Reading…'),
              _Info('Build', snapshot?.build ?? 'Reading…'),
              _Info('Hostname / device', snapshot?.hostname ?? 'Reading…'),
              _Info('Architecture', snapshot?.architecture ?? 'Reading…'),
              _Info('Processor', snapshot?.processor ?? 'Reading…'),
            ],
          ),
        ),
        Text('Performance', style: Theme.of(context).textTheme.titleLarge),
        _MetricBar(
          title: 'CPU',
          fraction:
              snapshot?.cpuUsage == null ? null : snapshot!.cpuUsage! / 100,
          value: snapshot?.cpuUsage == null
              ? 'Unavailable on this platform'
              : '${snapshot!.cpuUsage!.toStringAsFixed(1)}%',
        ),
        _MetricBar(
          title: 'RAM',
          fraction: snapshot?.ramUsage,
          value: snapshot == null
              ? 'Reading…'
              : '${formatBytes(snapshot.totalRam)} total · ${formatBytes(snapshot.totalRam != null && snapshot.freeRam != null ? snapshot.totalRam! - snapshot.freeRam! : null)} used · ${formatBytes(snapshot.freeRam)} free',
        ),
        _MetricBar(
          title: 'Disk',
          fraction: snapshot?.diskUsage,
          value: snapshot == null
              ? 'Reading…'
              : '${formatBytes(snapshot.totalDisk)} total · ${formatBytes(snapshot.freeDisk)} free',
        ),
        Card(
          child: ListTile(
            leading: Icon(
              _healthIcon(snapshot),
              color: _healthColor(snapshot),
            ),
            title: Text('System health: ${_health(snapshot)}'),
            subtitle: const Text(
              'Assessment uses available OS metrics only; unavailable metrics are not estimated.',
            ),
          ),
        ),
        Text('Storage Cleanup (manual review)',
            style: Theme.of(context).textTheme.titleLarge),
        const Card(
          child: ListTile(
            leading: Icon(Icons.folder_open),
            title: Text('Temporary files'),
            subtitle: Text(
              r'Windows: %TEMP% and C:\Windows\Temp'
              '\nWindows Prefetch: C:\\Windows\\Prefetch',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.warning_amber, color: Colors.orange),
            title: Text('Review before cleanup'),
            subtitle: Text(
              'Use Windows Disk Cleanup or Storage settings. This toolkit never deletes files automatically; avoid removing files currently in use.',
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cleanup commands'),
              content: const SelectableText(
                'cleanmgr\n'
                'DISM /Online /Cleanup-Image /StartComponentCleanup\n'
                'forfiles /p "%TEMP%" /s /m *.* /c "cmd /c echo @path"',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () => copyText(
                    context,
                    'cleanmgr && DISM /Online /Cleanup-Image /StartComponentCleanup',
                  ),
                  child: const Text('Copy safe review commands'),
                ),
              ],
            ),
          ),
          icon: const Icon(Icons.cleaning_services),
          label: const Text('Show cleanup commands'),
        ),
        if (!Platform.isWindows)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Windows cleanup commands above are for your Windows workstation; they are not executed on this device.',
              style: TextStyle(color: ToolkitColors.muted),
            ),
          ),
      ],
    );
  }

  String _health(SystemSnapshot? value) {
    if (value == null) return _error == null ? 'Checking' : 'Unavailable';
    final cpu = value.cpuUsage;
    final ram = value.ramUsage;
    final disk = value.diskUsage;
    if ((cpu != null && cpu >= 95) ||
        (ram != null && ram >= .95) ||
        (disk != null && disk >= .98)) {
      return 'Attention';
    }
    if (cpu == null && ram == null && disk == null) return 'Unavailable';
    if ((cpu != null && cpu >= 80) ||
        (ram != null && ram >= .85) ||
        (disk != null && disk >= .9)) {
      return 'Monitor';
    }
    return 'Normal';
  }

  IconData _healthIcon(SystemSnapshot? value) => switch (_health(value)) {
        'Normal' => Icons.check_circle_outline,
        'Attention' => Icons.error_outline,
        'Monitor' => Icons.warning_amber,
        _ => Icons.help_outline,
      };

  Color _healthColor(SystemSnapshot? value) => switch (_health(value)) {
        'Normal' => ToolkitColors.primary,
        'Attention' => Colors.redAccent,
        'Monitor' => Colors.orange,
        _ => ToolkitColors.muted,
      };
}

class _Info extends StatelessWidget {
  const _Info(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(title),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Text(value, textAlign: TextAlign.end),
        ),
      );
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.title,
    required this.fraction,
    required this.value,
  });

  final String title;
  final double? fraction;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Flexible(
                    child: Text(value, textAlign: TextAlign.end),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: fraction?.clamp(0, 1) ?? 0,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      );
}
