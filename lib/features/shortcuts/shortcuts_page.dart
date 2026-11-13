import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';
import '../../data/shortcuts_data.dart';

class ShortcutsPage extends StatefulWidget {
  const ShortcutsPage({
    super.key,
    required this.preferences,
    this.initialQuery = '',
    this.revision = 0,
  });

  final SharedPreferences preferences;
  final String initialQuery;
  final int revision;

  @override
  State<ShortcutsPage> createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  late final TextEditingController _search;
  String _category = 'All';
  bool _onlyFavorites = false;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _loadFavorites();
  }

  @override
  void didUpdateWidget(covariant ShortcutsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _search.text = widget.initialQuery;
      _category = 'All';
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final values =
          widget.preferences.getStringList('shortcut_favorites')?.toSet() ??
              <String>{};
      if (mounted) setState(() => _favorites = values);
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not load favorites: $error');
      }
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> entry) async {
    final id =
        '${entry['category']}:${_keys(entry).join('|')}:${entry['action']}';
    final updated = {..._favorites};
    if (!updated.add(id)) updated.remove(id);
    try {
      if (!await widget.preferences.setStringList(
        'shortcut_favorites',
        updated.toList(),
      )) {
        throw StateError('The favorite could not be saved.');
      }
      if (mounted) setState(() => _favorites = updated);
    } catch (error) {
      if (mounted) {
        showToolkitMessage(context, 'Could not save favorite: $error');
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final entries = shortcutsData.where((entry) {
      final id =
          '${entry['category']}:${_keys(entry).join('|')}:${entry['action']}';
      final text = entry.values.join(' ').toLowerCase();
      return (_category == 'All' || entry['category'] == _category) &&
          (query.isEmpty || text.contains(query)) &&
          (!_onlyFavorites || _favorites.contains(id));
    }).toList();
    return PageScaffold(
      title: 'Keyboard Shortcuts',
      subtitle:
          '${shortcutsData.length} Windows shortcuts · learn and practice',
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search shortcuts',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final category in ['All', ...shortcutCategories])
              FilterChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
            FilterChip(
              label: const Text('Favorites'),
              selected: _onlyFavorites,
              onSelected: (value) => setState(() => _onlyFavorites = value),
            ),
          ],
        ),
        if (entries.isEmpty)
          const Card(child: ListTile(title: Text('No matching shortcuts.')))
        else
          for (final entry in entries) _shortcutCard(entry),
      ],
    );
  }

  Widget _shortcutCard(Map<String, dynamic> entry) {
    final keys = _keys(entry);
    final favoriteId =
        '${entry['category']}:${keys.join('|')}:${entry['action']}';
    final isFavorite = _favorites.contains(favoriteId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                for (final chord in _chords(keys))
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(chord.join(' + ')),
                  ),
              ],
            ),
            Text(entry['action'] as String,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(entry['desc_sw'] as String),
            Text(entry['desc_en'] as String,
                style: const TextStyle(color: ToolkitColors.muted)),
            Row(
              children: [
                Text(entry['category'] as String,
                    style: const TextStyle(color: ToolkitColors.muted)),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy shortcut',
                  onPressed: () => copyText(context, _display(keys)),
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                  onPressed: () => _toggleFavorite(entry),
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                ),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _PracticeDialog(entry: entry),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Practice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _keys(Map<String, dynamic> entry) {
  final value = entry['keys'];
  return value is List ? value.cast<String>() : (value as String).split(' + ');
}

List<List<String>> _chords(List<String> keys) {
  const modifiers = {'Ctrl', 'Alt', 'Shift', 'Win'};
  final result = <List<String>>[];
  var chord = <String>[];
  for (final key in keys) {
    if (modifiers.contains(key) &&
        chord.any((part) => !modifiers.contains(part))) {
      result.add(chord);
      chord = [];
    }
    chord.add(key);
    if (!modifiers.contains(key)) {
      result.add(chord);
      chord = [];
    }
  }
  if (chord.isNotEmpty) result.add(chord);
  return result.isEmpty ? [keys] : result;
}

String _display(List<String> keys) =>
    _chords(keys).map((chord) => chord.join(' + ')).join(', then ');

class _PracticeDialog extends StatefulWidget {
  const _PracticeDialog({required this.entry});

  final Map<String, dynamic> entry;

  @override
  State<_PracticeDialog> createState() => _PracticeDialogState();
}

class _PracticeDialogState extends State<_PracticeDialog> {
  final _focus = FocusNode();
  var _chordIndex = 0;
  var _complete = false;
  String _status = 'Tap the practice area, then press the shortcut.';

  void _keyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final keys = _keys(widget.entry);
    final chords = _chords(keys);
    final pressed = <String>{};
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed) pressed.add('Ctrl');
    if (keyboard.isAltPressed) pressed.add('Alt');
    if (keyboard.isShiftPressed) pressed.add('Shift');
    if (keyboard.isMetaPressed) pressed.add('Win');
    final key = _keyName(event.logicalKey);
    if (key != null && !{'Ctrl', 'Alt', 'Shift', 'Win'}.contains(key)) {
      pressed.add(key);
    }
    final expected = chords[_chordIndex].toSet();
    final match =
        expected.length == pressed.length && expected.every(pressed.contains);
    final finalChord = _chordIndex == chords.length - 1;
    if (match && !finalChord) _chordIndex++;
    if (!match &&
        key != null &&
        !{'Ctrl', 'Alt', 'Shift', 'Win'}.contains(key)) {
      _chordIndex = 0;
    }
    setState(() {
      _complete = match && finalChord;
      _status = _complete
          ? 'Correct! ${_display(keys)}'
          : match
              ? 'Good. Now press ${chords[_chordIndex].join(' + ')}.'
              : 'Try ${_display(keys)}.';
    });
  }

  String? _keyName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) return 'Up';
    if (key == LogicalKeyboardKey.arrowDown) return 'Down';
    if (key == LogicalKeyboardKey.arrowLeft) return 'Left';
    if (key == LogicalKeyboardKey.arrowRight) return 'Right';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.pageUp) return 'PageUp';
    if (key == LogicalKeyboardKey.pageDown) return 'PageDown';
    final label = key.keyLabel;
    if (label.length == 1) return label.toUpperCase();
    if (RegExp(r'^F\d+$').hasMatch(label)) return label.toUpperCase();
    return null;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys(widget.entry);
    return AlertDialog(
      title: Text('Practice: ${widget.entry['action']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_display(keys), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          KeyboardListener(
            focusNode: _focus,
            onKeyEvent: _keyEvent,
            child: InkWell(
              onTap: _focus.requestFocus,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _complete
                        ? ToolkitColors.primary
                        : ToolkitColors.secondary,
                    width: 2,
                  ),
                ),
                child: Text(_status, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _chordIndex = 0;
            _complete = false;
            _status = 'Tap the practice area, then press the shortcut.';
            _focus.requestFocus();
          }),
          child: const Text('Try again'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
