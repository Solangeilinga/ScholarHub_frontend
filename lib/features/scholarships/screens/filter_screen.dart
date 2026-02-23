import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? filters;
  const FilterScreen({super.key, this.filters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _type;
  String? _level;
  String? _country;
  String? _language;
  int? _deadlineDays;

  final _types = {'COMPLETE': 'Complète', 'PARTIELLE': 'Partielle', 'RECHERCHE': 'Recherche', 'ECHANGE': 'Échange'};
  final _levels = {'LICENCE': 'Licence', 'MASTER': 'Master', 'DOCTORAT': 'Doctorat', 'POSTDOC': 'Post-Doc'};
  final _languages = ['Français', 'Anglais', 'Arabe', 'Portugais'];
  final _deadlines = {30: '< 30 jours', 60: '< 2 mois', 90: '< 3 mois'};

  @override
  void initState() {
    super.initState();
    if (widget.filters != null) {
      _type = widget.filters!['type'];
      _level = widget.filters!['level'];
      _country = widget.filters!['country'];
      _language = widget.filters!['language'];
      _deadlineDays = widget.filters!['deadlineDays'] != null ? int.parse(widget.filters!['deadlineDays'].toString()) : null;
    }
  }

  Map<String, dynamic> get _activeFilters {
    final f = <String, dynamic>{};
    if (_type != null) f['type'] = _type;
    if (_level != null) f['level'] = _level;
    if (_country != null) f['country'] = _country;
    if (_language != null) f['language'] = _language;
    if (_deadlineDays != null) f['deadlineDays'] = _deadlineDays;
    return f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres'),
        actions: [
          TextButton(
            onPressed: () { setState(() { _type = null; _level = null; _country = null; _language = null; _deadlineDays = null; }); },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Type de bourse', _types.entries.map((e) => FilterChip(
              label: Text(e.value),
              selected: _type == e.key,
              onSelected: (v) => setState(() => _type = v ? e.key : null),
              selectedColor: AppTheme.primary.withOpacity(0.15),
            )).toList()),

            _buildSection('Niveau d\'études', _levels.entries.map((e) => FilterChip(
              label: Text(e.value),
              selected: _level == e.key,
              onSelected: (v) => setState(() => _level = v ? e.key : null),
              selectedColor: AppTheme.secondary.withOpacity(0.15),
            )).toList()),

            _buildSection('Langue', _languages.map((l) => FilterChip(
              label: Text(l),
              selected: _language == l,
              onSelected: (v) => setState(() => _language = v ? l : null),
              selectedColor: Colors.orange.withOpacity(0.15),
            )).toList()),

            _buildSection('Deadline', _deadlines.entries.map((e) => FilterChip(
              label: Text(e.value),
              selected: _deadlineDays == e.key,
              onSelected: (v) => setState(() => _deadlineDays = v ? e.key : null),
              selectedColor: AppTheme.accent.withOpacity(0.15),
            )).toList()),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => context.pop(_activeFilters),
          child: Text('Appliquer les filtres (${_activeFilters.length})'),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
      ],
    );
  }
}
