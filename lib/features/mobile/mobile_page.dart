import 'package:flutter/material.dart';

import '../../core/toolkit_utils.dart';
import '../../data/mobile_tricks_data.dart';

class MobilePage extends StatefulWidget {
  const MobilePage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<MobilePage> createState() => _MobilePageState();
}

class _MobilePageState extends State<MobilePage> {
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
    final entries = mobileTricksData.where((entry) {
      return (_category == 'All' || entry['category'] == _category) &&
          entry.values.any((value) => value.toLowerCase().contains(query));
    }).toList();
    return PageScaffold(
      title: 'Mobile Technician Tricks',
      subtitle:
          '${mobileTricksData.length} Android tips · code availability varies by device',
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search mobile tips',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final category in ['All', ...mobileTrickCategories])
              FilterChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        for (final entry in entries)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.phone_android),
              title: Text(entry['title']!),
              subtitle: Text('${entry['category']} · ${entry['worksOn']}'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [
                SelectableText(entry['code']!),
                const SizedBox(height: 8),
                Text(entry['desc_sw']!),
                Text(entry['desc_en']!),
                Text(
                  'Tahadhari: ${entry['warning']}',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => copyText(context, entry['code']!),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
              ],
            ),
          ),
        if (entries.isEmpty)
          const Card(child: ListTile(title: Text('No mobile tips found.'))),
      ],
    );
  }
}
