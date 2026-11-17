import 'dart:typed_data';

import 'package:docx_creator/docx_creator.dart';

import '../../core/company_branding.dart';

const proposalContentSections = <(String, String)>[
  ('Background / Problem', 'Background / Problem'),
  ('Proposed solution / Scope of work', 'Proposed solution / Scope of work'),
  ('Deliverables', 'Deliverables'),
  ('Implementation plan / Timeline', 'Implementation plan / Timeline'),
  ('Investment / Cost', 'Investment / Cost'),
  ('Payment terms', 'Payment terms'),
  ('Proposal validity', 'Proposal validity'),
  ('Assumptions / Exclusions', 'Assumptions / Exclusions'),
];

class ProposalAttachment {
  const ProposalAttachment({
    required this.name,
    required this.bytes,
    required this.extension,
    required this.section,
    this.outputName,
  });

  final String name;
  final Uint8List bytes;
  final String extension;
  final String section;
  final String? outputName;

  bool get isImage => const {'gif', 'jpeg', 'jpg', 'png'}.contains(extension);
}

Future<Uint8List> createProposalDocument({
  required Map<String, String> values,
  required Uint8List logoBytes,
  List<ProposalAttachment> attachments = const [],
  Map<String, String> sectionLabels = const {},
  Set<String> hiddenSections = const {},
}) async {
  final builder = DocxDocumentBuilder()
    ..section(
      pageSize: DocxPageSize.a4,
      footer: DocxFooter(
        children: [
          DocxParagraph(
            align: DocxAlign.center,
            children: [
              DocxText(
                '$companyAddress | $companyPhone | ',
                fontSize: 8,
                color: DocxColor.darkGray,
              ),
              DocxText(
                companyWebsite,
                fontSize: 8,
                color: DocxColor.blue,
                href: companyWebsite,
                decorations: [DocxTextDecoration.underline],
              ),
            ],
          ),
        ],
      ),
    )
    ..add(
      DocxImage(
        bytes: logoBytes,
        extension: 'png',
        width: 210,
        height: 70,
        altText: companyName,
      ),
    )
    ..h1('TECHNICAL PROPOSAL')
    ..h2(values['Proposal title']?.trim().isNotEmpty == true
        ? values['Proposal title']!.trim()
        : 'Proposal');

  final metadata = <List<String>>[
    ['Client', values['Client'] ?? ''],
    ['Client contact', values['Client contact'] ?? ''],
    ['Site / location', values['Site / location'] ?? ''],
    ['Reference', values['Reference'] ?? ''],
    ['Date', values['Date'] ?? ''],
    ['Prepared by', values['Technician name'] ?? ''],
  ].where((row) => row[1].trim().isNotEmpty).toList();
  if (metadata.isNotEmpty) builder.table(metadata, hasHeader: false);

  for (final section in proposalContentSections) {
    final sectionKey = section.$2;
    if (hiddenSections.contains(sectionKey)) continue;

    final value = values[section.$2]?.trim() ?? '';
    final sectionAttachments = attachments
        .where((attachment) => attachment.section == sectionKey)
        .toList();
    if (value.isEmpty && sectionAttachments.isEmpty) continue;

    builder.h2(sectionLabels[sectionKey] ?? section.$1);
    if (value.isNotEmpty) builder.p(value);
    for (final attachment in sectionAttachments) {
      if (attachment.isImage) {
        builder
          ..p(attachment.name)
          ..image(
            DocxImage(
              bytes: attachment.bytes,
              extension: attachment.extension,
              width: 450,
              height: 300,
              altText: attachment.name,
            ),
          );
      } else {
        builder.add(
          DocxParagraph(
            children: [
              DocxText(
                attachment.name,
                href: attachment.outputName,
              ),
            ],
          ),
        );
      }
    }
  }

  return DocxExporter().exportToBytes(builder.build());
}
