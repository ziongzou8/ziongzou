import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../boq/boq_generator_page.dart';
import '../knowledge/knowledge_page.dart';
import '../mobile/mobile_page.dart';
import '../proposal/proposal_generator_page.dart';
import '../report/report_generator_page.dart';
import '../scripts/scripts_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({
    super.key,
    required this.preferences,
    required this.initialTab,
    required this.initialQuery,
    required this.revision,
  });

  final SharedPreferences preferences;
  final int initialTab;
  final String initialQuery;
  final int revision;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  static const _tabs = [
    'Scripts',
    'Mobile',
    'Knowledge',
    'Reports',
    'Proposal',
    'BOQ',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void didUpdateWidget(covariant ToolsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _controller.index = widget.initialTab.clamp(0, _tabs.length - 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Material(
            color: ToolkitColors.background,
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              tabs: [
                for (final tab in _tabs) Tab(text: tab),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                ScriptsPage(initialQuery: widget.initialQuery),
                MobilePage(initialQuery: widget.initialQuery),
                KnowledgePage(initialQuery: widget.initialQuery),
                ReportGeneratorPage(preferences: widget.preferences),
                ProposalGeneratorPage(preferences: widget.preferences),
                BoqGeneratorPage(preferences: widget.preferences),
              ],
            ),
          ),
        ],
      );
}
