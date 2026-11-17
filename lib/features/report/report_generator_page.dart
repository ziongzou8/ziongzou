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

import '../../core/company_branding.dart';
import '../../core/toolkit_utils.dart';

const _reportContentSections = <(String, String)>[
  ('problem', 'Problem reported'),
  ('diagnosis', 'Diagnosis'),
  ('work', 'Work performed'),
  ('solution', 'Solution / outcome'),
  ('challenges', 'Challenges'),
  ('recommendations', 'Recommendations'),
];

class ReportGeneratorPage extends StatefulWidget {
  const ReportGeneratorPage({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<ReportGeneratorPage> createState() => _ReportGeneratorPageState();
}

class _ReportGeneratorPageState extends State<ReportGeneratorPage> {
  static const _maxReportImages = 10;

  final _form = GlobalKey<FormState>();
  final _signaturePadKey = GlobalKey();
  late final Map<String, TextEditingController> _fields;
  final List<_ReportAttachment> _attachments = [];
  final List<List<Offset>> _signatureStrokes = [];
  final Map<String, String> _sectionLabels = {
    for (final section in _reportContentSections) section.$1: section.$2,
  };
  final Set<String> _hiddenSections = {};
  String _status = 'Completed';
  _SignatureType _signatureType = _SignatureType.typed;
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
    ('signature', 'Typed signature', 1),
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
        for (final spec in _fieldSpecs)
          if (spec.$1 != 'signature') spec.$2: _fields[spec.$1]!.text.trim(),
        'Status': _status,
      };

  bool _validateSignature() {
    final message = switch (_signatureType) {
      _SignatureType.typed when _fields['signature']!.text.trim().isEmpty =>
        'Enter the technician signature.',
      _SignatureType.freehand when _signatureStrokes.isEmpty =>
        'Draw the technician signature before generating the report.',
      _ => null,
    };
    if (message == null) return true;
    showToolkitMessage(context, message);
    return false;
  }

  void _selectSignatureType(_SignatureType? value) {
    if (value == null || value == _signatureType) return;
    setState(() => _signatureType = value);
  }

  Offset _normalizedSignaturePoint(Offset point) {
    final renderObject = _signaturePadKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || renderObject.size.isEmpty) {
      return Offset.zero;
    }
    return Offset(
      (point.dx / renderObject.size.width).clamp(0.0, 1.0).toDouble(),
      (point.dy / renderObject.size.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  void _startSignatureStroke(DragStartDetails details) {
    setState(() {
      _signatureStrokes.add([
        _normalizedSignaturePoint(details.localPosition),
      ]);
    });
  }

  void _continueSignatureStroke(DragUpdateDetails details) {
    if (_signatureStrokes.isEmpty) return;
    setState(() {
      _signatureStrokes.last.add(
        _normalizedSignaturePoint(details.localPosition),
      );
    });
  }

  void _clearSignature() {
    setState(_signatureStrokes.clear);
  }

  String _signatureSvg() {
    final paths = _signatureStrokes.map((stroke) {
      if (stroke.isEmpty) return '';
      final commands = [
        for (var index = 0; index < stroke.length; index++)
          '${index == 0 ? 'M' : 'L'} '
              '${(stroke[index].dx * 600).toStringAsFixed(2)} '
              '${(stroke[index].dy * 160).toStringAsFixed(2)}',
      ].join(' ');
      return '<path d="$commands" fill="none" stroke="#000000" '
          'stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>';
    }).join();
    return '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="160" '
        'viewBox="0 0 600 160">$paths</svg>';
  }

  Future<Uint8List?> _createPdf() async {
    if (!_form.currentState!.validate() || !_validateSignature()) return null;
    final values = _values();
    final document = pw.Document();
    final logoBytes = (await rootBundle.load('assets/ahead_africa_logo.png'))
        .buffer
        .asUint8List();
    final logo = pw.MemoryImage(logoBytes);
    final reportAttachments = [
      for (final attachment in _attachments)
        (
          attachment: attachment,
          image: attachment.isImage ? pw.MemoryImage(attachment.bytes) : null,
          description: attachment.description.text.trim(),
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
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyAddress,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Phone: $companyPhone',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.UrlLink(
                    destination: companyWebsite,
                    child: pw.Text(
                      companyWebsite,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ],
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
                if (!_reportContentSections.any(
                  (section) => section.$2 == entry.key,
                ))
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
          for (final section in _reportContentSections)
            if (!_hiddenSections.contains(section.$1))
              ..._buildPdfSection(section, reportAttachments),
          pw.SizedBox(height: 18),
          pw.Text(
            'Technician signature',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          switch (_signatureType) {
            _SignatureType.typed => pw.Text(_fields['signature']!.text.trim()),
            _SignatureType.freehand => pw.SvgImage(
                svg: _signatureSvg(),
                width: 360,
                height: 96,
              ),
          },
        ],
      ),
    );
    return document.save();
  }

  List<pw.Widget> _buildPdfSection(
    (String, String) section,
    List<
            ({
              _ReportAttachment attachment,
              pw.MemoryImage? image,
              String description,
            })>
        attachments,
  ) {
    final sectionAttachments = attachments
        .where((item) => item.attachment.section == section.$1)
        .toList();
    final text = _fields[section.$1]!.text.trim();
    if (text.isEmpty && sectionAttachments.isEmpty) return [];

    return [
      pw.Text(
        _sectionLabels[section.$1]!,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      pw.SizedBox(height: 6),
      for (final item in sectionAttachments)
        if (item.attachment.position == _AttachmentPosition.beforeText)
          ..._pdfAttachment(item),
      if (text.isNotEmpty) pw.Text(text),
      for (final item in sectionAttachments)
        if (item.attachment.position == _AttachmentPosition.afterText)
          ..._pdfAttachment(item),
      pw.SizedBox(height: 14),
    ];
  }

  List<pw.Widget> _pdfAttachment(
    ({
      _ReportAttachment attachment,
      pw.MemoryImage? image,
      String description,
    }) item,
  ) {
    if (item.image == null) {
      return [
        pw.Text(
          'Attachment: ${item.attachment.name}'
          '${item.description.isEmpty ? '' : ' — ${item.description}'}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
      ];
    }

    return [
      if (item.description.isNotEmpty || item.attachment.name.isNotEmpty)
        pw.Text(
          item.description.isEmpty ? item.attachment.name : item.description,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      pw.SizedBox(height: 6),
      pw.Center(
        child: pw.Image(
          item.image!,
          width: 500,
          height: 300,
          fit: pw.BoxFit.contain,
        ),
      ),
      pw.SizedBox(height: 14),
    ];
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
      for (var index = 0; index < _attachments.length; index++) {
        final attachment = _attachments[index];
        if (attachment.isImage) continue;
        final name = path.basename(attachment.name).replaceAll(
              RegExp(r'[^A-Za-z0-9._-]'),
              '_',
            );
        await File(
          path.join(
            directory.path,
            '${reference}_attachment_${index + 1}_$name',
          ),
        ).writeAsBytes(attachment.bytes, flush: true);
      }
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

  Future<void> _openRecentReport(Map<String, dynamic> values) async {
    final reportPath = values['path']?.toString();
    if (reportPath == null || reportPath.isEmpty) {
      showToolkitMessage(context, 'This report has no saved PDF path.');
      return;
    }

    try {
      final bytes = await File(reportPath).readAsBytes();
      if (!mounted) return;
      final reference = values['reference']?.toString();
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                reference == null || reference.isEmpty
                    ? path.basename(reportPath)
                    : reference,
              ),
            ),
            body: PdfPreview(
              build: (_) async => bytes,
              pdfFileName: path.basename(reportPath),
              canChangeOrientation: false,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not open report: $error');
      }
    }
  }

  Future<void> _clearRecentReports() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent reports?'),
        content: const Text(
          'This clears the recent list only. Saved PDF files will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final cleared = await widget.preferences.setStringList(
        'report_history',
        const [],
      );
      if (!cleared) throw StateError('Recent reports could not be cleared.');
      if (mounted) {
        setState(() {});
        showToolkitMessage(context, 'Recent reports cleared.');
      }
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not clear recent reports: $error');
      }
    }
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
                for (final spec
                    in _fieldSpecs.where((spec) => spec.$1 != 'signature'))
                  if (!_hiddenSections.contains(spec.$1))
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
                        decoration: InputDecoration(
                          labelText: _sectionLabels[spec.$1] ?? spec.$2,
                          suffixIcon: _sectionLabels.containsKey(spec.$1)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip:
                                          'Rename ${_sectionLabels[spec.$1]}',
                                      onPressed: _busy
                                          ? null
                                          : () => _renameSection(spec.$1),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip:
                                          'Hide ${_sectionLabels[spec.$1]}',
                                      onPressed: _busy
                                          ? null
                                          : () => setState(
                                                () => _hiddenSections
                                                    .add(spec.$1),
                                              ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                )
                              : spec.$1 == 'reference'
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
                                }.contains(spec.$1) &&
                                !_hiddenSections.contains(spec.$1)
                            ? (value) => value == null || value.trim().isEmpty
                                ? 'Required'
                                : null
                            : null,
                      ),
                    ),
                _buildSignatureSection(),
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
                if (_hiddenSections.isNotEmpty) _buildHiddenSections(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildAttachmentsSection(),
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
          FutureBuilder<List<String>>(
            future: Future.value(
              widget.preferences.getStringList('report_history') ?? const [],
            ),
            builder: (context, snapshot) {
              final records = snapshot.data ?? const <String>[];
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Reports',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: records.isEmpty ? null : _clearRecentReports,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  if (records.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('Saved reports appear here.'),
                      ),
                    )
                  else
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
                                onTap: () => _openRecentReport(values),
                              ),
                            );
                          } catch (error) {
                            return Card(
                              child: ListTile(
                                title: const Text(
                                    'Unreadable saved report record'),
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

  Widget _buildSignatureSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technician signature',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              DropdownButtonFormField<_SignatureType>(
                key: const ValueKey('signature-type-selector'),
                initialValue: _signatureType,
                decoration: const InputDecoration(labelText: 'Signature type'),
                items: [
                  for (final type in _SignatureType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                ],
                onChanged: _selectSignatureType,
              ),
              const SizedBox(height: 8),
              switch (_signatureType) {
                _SignatureType.typed => TextFormField(
                    controller: _fields['signature'],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Typed signature',
                      hintText: 'Enter the technician name',
                    ),
                  ),
                _SignatureType.freehand => _buildFreehandSignature(),
              },
            ],
          ),
        ),
      );

  Widget _buildFreehandSignature() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Draw your signature using a finger, stylus, or mouse.'),
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('signature-pad'),
            height: 160,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(10),
            ),
            child: GestureDetector(
              key: _signaturePadKey,
              behavior: HitTestBehavior.opaque,
              onPanStart: _startSignatureStroke,
              onPanUpdate: _continueSignatureStroke,
              child: CustomPaint(
                painter: _SignaturePadPainter(_signatureStrokes),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('clear-signature-drawing'),
              onPressed: _signatureStrokes.isEmpty ? null : _clearSignature,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear drawing'),
            ),
          ),
        ],
      );

  Widget _buildAttachmentsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report attachments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Add up to $_maxReportImages images, or attach other files. '
                'Choose a report section and whether each item appears before '
                'or after its text. Other files are saved beside the PDF and '
                'listed in the report.',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickAttachments,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add files or images'),
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
            if (attachment.isImage)
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
              )
            else
              const SizedBox(
                width: 88,
                height: 88,
                child: Icon(Icons.insert_drive_file_outlined),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TextFormField(
                    controller: attachment.description,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: attachment.isImage
                          ? 'Image description'
                          : 'Description',
                      hintText: 'Describe this attachment',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: attachment.section,
                    decoration:
                        const InputDecoration(labelText: 'Report section'),
                    items: [
                      for (final section in _reportContentSections)
                        DropdownMenuItem(
                          value: section.$1,
                          child: Text(_sectionLabel(section.$1)),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => _updateAttachmentSection(index, value),
                  ),
                  DropdownButtonFormField<_AttachmentPosition>(
                    initialValue: attachment.position,
                    decoration: const InputDecoration(labelText: 'Placement'),
                    items: const [
                      DropdownMenuItem(
                        value: _AttachmentPosition.beforeText,
                        child: Text('Before section text'),
                      ),
                      DropdownMenuItem(
                        value: _AttachmentPosition.afterText,
                        child: Text('After section text'),
                      ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => _updateAttachmentPosition(index, value),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove attachment',
              onPressed: _busy ? null : () => _removeAttachment(index),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
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

      final currentImageCount =
          _attachments.where((item) => item.isImage).length;
      var availableImageSlots = _maxReportImages - currentImageCount;
      final added = <_ReportAttachment>[];
      var skippedImages = 0;
      for (final file in result.files) {
        final extension =
            path.extension(file.name).replaceFirst('.', '').toLowerCase();
        final isImage = const {'gif', 'jpeg', 'jpg', 'png'}.contains(extension);
        if (isImage && availableImageSlots == 0) {
          skippedImages++;
          continue;
        }
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw StateError('Could not read the selected file: ${file.name}');
        }
        added.add(
          _ReportAttachment(
            name: file.name,
            bytes: bytes,
            description: TextEditingController(),
            extension: extension,
            section: _reportContentSections[2].$1,
          ),
        );
        if (isImage) availableImageSlots--;
      }

      if (added.isNotEmpty) {
        setState(() => _attachments.addAll(added));
      }
      if (skippedImages > 0) {
        showToolkitMessage(
          context,
          'Skipped $skippedImages image(s). Reports support up to '
          '$_maxReportImages images.',
        );
      }
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not add report attachments: $error');
      }
    }
  }

  void _updateAttachmentSection(int index, String? section) {
    if (section == null) return;
    final attachment = _attachments[index];
    setState(() {
      _attachments[index] = attachment.copyWith(section: section);
    });
  }

  void _updateAttachmentPosition(
    int index,
    _AttachmentPosition? position,
  ) {
    if (position == null) return;
    final attachment = _attachments[index];
    setState(() {
      _attachments[index] = attachment.copyWith(position: position);
    });
  }

  void _removeAttachment(int index) {
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

  String _sectionLabel(String section) => _sectionLabels[section]!;

  Future<void> _renameSection(String section) async {
    var newLabel = _sectionLabel(section);
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename report section'),
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
          entry.key != section &&
          entry.value.toLowerCase() == updatedLabel.toLowerCase(),
    )) {
      showToolkitMessage(context, 'Each section must have a unique name.');
      return;
    }
    setState(() => _sectionLabels[section] = updatedLabel);
  }

  Widget _buildHiddenSections() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hidden report sections',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final section in _reportContentSections)
                if (_hiddenSections.contains(section.$1))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_sectionLabel(section.$1)),
                    trailing: IconButton(
                      tooltip: 'Restore ${_sectionLabel(section.$1)}',
                      onPressed: _busy
                          ? null
                          : () => setState(
                                () => _hiddenSections.remove(section.$1),
                              ),
                      icon: const Icon(Icons.restore),
                    ),
                  ),
            ],
          ),
        ),
      );
}

enum _SignatureType {
  typed('Typed name'),
  freehand('Freehand drawing');

  const _SignatureType(this.label);

  final String label;
}

class _SignaturePadPainter extends CustomPainter {
  const _SignaturePadPainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.dx * size.width, stroke.first.dy * size.height),
          pen.strokeWidth / 2,
          Paint()..color = pen.color,
        );
      } else {
        canvas.drawPath(path, pen);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}

enum _AttachmentPosition { beforeText, afterText }

class _ReportAttachment {
  const _ReportAttachment({
    required this.name,
    required this.bytes,
    required this.description,
    required this.extension,
    required this.section,
    this.position = _AttachmentPosition.afterText,
  });

  final String name;
  final Uint8List bytes;
  final TextEditingController description;
  final String extension;
  final String section;
  final _AttachmentPosition position;

  bool get isImage => const {'gif', 'jpeg', 'jpg', 'png'}.contains(extension);

  _ReportAttachment copyWith({
    String? section,
    _AttachmentPosition? position,
  }) =>
      _ReportAttachment(
        name: name,
        bytes: bytes,
        description: description,
        extension: extension,
        section: section ?? this.section,
        position: position ?? this.position,
      );
}
