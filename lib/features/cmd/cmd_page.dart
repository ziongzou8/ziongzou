import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';
import '../../core/windows_command_runner.dart';
import '../../data/cmd_data.dart';

class CmdPage extends StatefulWidget {
  const CmdPage({super.key, this.initialQuery = '', this.revision = 0});

  final String initialQuery;
  final int revision;

  @override
  State<CmdPage> createState() => _CmdPageState();
}

class _CmdPageState extends State<CmdPage> {
  late final TextEditingController _search;
  String _category = 'All';

  static const _bundles = <(String, String, List<String>)>[
    (
      'Slow PC',
      'Checks and repairs Windows component files, then scans the system drive.',
      [
        'sfc /scannow',
        'DISM /Online /Cleanup-Image /RestoreHealth',
        'chkdsk C: /scan',
      ],
    ),
    (
      'No Internet',
      'Refreshes DNS and resets the Windows network catalog and IP stack.',
      [
        'ipconfig /flushdns',
        'netsh winsock reset',
        'netsh int ip reset',
      ],
    ),
    (
      'Disk Full',
      'Opens supported cleanup and component-store maintenance tools. Review cleanup choices before confirming.',
      [
        'cleanmgr',
        'DISM /Online /Cleanup-Image /StartComponentCleanup',
        r'forfiles /p "%TEMP%" /s /m *.* /c "cmd /c echo @path"',
      ],
    ),
  ];

  static const _tools = <(String, String)>[
    ('Device Manager', 'devmgmt.msc'),
    ('Network Connections', 'ncpa.cpl'),
    ('Programs', 'appwiz.cpl'),
    ('Task Manager', 'taskmgr'),
    ('System Configuration', 'msconfig'),
    ('Registry Editor', 'regedit'),
    ('Services', 'services.msc'),
    ('Disk Management', 'diskmgmt.msc'),
  ];

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant CmdPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _search.text = widget.initialQuery;
      _category = 'All';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final entries = cmdData.where((entry) {
      return (_category == 'All' || entry['category'] == _category) &&
          (query.isEmpty ||
              entry.values.any((value) => value.toLowerCase().contains(query)));
    }).toList();
    return PageScaffold(
      title: 'Commands & Power Tools',
      subtitle:
          '${cmdData.length} local Windows commands · review and confirm before running',
      children: [
        Text('Bundle Fixes', style: Theme.of(context).textTheme.titleLarge),
        for (final bundle in _bundles)
          Card(
            child: ListTile(
              title: Text(bundle.$1),
              subtitle: Text('${bundle.$2}\n${bundle.$3.join(' && ')}'),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Copy bundle commands',
                    onPressed: () => copyText(context, bundle.$3.join(' && ')),
                    icon: const Icon(Icons.copy_all),
                  ),
                  IconButton(
                    tooltip:
                        'This bundle includes Advanced commands; run eligible commands individually.',
                    onPressed: null,
                    icon: const Icon(Icons.play_arrow),
                  ),
                ],
              ),
            ),
          ),
        const _Notice(
          text:
              'Safe and Medium commands run in Command Prompt after confirmation. '
              'Advanced commands remain copy-only. Disk cleanup lists temporary '
              'files for review and does not delete them.',
        ),
        const SizedBox(height: 8),
        Text('System Tools', style: Theme.of(context).textTheme.titleLarge),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 550
                    ? 2
                    : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: columns == 1 ? 3.2 : 2.2,
              children: [
                for (final tool in _tools)
                  OutlinedButton.icon(
                    onPressed: () => _toolDialog(context, tool.$1, tool.$2),
                    icon: const Icon(Icons.launch),
                    label: Text(tool.$1),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search commands',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final category in ['All', ...cmdCategories])
              FilterChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: entries.isEmpty
                ? null
                : () => copyText(
                      context,
                      entries.map((entry) => entry['cmd']).join(' && '),
                    ),
            icon: const Icon(Icons.copy_all),
            label: Text(
              _category == 'All'
                  ? 'Copy All Matching Commands'
                  : 'Copy All in $_category',
            ),
          ),
        ),
        if (entries.isEmpty)
          const Card(child: ListTile(title: Text('No matching commands.')))
        else
          for (final entry in entries) _commandCard(context, entry),
      ],
    );
  }

  Widget _commandCard(BuildContext context, Map<String, String> entry) {
    final (label, color) = switch (entry['risk']) {
      'Medium' => ('Medium', Colors.orange),
      'Advanced' => ('Advanced', Colors.red),
      _ => ('Safe', ToolkitColors.primary),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(entry['cmd']!)),
                Chip(
                  label: Text(label),
                  backgroundColor: color.withAlpha(40),
                  side: BorderSide(color: color),
                ),
              ],
            ),
            TerminalPanel(text: 'C:\\> ${entry['syntax']}'),
            const SizedBox(height: 8),
            Text(entry['desc_sw']!),
            Text(entry['desc_en']!,
                style: const TextStyle(color: ToolkitColors.muted)),
            Text(
              '${entry['category']} · ${entry['use_case_sw']}',
              style: const TextStyle(color: ToolkitColors.muted, fontSize: 12),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  Tooltip(
                    message: entry['risk'] == 'Advanced'
                        ? 'Advanced commands remain copy-only.'
                        : 'Run after confirmation',
                    child: TextButton.icon(
                      onPressed: entry['risk'] == 'Advanced'
                          ? null
                          : () => runWindowsCommand(
                                context,
                                title: entry['cmd']!,
                                command: entry['cmd']!,
                                riskLevel: entry['risk']!,
                              ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => copyText(context, entry['cmd']!),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toolDialog(
    BuildContext context,
    String title,
    String command,
  ) async {
    final copied = await copyText(context, command);
    if (!copied || !context.mounted) return;
    final openTool = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Copied $command. You can run this Windows tool now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open tool'),
          ),
        ],
      ),
    );
    if (openTool == true && context.mounted) {
      await openWindowsTool(context, title: title, command: command);
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: ToolkitColors.primary),
          title: Text(text),
        ),
      );
}
