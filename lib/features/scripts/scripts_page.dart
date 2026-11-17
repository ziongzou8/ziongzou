import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';
import '../../core/windows_command_runner.dart';
import '../../data/scripts_data.dart';

class ScriptsPage extends StatefulWidget {
  const ScriptsPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage> {
  late final TextEditingController _search;
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final categories =
        scriptsData.map((item) => item['category']!).toSet().toList()..sort();
    final entries = scriptsData.where((entry) {
      return (_category == 'All' || entry['category'] == _category) &&
          entry.values.any((value) => value.toLowerCase().contains(query));
    }).toList();
    return PageScaffold(
      title: 'Scripts Library',
      subtitle:
          '${scriptsData.length} reviewed command snippets · inspect and confirm before running',
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search scripts',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final category in ['All', ...categories])
              FilterChip(
                label: Text(category),
                selected: category == _category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        for (final entry in entries) _scriptCard(context, entry),
        if (entries.isEmpty)
          const Card(child: ListTile(title: Text('No matching scripts.'))),
      ],
    );
  }

  Widget _scriptCard(BuildContext context, Map<String, String> entry) {
    final risk = entry['riskLevel']!;
    final color = switch (risk) {
      'Advanced' => Colors.red,
      'Medium' => Colors.orange,
      _ => ToolkitColors.primary,
    };
    return Card(
      child: ExpansionTile(
        title: Text(entry['name']!),
        subtitle: Text(
          '${entry['category']} · $risk · ${entry['requiredPermissions']}',
        ),
        trailing: Chip(
          label: Text(risk),
          backgroundColor: color.withAlpha(40),
          side: BorderSide(color: color),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          Text(entry['description']!),
          Text(entry['purpose']!,
              style: const TextStyle(color: ToolkitColors.muted)),
          const SizedBox(height: 8),
          TerminalPanel(text: entry['scriptContent']!),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(entry['executionInstructions']!)),
              IconButton(
                tooltip: 'Execution instructions and confirmation',
                onPressed: () => _instructions(context, entry),
                icon: const Icon(Icons.info_outline),
              ),
              Tooltip(
                message: risk == 'Advanced'
                    ? 'Advanced scripts remain copy-only.'
                    : 'Run after confirmation',
                child: TextButton.icon(
                  onPressed: risk == 'Advanced'
                      ? null
                      : () => runWindowsCommand(
                            context,
                            title: entry['name']!,
                            command: entry['scriptContent']!,
                            riskLevel: risk,
                            requiresAdministrator:
                                entry['requiredPermissions'] == 'Admin',
                          ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                ),
              ),
              IconButton(
                tooltip: 'Copy script',
                onPressed: () => _copy(context, entry),
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          Text('Expected output: ${entry['expectedOutput']}'),
        ],
      ),
    );
  }

  Future<void> _instructions(
    BuildContext context,
    Map<String, String> entry,
  ) async {
    final advanced = entry['riskLevel'] == 'Advanced';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(advanced ? 'Advanced script confirmation' : entry['name']!),
        content: Text(
          '${entry['executionInstructions']}\n\n'
          'Required permission: ${entry['requiredPermissions']}\n'
          'Expected output: ${entry['expectedOutput']}\n\n'
          '${advanced ? 'This script may change system state. Review its content and confirm you have authorization before copying.' : 'Review the complete command and confirm the target system before running.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(advanced ? 'I understand' : 'Copy script'),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await copyText(context, entry['scriptContent']!);
    }
  }

  Future<void> _copy(
    BuildContext context,
    Map<String, String> entry,
  ) async {
    final content = entry['scriptContent']!;
    if (entry['riskLevel'] == 'Advanced') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Advanced script'),
          content: const Text(
            'Review this command carefully and confirm authorization before copying it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await copyText(context, content);
  }
}
