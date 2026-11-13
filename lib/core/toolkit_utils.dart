import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

Future<bool> copyText(BuildContext context, String value) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    try {
      final preferences = await SharedPreferences.getInstance();
      await saveRecentActivity(preferences, 'Copied a toolkit item');
    } catch (error) {
      debugPrint('Unable to record clipboard activity: $error');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not copy: $error')),
      );
    }
    return false;
  }
}

Future<void> saveRecentActivity(
    SharedPreferences preferences, String item) async {
  try {
    final recent = preferences.getStringList('recent_activity') ?? <String>[];
    final updated = [item, ...recent.where((value) => value != item)].take(8);
    final saved =
        await preferences.setStringList('recent_activity', updated.toList());
    if (!saved) throw StateError('The activity history could not be saved.');
  } catch (error) {
    debugPrint('Unable to save activity: $error');
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(title),
            backgroundColor: ToolkitColors.background,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(subtitle,
                    style: const TextStyle(color: ToolkitColors.muted)),
                const SizedBox(height: 14),
                ...children,
              ]),
            ),
          ),
        ],
      );
}

class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(
            color: Color(0xFF4ADE80),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      );
}

void showToolkitMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
