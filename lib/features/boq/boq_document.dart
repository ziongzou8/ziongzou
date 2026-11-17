import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../core/company_branding.dart';

class BoqLineItem {
  const BoqLineItem({
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitRate,
    this.customValues = const [],
  });

  final String description;
  final String unit;
  final double quantity;
  final double unitRate;
  final List<String> customValues;

  double get amount => quantity * unitRate;
}

Uint8List createBoqWorkbook({
  required String projectTitle,
  required String client,
  required String reference,
  required String date,
  required String currency,
  required List<BoqLineItem> items,
  required Uint8List logoBytes,
  List<String> customColumns = const [],
}) {
  final populatedItems = items
      .where((item) =>
          item.description.trim().isNotEmpty ||
          item.customValues.any((value) => value.trim().isNotEmpty))
      .toList();
  if (populatedItems.isEmpty) {
    throw ArgumentError('Add at least one BOQ line item.');
  }
  final activeCustomColumns = [
    for (var index = 0; index < customColumns.length; index++)
      customColumns[index].trim().isEmpty
          ? 'Column ${index + 1}'
          : customColumns[index].trim(),
  ];
  final lastColumn = _columnName(6 + activeCustomColumns.length);

  final totalRow = 6 + populatedItems.length;
  final addressRow = totalRow + 1;
  final phoneRow = totalRow + 2;
  final websiteRow = totalRow + 3;
  final grandTotal =
      populatedItems.fold<double>(0, (total, item) => total + item.amount);
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Default Extension="png" ContentType="image/png"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/xl/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>
</Types>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/workbook.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="BOQ" sheetId="1" r:id="rId1"/></sheets><calcPr calcId="191029" fullCalcOnLoad="1"/>
</workbook>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/_rels/workbook.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''',
      ),
    )
    ..addFile(ArchiveFile.string('xl/styles.xml', _stylesXml))
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet1.xml',
        _worksheetXml(
          projectTitle: projectTitle,
          client: client,
          reference: reference,
          date: date,
          currency: currency,
          items: populatedItems,
          customColumns: activeCustomColumns,
          lastColumn: lastColumn,
          totalRow: totalRow,
          addressRow: addressRow,
          phoneRow: phoneRow,
          websiteRow: websiteRow,
          grandTotal: grandTotal,
        ),
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/_rels/sheet1.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="${_xml(companyWebsite)}" TargetMode="External"/>
</Relationships>''',
      ),
    )
    ..addFile(ArchiveFile.string('xl/drawings/drawing1.xml', _drawingXml))
    ..addFile(
      ArchiveFile.string(
        'xl/drawings/_rels/drawing1.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/ahead_africa_logo.png"/>
</Relationships>''',
      ),
    )
    ..addFile(ArchiveFile.bytes('xl/media/ahead_africa_logo.png', logoBytes));

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _worksheetXml({
  required String projectTitle,
  required String client,
  required String reference,
  required String date,
  required String currency,
  required List<BoqLineItem> items,
  required List<String> customColumns,
  required String lastColumn,
  required int totalRow,
  required int addressRow,
  required int phoneRow,
  required int websiteRow,
  required double grandTotal,
}) {
  final columnContents = <List<String>>[
    [
      'No.',
      'Reference: $reference',
      'Project: $projectTitle',
      for (var index = 0; index < items.length; index++) '${index + 1}',
    ],
    ['Description', for (final item in items) item.description],
    ['Unit', for (final item in items) item.unit],
    [
      'Quantity',
      'Date: $date',
      for (final item in items) item.quantity.toString(),
    ],
    [
      'Unit rate ($currency)',
      companyName,
      'GRAND TOTAL',
      for (final item in items) item.unitRate.toString(),
    ],
    [
      'Amount ($currency)',
      'BILL OF QUANTITIES',
      for (final item in items) item.amount.toString(),
      grandTotal.toString(),
    ],
    for (var column = 0; column < customColumns.length; column++)
      [
        customColumns[column],
        for (final item in items)
          if (column < item.customValues.length) item.customValues[column],
      ],
  ];
  // XLSX stores calculated widths rather than an AutoFit command.
  final columnWidths = [
    for (final contents in columnContents) _autoFitWidth(contents),
  ];

  final rows = <String>[
    '<row r="1" ht="58" customHeight="1">${_textCell('E1', companyName, 1)}</row>',
    '<row r="2" ht="30" customHeight="1">${_textCell('E2', 'BILL OF QUANTITIES', 1)}</row>',
    '<row r="3">${_textCell('A3', 'Reference: $reference')}${_textCell('D3', 'Date: $date')}</row>',
    '<row r="4">${_textCell('A4', 'Project: $projectTitle')}${_textCell('D4', 'Client: $client')}</row>',
    '<row r="5">${_textCell('A5', 'No.', 2)}${_textCell('B5', 'Description', 2)}${_textCell('C5', 'Unit', 2)}${_textCell('D5', 'Quantity', 2)}${_textCell('E5', 'Unit rate ($currency)', 2)}${_textCell('F5', 'Amount ($currency)', 2)}'
        '${[
      for (var index = 0; index < customColumns.length; index++)
        _textCell('${_columnName(7 + index)}5', customColumns[index], 2),
    ].join()}</row>',
  ];

  for (var index = 0; index < items.length; index++) {
    final item = items[index];
    final row = index + 6;
    final customCells = StringBuffer();
    for (var column = 0; column < customColumns.length; column++) {
      final sourceIndex = column;
      final value = sourceIndex < item.customValues.length
          ? item.customValues[sourceIndex].trim()
          : '';
      if (value.isNotEmpty) {
        customCells.write(
          _textCell('${_columnName(7 + column)}$row', value),
        );
      }
    }
    rows.add(
      '<row r="$row">${_numberCell('A$row', index + 1)}'
      '${_textCell('B$row', item.description)}'
      '${_textCell('C$row', item.unit)}'
      '${_numberCell('D$row', item.quantity)}'
      '${_numberCell('E$row', item.unitRate, 3)}'
      '${_formulaCell('F$row', 'D$row*E$row', item.amount, 3)}'
      '$customCells</row>',
    );
  }

  rows
    ..add(
      '<row r="$totalRow">${_textCell('E$totalRow', 'GRAND TOTAL', 1)}'
      '${_formulaCell('F$totalRow', 'SUM(F6:F${totalRow - 1})', grandTotal, 3)}</row>',
    )
    ..add(
        '<row r="$addressRow">${_textCell('A$addressRow', companyAddress)}</row>')
    ..add(
        '<row r="$phoneRow">${_textCell('A$phoneRow', 'Phone: $companyPhone')}</row>')
    ..add(
        '<row r="$websiteRow">${_textCell('A$websiteRow', companyWebsite)}</row>');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>
<dimension ref="A1:$lastColumn$websiteRow"/>
<sheetViews><sheetView workbookViewId="0"><pane ySplit="5" topLeftCell="A6" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
<sheetFormatPr defaultRowHeight="18"/>
<cols>${[
    for (var index = 0; index < columnWidths.length; index++)
      '<col min="${index + 1}" max="${index + 1}" width="${columnWidths[index].toStringAsFixed(2)}" bestFit="1" customWidth="1"/>',
  ].join()}</cols>
<sheetData>${rows.join()}</sheetData>
<autoFilter ref="A5:$lastColumn${totalRow - 1}"/>
<mergeCells count="3"><mergeCell ref="A$addressRow:$lastColumn$addressRow"/><mergeCell ref="A$phoneRow:$lastColumn$phoneRow"/><mergeCell ref="A$websiteRow:$lastColumn$websiteRow"/></mergeCells>
<hyperlinks><hyperlink ref="A$websiteRow" r:id="rId2" display="${_xml(companyWebsite)}"/></hyperlinks>
<pageMargins left="0.25" right="0.25" top="0.5" bottom="0.5" header="0.2" footer="0.2"/>
<pageSetup orientation="landscape" fitToWidth="1" fitToHeight="0"/>
<headerFooter><oddFooter>&amp;L${_xml(companyAddress)}&amp;C${_xml(companyPhone)}&amp;R${_xml(companyWebsite)}</oddFooter></headerFooter>
<drawing r:id="rId1"/>
</worksheet>''';
}

String _textCell(String reference, String value, [int style = 0]) =>
    '<c r="$reference" t="inlineStr" s="$style"><is><t xml:space="preserve">${_xml(value)}</t></is></c>';

String _numberCell(String reference, num value, [int style = 0]) =>
    '<c r="$reference" s="$style"><v>$value</v></c>';

String _formulaCell(
  String reference,
  String formula,
  num calculatedValue,
  int style,
) =>
    '<c r="$reference" s="$style"><f>$formula</f><v>$calculatedValue</v></c>';

double _autoFitWidth(Iterable<String> values) {
  final longestValue = values.fold<int>(
    0,
    (longest, value) =>
        value.runes.length > longest ? value.runes.length : longest,
  );
  return (longestValue + 2).clamp(10, 255).toDouble();
}

String _columnName(int index) {
  var number = index;
  final letters = StringBuffer();
  while (number > 0) {
    final remainder = (number - 1) % 26;
    letters.writeCharCode(65 + remainder);
    number = (number - 1) ~/ 26;
  }
  return String.fromCharCodes(letters.toString().codeUnits.reversed);
}

String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

const _stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="1"><numFmt numFmtId="164" formatCode="#,##0.00"/></numFmts>
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="12"/><name val="Calibri"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFD9E2F3"/></left><right style="thin"><color rgb="FFD9E2F3"/></right><top style="thin"><color rgb="FFD9E2F3"/></top><bottom style="thin"><color rgb="FFD9E2F3"/></bottom><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="4"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf><xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';

const _drawingXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<xdr:twoCellAnchor editAs="oneCell"><xdr:from><xdr:col>0</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>0</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from><xdr:to><xdr:col>2</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>2</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to>
<xdr:pic><xdr:nvPicPr><xdr:cNvPr id="1" name="AHEAD AFRICA logo" descr="AHEAD AFRICA SOLUTION LTD"/><xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr></xdr:nvPicPr><xdr:blipFill><a:blip r:embed="rId1"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill><xdr:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="3228975" cy="1076325"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/></xdr:twoCellAnchor>
</xdr:wsDr>''';
