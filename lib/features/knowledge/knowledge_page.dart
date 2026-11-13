import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';
import '../../data/knowledge_base_data.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
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
    final entries = knowledgeBaseData.where((entry) {
      return (_category == 'All' || entry['category'] == _category) &&
          _searchable(entry).contains(query);
    }).toList();
    return PageScaffold(
      title: 'Technician Knowledge Base',
      subtitle: '${knowledgeBaseData.length} offline troubleshooting guides',
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search issues, symptoms, and solutions',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final category in ['All', ...knowledgeCategories])
              FilterChip(
                label: Text(category),
                selected: category == _category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        for (final entry in entries) _guideCard(entry),
        if (entries.isEmpty)
          const Card(child: ListTile(title: Text('No matching guides.'))),
      ],
    );
  }

  String _searchable(Map<String, dynamic> entry) {
    final values = <String>[];
    for (final value in entry.values) {
      if (value is Iterable) {
        values.addAll(value.map((item) => item.toString()));
      } else {
        values.add(value.toString());
      }
    }
    return values.join(' ').toLowerCase();
  }

  Widget _guideCard(Map<String, dynamic> entry) => Card(
        child: ExpansionTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(entry['title'] as String),
          subtitle: Text('${entry['category']} · ${entry['problem']}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _section('Likely causes', entry['causes'] as List),
            _section('Diagnosis', entry['diagnosisSteps'] as List),
            _section('Solution', [entry['solution']]),
            _section('Verification', [entry['verification']]),
            _section('Precautions', [entry['precautions']]),
          ],
        ),
      );

  Widget _section(String title, List values) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final value in values)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $value',
                  style: const TextStyle(color: ToolkitColors.muted),
                ),
              ),
          ],
        ),
      );
}
