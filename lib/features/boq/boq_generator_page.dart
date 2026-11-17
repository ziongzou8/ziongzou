import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/document_export_utils.dart';
import '../../core/toolkit_utils.dart';
import 'boq_document.dart';
import '../recent_documents_section.dart';

class BoqGeneratorPage extends StatefulWidget {
  const BoqGeneratorPage({
    super.key,
    required this.preferences,
    this.documentOpener,
  });

  final SharedPreferences preferences;
  final ExportedDocumentOpener? documentOpener;

  @override
  State<BoqGeneratorPage> createState() => _BoqGeneratorPageState();
}

class _BoqGeneratorPageState extends State<BoqGeneratorPage> {
  final _form = GlobalKey<FormState>();
  final _projectTitle = TextEditingController();
  final _client = TextEditingController();
  final _reference = TextEditingController();
  final _date = TextEditingController();
  final _currency = TextEditingController(text: 'TZS');
  final List<_BoqRowControllers> _items = [];
  final List<_BoqColumnController> _columns = [];
  bool _busy = false;
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _reference.text = 'BOQ-${now.year}${_two(now.month)}${_two(now.day)}-'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    _date.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _items.add(_BoqRowControllers());
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _projectTitle.dispose();
    _client.dispose();
    _reference.dispose();
    _date.dispose();
    _currency.dispose();
    for (final column in _columns) {
      column.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double get _grandTotal => _items.fold(
        0,
        (total, item) =>
            total + _number(item.quantity) * _number(item.unitRate),
      );

  void _addItem() => setState(
        () => _items.add(
          _BoqRowControllers(customColumnCount: _columns.length),
        ),
      );

  void _addColumn() {
    setState(() {
      var columnNumber = 1;
      while (_columns.any(
        (column) => column.title.text.trim() == 'Column $columnNumber',
      )) {
        columnNumber++;
      }
      _columns.add(
        _BoqColumnController()..title.text = 'Column $columnNumber',
      );
      for (final item in _items) {
        item.customValues.add(TextEditingController());
      }
    });
  }

  void _removeColumn(int index) {
    final removed = _columns.removeAt(index);
    removed.dispose();
    for (final item in _items) {
      item.customValues.removeAt(index).dispose();
    }
    setState(() {});
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    final removed = _items.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _generateBoq() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_items.isEmpty) {
      showToolkitMessage(context, 'Add at least one BOQ line item.');
      return;
    }
    setState(() => _busy = true);
    try {
      final logoBytes = (await rootBundle.load('assets/ahead_africa_logo.png'))
          .buffer
          .asUint8List();
      final bytes = createBoqWorkbook(
        projectTitle: _projectTitle.text.trim(),
        client: _client.text.trim(),
        reference: _reference.text.trim(),
        date: _date.text.trim(),
        currency: _currency.text.trim(),
        items: [
          for (final item in _items)
            BoqLineItem(
              description: item.description.text.trim(),
              unit: item.unit.text.trim(),
              quantity: _number(item.quantity),
              unitRate: _number(item.unitRate),
              customValues: [
                for (final value in item.customValues) value.text.trim(),
              ],
            ),
        ],
        customColumns: [
          for (final column in _columns) column.title.text.trim(),
        ],
        logoBytes: logoBytes,
      );
      final filePath = await saveExportedDocument(
        name: _reference.text,
        extension: 'xlsx',
        bytes: bytes,
      );
      if (mounted) {
        setState(() => _lastSavedPath = filePath);
      }
      try {
        await recordRecentExport(
          preferences: widget.preferences,
          historyKey: 'boq_history',
          title: _projectTitle.text.trim(),
          subtitle: 'BOQ · ${_client.text.trim()}',
          filePath: filePath,
        );
      } catch (error) {
        if (mounted) {
          showToolkitMessage(
            context,
            'BOQ saved to $filePath, but recent history could not be updated: $error',
          );
        }
        return;
      }
      if (mounted) {
        setState(() => _lastSavedPath = filePath);
        showToolkitMessage(context, 'Excel BOQ saved: $filePath');
      }
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not generate BOQ: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRecentDocument(Map<String, dynamic> record) async {
    final filePath = record['path']?.toString() ?? '';
    if (filePath.isEmpty) {
      showToolkitMessage(context, 'This BOQ has no saved file path.');
      return;
    }
    try {
      await (widget.documentOpener ?? openExportedDocument)(filePath);
    } catch (error) {
      if (mounted) showToolkitMessage(context, 'Could not open BOQ: $error');
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
        title: 'BOQ Generator',
        subtitle:
            'Build a bill of quantities with calculated line totals and save it as an Excel workbook.',
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                _metadataField(_projectTitle, 'Project title', required: true),
                _metadataField(_client, 'Client name / organization',
                    required: true),
                _metadataField(_reference, 'Reference number', required: true),
                _metadataField(_date, 'Date', required: true),
                _metadataField(
                  _currency,
                  'Currency (for example, TZS)',
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
                if (_columns.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Custom columns',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (var index = 0; index < _columns.length; index++)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _columns[index].title,
                            decoration: InputDecoration(
                              labelText: 'Column ${index + 1} heading',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove column',
                          onPressed: () => _removeColumn(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                ],
                for (var index = 0; index < _items.length; index++)
                  _buildItemCard(index),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add BOQ row'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _addColumn,
                icon: const Icon(Icons.view_column_outlined),
                label: const Text('Add BOQ column'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Estimated total'),
              trailing: Text(
                '${_currency.text.trim()} ${_grandTotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _generateBoq,
            icon: const Icon(Icons.table_view_outlined),
            label: Text(_busy ? 'Generating…' : 'Generate & Save Excel BOQ'),
          ),
          if (_lastSavedPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText('Last saved: $_lastSavedPath'),
            ),
          RecentDocumentsSection(
            preferences: widget.preferences,
            historyKey: 'boq_history',
            title: 'Recent BOQs',
            icon: Icons.table_view_outlined,
            onOpen: _openRecentDocument,
          ),
        ],
      );

  Widget _metadataField(
    TextEditingController controller,
    String label, {
    bool required = false,
    ValueChanged<String>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
          validator: required
              ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
              : null,
        ),
      );

  Widget _buildItemCard(int index) {
    final item = _items[index];
    return Card(
      key: ValueKey(item),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'BOQ item ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed:
                      _items.length == 1 ? null : () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              controller: item.description,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberField(
                    controller: item.quantity,
                    label: 'Quantity',
                    positive: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberField(
                    controller: item.unitRate,
                    label: 'Unit rate',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var columnIndex = 0;
                columnIndex < _columns.length;
                columnIndex++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: item.customValues[columnIndex],
                  decoration: InputDecoration(
                    labelText: _columns[columnIndex].title.text.trim().isEmpty
                        ? 'Column ${columnIndex + 1} value'
                        : _columns[columnIndex].title.text.trim(),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line total: ${_currency.text.trim()} '
                '${(_number(item.quantity) * _number(item.unitRate)).toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool positive = false,
    required ValueChanged<String> onChanged,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
        validator: (value) {
          final parsed = double.tryParse(value?.trim() ?? '');
          if (parsed == null ||
              !parsed.isFinite ||
              parsed < 0 ||
              (positive && parsed == 0)) {
            return positive ? 'Enter > 0' : 'Enter a number';
          }
          return null;
        },
      );
}

class _BoqColumnController {
  final title = TextEditingController();

  void dispose() => title.dispose();
}

class _BoqRowControllers {
  _BoqRowControllers({int customColumnCount = 0})
      : customValues = List.generate(
          customColumnCount,
          (_) => TextEditingController(),
        );

  final description = TextEditingController();
  final unit = TextEditingController(text: 'unit');
  final quantity = TextEditingController(text: '1');
  final unitRate = TextEditingController();
  final List<TextEditingController> customValues;

  void dispose() {
    description.dispose();
    unit.dispose();
    quantity.dispose();
    unitRate.dispose();
    for (final value in customValues) {
      value.dispose();
    }
  }
}
