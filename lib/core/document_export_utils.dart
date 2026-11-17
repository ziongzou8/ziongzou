import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ExportedDocumentOpener = Future<void> Function(String filePath);

Future<void> recordRecentExport({
  required SharedPreferences preferences,
  required String historyKey,
  required String title,
  required String subtitle,
  required String filePath,
}) async {
  final previous = preferences.getStringList(historyKey) ?? const [];
  final history = previous.where((record) {
    try {
      final values = jsonDecode(record) as Map<String, dynamic>;
      return values['path'] != filePath;
    } catch (_) {
      return true;
    }
  });
  final record = jsonEncode({
    'title': title,
    'subtitle': subtitle,
    'path': filePath,
    'savedAt': DateTime.now().toIso8601String(),
  });
  final saved = await preferences.setStringList(
    historyKey,
    [record, ...history].take(20).toList(),
  );
  if (!saved) throw StateError('Recent document history could not be saved.');
}

Future<void> openExportedDocument(String filePath) async {
  if (!await File(filePath).exists()) {
    throw FileSystemException('Saved document was not found', filePath);
  }
  final result = await OpenFilex.open(filePath);
  if (result.type != ResultType.done) {
    throw StateError(result.message);
  }
}

Future<String> saveExportedDocument({
  required String name,
  required String extension,
  required List<int> bytes,
}) async {
  final directory = await _outputDirectory();
  final safeName = name.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  if (safeName.isEmpty) throw ArgumentError.value(name, 'name');
  final file = File(path.join(directory.path, '$safeName.$extension'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
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
