import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentDocumentsSection extends StatelessWidget {
  const RecentDocumentsSection({
    super.key,
    required this.preferences,
    required this.historyKey,
    required this.title,
    required this.icon,
    required this.onOpen,
  });

  final SharedPreferences preferences;
  final String historyKey;
  final String title;
  final IconData icon;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
        future: Future.value(
          preferences.getStringList(historyKey) ?? const [],
        ),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <String>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (records.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Saved documents will appear here.'),
                  ),
                )
              else
                for (final record in records)
                  Builder(
                    builder: (context) {
                      try {
                        final values = jsonDecode(record) as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: Icon(icon),
                            title: Text(values['title']?.toString() ?? 'Document'),
                            subtitle: Text(
                              '${values['subtitle'] ?? ''}\n'
                              '${values['savedAt'] ?? ''}\n'
                              '${values['path'] ?? ''}',
                            ),
                            onTap: () => onOpen(values),
                          ),
                        );
                      } catch (error) {
                        return Card(
                          child: ListTile(
                            title: const Text('Unreadable recent document'),
                            subtitle: Text('$error'),
                          ),
                        );
                      }
                    },
                  ),
            ],
          );
        },
      );
}
