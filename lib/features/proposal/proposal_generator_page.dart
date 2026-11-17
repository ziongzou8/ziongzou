import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/document_export_utils.dart';
import '../../core/toolkit_utils.dart';
import 'proposal_document.dart';
import '../recent_documents_section.dart';

class ProposalGeneratorPage extends StatefulWidget {
  const ProposalGeneratorPage({
    super.key,
    required this.preferences,
    this.documentOpener,
  });

  final SharedPreferences preferences;
  final ExportedDocumentOpener? documentOpener;

  @override
  State<ProposalGeneratorPage> createState() => _ProposalGeneratorPageState();
}

class _ProposalGeneratorPageState extends State<ProposalGeneratorPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  final List<ProposalAttachment> _attachments = [];
  final Map<String, String> _sectionLabels = {
    for (final section in proposalContentSections) section.$2: section.$1,
  };
  final Set<String> _hiddenSections = {};
  bool _busy = false;
  String? _lastSavedPath;

  static const _fieldSpecs = <(String, String, int)>[
    ('title', 'Proposal title', 1),
    ('client', 'Client name / organization', 1),
    ('client_contact', 'Client contact', 1),
    ('site', 'Site / location', 1),
    ('reference', 'Reference number', 1),
    ('date', 'Date', 1),
    ('technician', 'Technician name', 1),
    ('background', 'Background / Problem', 4),
    ('scope', 'Proposed solution / Scope of work', 5),
    ('deliverables', 'Deliverables', 4),
    ('timeline', 'Implementation plan / Timeline', 4),
    ('investment', 'Investment / Cost', 3),
    ('payment_terms', 'Payment terms', 3),
    ('validity', 'Proposal validity', 2),
    ('exclusions', 'Assumptions / Exclusions', 3),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fields = {
      for (final spec in _fieldSpecs)
        spec.$1: TextEditingController(text: _defaultValue(spec.$1, now)),
    };
  }

  String _defaultValue(String key, DateTime now) {
    final date = '${now.year}-${_two(now.month)}-${_two(now.day)}';
    if (key == 'date') return date;
    if (key == 'reference') {
      return 'PROP-${now.year}${_two(now.month)}${_two(now.day)}-'
          '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    }
    return '';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _values() => {
        for (final spec in _fieldSpecs) spec.$2: _fields[spec.$1]!.text.trim(),
      };

  Future<void> _generateProposal() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final logoBytes = (await rootBundle.load('assets/ahead_africa_logo.png'))
          .buffer
          .asUint8List();
      final attachments = [
        for (var index = 0; index < _attachments.length; index++)
          _attachmentForExport(_attachments[index], index),
      ];
      final bytes = await createProposalDocument(
        values: _values(),
        logoBytes: logoBytes,
        attachments: attachments,
        sectionLabels: _sectionLabels,
        hiddenSections: _hiddenSections,
      );
      final filePath = await saveExportedDocument(
        name: _fields['reference']!.text,
        extension: 'docx',
        bytes: bytes,
      );
      for (final attachment in attachments.where(
        (attachment) => !attachment.isImage,
      )) {
        await File(
          path.join(path.dirname(filePath), attachment.outputName!),
        ).writeAsBytes(attachment.bytes, flush: true);
      }
      if (mounted) {
        setState(() => _lastSavedPath = filePath);
      }
      final values = _values();
      try {
        await recordRecentExport(
          preferences: widget.preferences,
          historyKey: 'proposal_history',
          title: '${values['Proposal title']} · ${values['Reference']}',
          subtitle: 'Proposal · ${values['Client']}',
          filePath: filePath,
        );
      } catch (error) {
        if (mounted) {
          showToolkitMessage(
            context,
            'Proposal saved to $filePath, but recent history could not be updated: $error',
          );
        }
        return;
      }
      if (mounted) {
        setState(() => _lastSavedPath = filePath);
        showToolkitMessage(context, 'Word proposal saved: $filePath');
      }
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not generate proposal: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ProposalAttachment _attachmentForExport(
    ProposalAttachment attachment,
    int index,
  ) {
    if (attachment.isImage) return attachment;
    final reference = _fields['reference']!.text.trim().replaceAll(
          RegExp(r'[^A-Za-z0-9_-]'),
          '_',
        );
    final name = path.basename(attachment.name).replaceAll(
          RegExp(r'[^A-Za-z0-9._-]'),
          '_',
        );
    return ProposalAttachment(
      name: attachment.name,
      bytes: attachment.bytes,
      extension: attachment.extension,
      section: attachment.section,
      outputName: '${reference}_attachment_${index + 1}_$name',
    );
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;

      final added = <ProposalAttachment>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw StateError('Could not read the selected file: ${file.name}');
        }
        added.add(
          ProposalAttachment(
            name: file.name,
            bytes: bytes,
            extension: (file.extension ?? '').toLowerCase(),
            section: proposalContentSections[1].$2,
          ),
        );
      }
      if (added.isNotEmpty) {
        setState(() => _attachments.addAll(added));
      }
    } catch (error) {
      if (mounted) {
        showToolkitMessage(
            context, 'Could not add proposal attachments: $error');
      }
    }
  }

  void _updateAttachmentSection(int index, String? section) {
    if (section == null) return;
    final attachment = _attachments[index];
    setState(() {
      _attachments[index] = ProposalAttachment(
        name: attachment.name,
        bytes: attachment.bytes,
        extension: attachment.extension,
        section: section,
      );
    });
  }

  String _sectionLabel(String sectionKey) => _sectionLabels[sectionKey]!;

  bool _isOptionalSection(String fieldLabel) =>
      _sectionLabels.containsKey(fieldLabel);

  Future<void> _renameSection(String sectionKey) async {
    var newLabel = _sectionLabel(sectionKey);
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename proposal section'),
        content: TextFormField(
          initialValue: newLabel,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Section name'),
          onChanged: (value) => newLabel = value,
          onFieldSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(newLabel),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final updatedLabel = label?.trim();
    if (!mounted || updatedLabel == null) return;
    if (updatedLabel.isEmpty) {
      showToolkitMessage(context, 'Section name cannot be empty.');
      return;
    }
    if (_sectionLabels.entries.any(
      (entry) =>
          entry.key != sectionKey &&
          entry.value.toLowerCase() == updatedLabel.toLowerCase(),
    )) {
      showToolkitMessage(context, 'Each section must have a unique name.');
      return;
    }
    setState(() => _sectionLabels[sectionKey] = updatedLabel);
  }

  Widget _buildHiddenSections() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hidden proposal sections',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final section in proposalContentSections)
                if (_hiddenSections.contains(section.$2))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_sectionLabel(section.$2)),
                    trailing: IconButton(
                      tooltip: 'Restore ${_sectionLabel(section.$2)}',
                      onPressed: _busy
                          ? null
                          : () => setState(
                                () => _hiddenSections.remove(section.$2),
                              ),
                      icon: const Icon(Icons.restore),
                    ),
                  ),
            ],
          ),
        ),
      );

  Future<void> _openRecentDocument(Map<String, dynamic> record) async {
    final filePath = record['path']?.toString() ?? '';
    if (filePath.isEmpty) {
      showToolkitMessage(context, 'This proposal has no saved file path.');
      return;
    }
    try {
      await (widget.documentOpener ?? openExportedDocument)(filePath);
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not open proposal: $error');
      }
    }
  }

  Widget _buildAttachmentsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proposal attachments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Attach files or images to a proposal section. Images are '
                'embedded in the Word document; other files are saved beside '
                'it and linked from the selected section.',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickAttachments,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add files or images'),
              ),
              for (var index = 0; index < _attachments.length; index++)
                Card(
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_attachments[index].isImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _attachments[index].bytes,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(
                                width: 72,
                                height: 72,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            width: 72,
                            height: 72,
                            child: Icon(Icons.insert_drive_file_outlined),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attachments[index].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _attachments[index].section,
                                decoration: const InputDecoration(
                                  labelText: 'Proposal section',
                                ),
                                items: [
                                  for (final section in proposalContentSections)
                                    DropdownMenuItem(
                                      value: section.$2,
                                      child: Text(_sectionLabel(section.$2)),
                                    ),
                                ],
                                onChanged: _busy
                                    ? null
                                    : (value) => _updateAttachmentSection(
                                          index,
                                          value,
                                        ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove attachment',
                          onPressed: _busy
                              ? null
                              : () => setState(
                                    () => _attachments.removeAt(index),
                                  ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => PageScaffold(
        title: 'Proposal Generator',
        subtitle:
            'Write a client proposal and save it as an editable Microsoft Word document.',
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                for (final spec in _fieldSpecs)
                  if (!_hiddenSections.contains(spec.$2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: _fields[spec.$1],
                        minLines: spec.$3,
                        maxLines: spec.$3,
                        keyboardType: spec.$3 > 1
                            ? TextInputType.multiline
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: _sectionLabels[spec.$2] ?? spec.$2,
                          suffixIcon: _isOptionalSection(spec.$2)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip:
                                          'Rename ${_sectionLabel(spec.$2)}',
                                      onPressed: _busy
                                          ? null
                                          : () => _renameSection(spec.$2),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Hide ${_sectionLabel(spec.$2)}',
                                      onPressed: _busy
                                          ? null
                                          : () => setState(
                                                () => _hiddenSections
                                                    .add(spec.$2),
                                              ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        validator: const {
                          'title',
                          'client',
                          'scope',
                          'technician',
                        }.contains(spec.$1)
                            ? (value) => value == null || value.trim().isEmpty
                                ? 'Required'
                                : null
                            : null,
                      ),
                    ),
              ],
            ),
          ),
          if (_hiddenSections.isNotEmpty) _buildHiddenSections(),
          const SizedBox(height: 8),
          _buildAttachmentsSection(),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _generateProposal,
            icon: const Icon(Icons.description_outlined),
            label:
                Text(_busy ? 'Generating…' : 'Generate & Save Word Proposal'),
          ),
          if (_lastSavedPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText('Last saved: $_lastSavedPath'),
            ),
          RecentDocumentsSection(
            preferences: widget.preferences,
            historyKey: 'proposal_history',
            title: 'Recent Proposals',
            icon: Icons.description_outlined,
            onOpen: _openRecentDocument,
          ),
        ],
      );
}
