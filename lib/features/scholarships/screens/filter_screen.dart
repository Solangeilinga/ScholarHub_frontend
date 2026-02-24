import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/countries.dart';
import '../../../core/constants/languages.dart'; // ← Import du nouveau fichier

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? filters;
  const FilterScreen({super.key, this.filters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _type;
  List<String> _levels = [];
  List<String> _countries = [];
  String? _language; // ← Utilise le code (ex: 'FR', 'EN')
  int? _deadlineDays;

  // Types de bourses
  final Map<String, String> _types = {
    'COMPLETE': 'Complète',
    'PARTIELLE': 'Partielle',
    'RECHERCHE': 'Recherche',
    'FORMATION': 'Formation'
  };

  // Niveaux d'études
  final Map<String, String> _levelsMap = {
    'BEPC': 'BEPC',
      'BACCALAUREAT': 'Baccalauréat',
      'LICENCE_1': 'Licence 1',
      'LICENCE_2': 'Licence 2',
      'LICENCE_3': 'Licence 3',
      'LICENCE': 'Licence',
      'MAITRISE': 'Maîtrise',
      'MASTER_1': 'Master 1',
      'MASTER_2': 'Master 2',
      'MASTER': 'Master',
      'DOCTORAT_1': 'Doctorat 1',
      'DOCTORAT_2': 'Doctorat 2',
      'DOCTORAT': 'Doctorat',
  };



  final _deadlines = {30: '< 30 jours', 60: '< 2 mois', 90: '< 3 mois'};

  @override
  void initState() {
    super.initState();
    if (widget.filters != null) {
      _type = widget.filters!['type'];

      final levelFilter = widget.filters!['level'];
      if (levelFilter is String) {
        _levels = [levelFilter];
      } else if (levelFilter is List) {
        _levels = List<String>.from(levelFilter);
      }

      final countryFilter = widget.filters!['countries'];
      if (countryFilter is String) {
        _countries = [countryFilter];
      } else if (countryFilter is List) {
        _countries = List<String>.from(countryFilter);
      }

      _language = widget.filters!['language']; // ← Déjà en code
      _deadlineDays = widget.filters!['deadlineDays'] != null
          ? int.parse(widget.filters!['deadlineDays'].toString())
          : null;
    }
  }

  Map<String, dynamic> get _activeFilters {
    final f = <String, dynamic>{};
    if (_type != null) f['type'] = _type;
    if (_levels.isNotEmpty) f['level'] = _levels;
    if (_countries.isNotEmpty) f['countries'] = _countries;
    if (_language != null) f['language'] = _language; // ← Envoie le code
    if (_deadlineDays != null) f['deadlineDays'] = _deadlineDays;
    return f;
  }

  void _toggleLevel(String level) {
    setState(() {
      if (_levels.contains(level)) {
        _levels.remove(level);
      } else {
        _levels.add(level);
      }
    });
  }

  void _toggleCountry(String countryCode) {
    setState(() {
      if (_countries.contains(countryCode)) {
        _countries.remove(countryCode);
      } else {
        _countries.add(countryCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _type = null;
                _levels = [];
                _countries = [];
                _language = null;
                _deadlineDays = null;
              });
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type de bourse
            _buildSection(
                'Type de bourse',
                _types.entries
                    .map((e) => FilterChip(
                          label: Text(e.value),
                          selected: _type == e.key,
                          onSelected: (v) =>
                              setState(() => _type = v ? e.key : null),
                          selectedColor:
                              AppTheme.primary.withValues(alpha: 0.15),
                        ))
                    .toList()),

            // Niveaux d'études
            _buildSection(
                'Niveaux requis',
                _levelsMap.entries
                    .map((e) => FilterChip(
                          label: Text(e.value),
                          selected: _levels.contains(e.key),
                          onSelected: (_) => _toggleLevel(e.key),
                          selectedColor:
                              AppTheme.secondary.withValues(alpha: 0.15),
                        ))
                    .toList()),

            // Pays éligibles
            _buildSection(
                'Pays éligibles',
                africanCountries
                    .map((country) => FilterChip(
                          label: Text(country.name),
                          selected: _countries.contains(country.code),
                          onSelected: (_) => _toggleCountry(country.code),
                          selectedColor: Colors.teal.withValues(alpha: 0.15),
                          avatar: Text(country.flag),
                        ))
                    .toList()),

            // Langue d'enseignement (corrigé avec le fichier languages.dart)
            _buildSection(
                'Langue',
                languages
                    .map((lang) => FilterChip(
                          label: Text(lang.name),
                          selected: _language == lang.code,
                          onSelected: (v) =>
                              setState(() => _language = v ? lang.code : null),
                          selectedColor: Colors.orange.withValues(alpha: 0.15),
                        ))
                    .toList()),

            // Deadline
            _buildSection(
                'Date limite',
                _deadlines.entries
                    .map((e) => FilterChip(
                          label: Text(e.value),
                          selected: _deadlineDays == e.key,
                          onSelected: (v) =>
                              setState(() => _deadlineDays = v ? e.key : null),
                          selectedColor:
                              AppTheme.accent.withValues(alpha: 0.15),
                        ))
                    .toList()),

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
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
      ],
    );
  }
}
