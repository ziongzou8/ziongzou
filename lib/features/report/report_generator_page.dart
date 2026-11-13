import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/toolkit_utils.dart';

class ReportGeneratorPage extends StatefulWidget {
  const ReportGeneratorPage({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<ReportGeneratorPage> createState() => _ReportGeneratorPageState();
}

class _ReportGeneratorPageState extends State<ReportGeneratorPage> {
  static const _maxReportImages = 10;

  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  final List<_ReportImageAttachment> _attachments = [];
  String _status = 'Completed';
  bool _busy = false;
  String? _lastSavedPath;

  static const _fieldSpecs = <(String, String, int)>[
    ('company', 'Company name', 1),
    ('technician_details', 'Technician details / contact', 1),
    ('client', 'Client name / organization', 1),
    ('client_contact', 'Client contact', 1),
    ('site', 'Site / location', 1),
    ('date', 'Date', 1),
    ('time', 'Time', 1),
    ('reference', 'Reference number', 1),
    ('problem', 'Problem reported', 3),
    ('diagnosis', 'Diagnosis', 4),
    ('work', 'Work performed', 4),
    ('solution', 'Solution / outcome', 3),
    ('challenges', 'Challenges', 3),
    ('recommendations', 'Recommendations', 3),
    ('technician', 'Technician name', 1),
    ('signature', 'Signature (typed name or placeholder)', 1),
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
    if (key == 'date') return '${now.year}-${_two(now.month)}-${_two(now.day)}';
    if (key == 'time') return '${_two(now.hour)}:${_two(now.minute)}';
    if (key == 'reference') {
      return 'ZIO-${now.year}${_two(now.month)}${_two(now.day)}-'
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
    for (final attachment in _attachments) {
      attachment.description.dispose();
    }
    super.dispose();
  }

  Map<String, String> _values() => {
        for (final spec in _fieldSpecs) spec.$2: _fields[spec.$1]!.text.trim(),
        'Status': _status,
      };

  Future<Uint8List?> _createPdf() async {
    if (!_form.currentState!.validate()) return null;
    final values = _values();
    final document = pw.Document();
    final logoBytes = (await rootBundle.load('assets/ahead_africa_logo.png'))
        .buffer
        .asUint8List();
    final logo = pw.MemoryImage(logoBytes);
    final reportImages = [
      for (final attachment in _attachments)
        (
          image: pw.MemoryImage(attachment.bytes),
          description: attachment.description.text.trim(),
          name: attachment.name,
        ),
    ];
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '5th Floor, Garden Avenue Tower, Ohio St, Dar es Salaam',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Phone: 0690 255 556',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(
                logo,
                width: 210,
                height: 70,
                fit: pw.BoxFit.contain,
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TECHNICAL SERVICE REPORT',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      values['Reference number']!,
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            values['Company name']!,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              for (final entry in values.entries)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text(
                        entry.key,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text(entry.value.isEmpty ? '—' : entry.value),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
              'Technician signature: ${values['Signature (typed name or placeholder)']}'),
          if (reportImages.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'PHOTOGRAPHIC EVIDENCE',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            for (var index = 0; index < reportImages.length; index++) ...[
              pw.Text(
                'Image ${index + 1}: ${reportImages[index].description.isEmpty ? reportImages[index].name : reportImages[index].description}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Image(
                  reportImages[index].image,
                  width: 500,
                  height: 300,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 14),
            ],
          ],
          pw.SizedBox(height: 28),
          pw.Text('Generated by ZIONGZOU Technician Toolkit',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              )),
        ],
      ),
    );
    return document.save();
  }

  Future<Directory> _outputDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        await downloads.create(recursive: true);
        return downloads;
      }
    } on Object catch (error) {
      debugPrint('Downloads directory unavailable: $error');
    }
    final documents = await getApplicationDocumentsDirectory();
    await documents.create(recursive: true);
    return documents;
  }

  Future<void> _savePdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _createPdf();
      if (bytes == null) return;
      final directory = await _outputDirectory();
      final reference = _fields['reference']!.text.trim().replaceAll(
            RegExp(r'[^A-Za-z0-9_-]'),
            '_',
          );
      final file = File(path.join(directory.path, '$reference.pdf'));
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() => _lastSavedPath = file.path);
      }
      try {
        await _saveHistory(file.path);
      } catch (error) {
        if (mounted) {
          showToolkitMessage(
            context,
            'PDF saved to ${file.path}, but report history failed: $error',
          );
        }
        return;
      }
      if (mounted) {
        showToolkitMessage(context, 'PDF saved: ${file.path}');
      }
    } catch (error) {
      if (mounted) showToolkitMessage(context, 'Could not save report: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    await _withPdf((bytes) async {
      final reference = _fields['reference']!.text.trim();
      await Printing.sharePdf(bytes: bytes, filename: '$reference.pdf');
    });
  }

  Future<void> _printPdf() async {
    await _withPdf((bytes) async {
      await Printing.layoutPdf(
        name: '${_fields['reference']!.text.trim()}.pdf',
        onLayout: (_) async => bytes,
      );
    });
  }

  Future<void> _withPdf(Future<void> Function(Uint8List bytes) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _createPdf();
      if (bytes != null) await action(bytes);
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not create or share PDF: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveHistory(String filePath) async {
    final history = widget.preferences.getStringList('report_history') ?? [];
    final record = jsonEncode({
      'reference': _fields['reference']!.text.trim(),
      'client': _fields['client']!.text.trim(),
      'site': _fields['site']!.text.trim(),
      'date': _fields['date']!.text.trim(),
      'status': _status,
      'path': filePath,
      'savedAt': DateTime.now().toIso8601String(),
    });
    final saved = await widget.preferences.setStringList(
      'report_history',
      [record, ...history].take(20).toList(),
    );
    if (!saved) {
      throw StateError(
          'Report saved, but report history could not be updated.');
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
        title: 'Service Report Generator',
        subtitle:
            'Complete the service record, then generate, save, share or print PDF',
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                for (final spec in _fieldSpecs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _fields[spec.$1],
                      minLines: spec.$3,
                      maxLines: spec.$3,
                      readOnly: spec.$1 == 'date' || spec.$1 == 'time',
                      onTap: spec.$1 == 'date'
                          ? _pickDate
                          : spec.$1 == 'time'
                              ? _pickTime
                              : null,
                      onChanged: spec.$1 == 'signature'
                          ? (_) => setState(() {})
                          : null,
                      decoration: InputDecoration(
                        labelText: spec.$2,
                        suffixIcon: spec.$1 == 'reference'
                            ? IconButton(
                                tooltip: 'Generate new reference',
                                onPressed: _regenerateReference,
                                icon: const Icon(Icons.refresh),
                              )
                            : null,
                      ),
                      validator: {
                        'company',
                        'client',
                        'site',
                        'problem',
                        'diagnosis',
                        'work',
                        'solution',
                        'technician',
                      }.contains(spec.$1)
                          ? (value) => value == null || value.trim().isEmpty
                              ? 'Required'
                              : null
                          : null,
                    ),
                  ),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Completed', child: Text('Completed')),
                    DropdownMenuItem(
                        value: 'In progress', child: Text('In progress')),
                    DropdownMenuItem(
                        value: 'Escalated', child: Text('Escalated')),
                    DropdownMenuItem(
                        value: 'Pending parts', child: Text('Pending parts')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Technician signature placeholder\n${_fields['signature']!.text.isEmpty ? '________________________________' : _fields['signature']!.text}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildImageEvidenceSection(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _savePdf,
                icon: const Icon(Icons.save_alt),
                label: Text(_busy ? 'Working…' : 'Generate & Save PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _sharePdf,
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _printPdf,
                icon: const Icon(Icons.print),
                label: const Text('Print'),
              ),
            ],
          ),
          if (_lastSavedPath != null)
            SelectableText('Last saved: $_lastSavedPath'),
          const SizedBox(height: 12),
          Text('Recent Reports', style: Theme.of(context).textTheme.titleLarge),
          FutureBuilder<List<String>>(
            future: Future.value(
              widget.preferences.getStringList('report_history') ?? const [],
            ),
            builder: (context, snapshot) {
              final records = snapshot.data ?? const <String>[];
              if (records.isEmpty) {
                return const Card(
                  child: ListTile(title: Text('Saved reports appear here.')),
                );
              }
              return Column(
                children: [
                  for (final record in records)
                    Builder(
                      builder: (context) {
                        try {
                          final values =
                              jsonDecode(record) as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf),
                              title: Text(
                                  '${values['reference']} · ${values['client']}'),
                              subtitle: Text(
                                  '${values['date']} · ${values['status']}\n${values['path']}'),
                            ),
                          );
                        } catch (error) {
                          return Card(
                            child: ListTile(
                              title:
                                  const Text('Unreadable saved report record'),
                              subtitle: Text('$error'),
                            ),
                          );
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ],
      );

  Widget _buildImageEvidenceSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image evidence',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Add up to $_maxReportImages photos with a description. '
                'They will be included in the generated PDF.',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy || _attachments.length >= _maxReportImages
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add images'),
              ),
              for (var index = 0; index < _attachments.length; index++)
                _buildAttachmentCard(index),
            ],
          ),
        ),
      );

  Widget _buildAttachmentCard(int index) {
    final attachment = _attachments[index];
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                attachment.bytes,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 88,
                  height: 88,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: attachment.description,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Image description',
                  hintText: 'Describe the issue, work, or result shown',
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove image',
              onPressed: _busy ? null : () => _removeImage(index),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;

      final availableSlots = _maxReportImages - _attachments.length;
      final selectedFiles = result.files.take(availableSlots);
      final added = <_ReportImageAttachment>[];
      for (final file in selectedFiles) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw StateError('Could not read the selected image: ${file.name}');
        }
        added.add(
          _ReportImageAttachment(
            name: file.name,
            bytes: bytes,
            description: TextEditingController(),
          ),
        );
      }

      if (added.isNotEmpty) {
        setState(() => _attachments.addAll(added));
      }
      if (result.files.length > availableSlots) {
        showToolkitMessage(
          context,
          'Added $availableSlots image(s). Reports support up to '
          '$_maxReportImages images.',
        );
      }
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not add images: $error');
      }
    }
  }

  void _removeImage(int index) {
    final attachment = _attachments.removeAt(index);
    attachment.description.dispose();
    setState(() {});
  }

  Future<void> _pickDate() async {
    final date = DateTime.tryParse(_fields['date']!.text) ?? DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) {
      _fields['date']!.text =
          '${value.year}-${_two(value.month)}-${_two(value.day)}';
      setState(() {});
    }
  }

  Future<void> _pickTime() async {
    final parts = _fields['time']!.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ??
          TimeOfDay.now().hour,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ??
          TimeOfDay.now().minute,
    );
    final value = await showTimePicker(context: context, initialTime: initial);
    if (value != null) {
      _fields['time']!.text = '${_two(value.hour)}:${_two(value.minute)}';
      setState(() {});
    }
  }

  void _regenerateReference() {
    final now = DateTime.now();
    _fields['reference']!.text =
        'ZIO-${now.year}${_two(now.month)}${_two(now.day)}-'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    setState(() {});
  }
}

class _ReportImageAttachment {
  const _ReportImageAttachment({
    required this.name,
    required this.bytes,
    required this.description,
  });

  final String name;
  final Uint8List bytes;
  final TextEditingController description;
}
