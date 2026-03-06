import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/scholarship_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../shared/widgets/scholarship_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';

// ⚡ Constantes en dehors du widget
const _types = ['COMPLETE', 'PARTIELLE', 'RECHERCHE', 'FORMATION'];
const _levels = [
  'BEPC', 'BACCALAUREAT', 'LICENCE_1', 'LICENCE_2', 'LICENCE_3',
  'LICENCE', 'MAITRISE', 'MASTER_1', 'MASTER_2', 'MASTER',
  'DOCTORAT_1', 'DOCTORAT_2', 'DOCTORAT'
];

const _typeLabels = {
  'COMPLETE': 'Complète',
  'PARTIELLE': 'Partielle',
  'RECHERCHE': 'Recherche',
  'FORMATION': 'Formation',
};

String _typeLabel(String type) => _typeLabels[type] ?? type;

class ScholarshipListScreen extends StatefulWidget {
  const ScholarshipListScreen({super.key});

  @override
  State<ScholarshipListScreen> createState() => _ScholarshipListScreenState();
}

class _ScholarshipListScreenState extends State<ScholarshipListScreen> {
  late final TextEditingController _searchCtrl;
  Map<String, dynamic> _filters = {};
  String? _selectedType;
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(_onSearchChanged); // ⚡ Listener pour les changements
    context.read<ScholarshipBloc>().add(LoadScholarshipsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Optionnel : recherche automatique après un délai
    // À implémenter si besoin
  }

  void _search() {
    final filters = <String, dynamic>{};
    if (_searchCtrl.text.isNotEmpty) filters['search'] = _searchCtrl.text;
    if (_selectedType != null) filters['type'] = _selectedType;
    if (_selectedLevel != null) filters['level'] = _selectedLevel;
    
    // ⚡ Évite de rebuild si les filtres sont identiques
    if (_filters.toString() == filters.toString()) return;
    
    setState(() => _filters = filters);
    context.read<ScholarshipBloc>().add(LoadScholarshipsEvent(filters: filters, refresh: true));
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedLevel = null;
      _searchCtrl.clear();
      _filters = {};
    });
    context.read<ScholarshipBloc>().add(LoadScholarshipsEvent(refresh: true));
  }

  void _selectType(String? type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _search();
  }

  void _selectLevel(String? level) {
    if (_selectedLevel == level) return;
    setState(() => _selectedLevel = level);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Explorer les bourses'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchBar(
              controller: _searchCtrl,
              onSearch: _search,
            ), // ⚡ Widget extrait
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _FilterBar(
            filters: _filters,
            selectedType: _selectedType,
            selectedLevel: _selectedLevel,
            onClear: _clearFilters,
            onSelectType: _selectType,
            onSelectLevel: _selectLevel,
          ), // ⚡ Widget extrait
          const Divider(height: 1),

          // Results
          Expanded(
            child: _ResultsList(
              filters: _filters,
              onClearFilters: _clearFilters,
            ), // ⚡ Widget extrait
          ),
        ],
      ),
    );
  }
}

// ⚡ Barre de recherche extraite
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        hintText: 'Rechercher par nom, domaine...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _SearchSuffix(
          controller: controller,
          onSearch: onSearch,
        ),
      ),
    );
  }
}

// ⚡ Suffixe de recherche extrait
class _SearchSuffix extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const _SearchSuffix({
    required this.controller,
    required this.onSearch,
  });

  @override
  State<_SearchSuffix> createState() => _SearchSuffixState();
}

class _SearchSuffixState extends State<_SearchSuffix> {
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasText)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              widget.controller.clear();
              widget.onSearch();
            },
          ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: widget.onSearch,
        ),
      ],
    );
  }
}

// ⚡ Barre de filtres extraite
class _FilterBar extends StatelessWidget {
  final Map<String, dynamic> filters;
  final String? selectedType;
  final String? selectedLevel;
  final VoidCallback onClear;
  final Function(String?) onSelectType;
  final Function(String?) onSelectLevel;

  const _FilterBar({
    required this.filters,
    required this.selectedType,
    required this.selectedLevel,
    required this.onClear,
    required this.onSelectType,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppTheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (filters.isNotEmpty)
            const _ClearFilterChip(), // ⚡ Widget constant
          ..._types.map((type) => _TypeFilterChip(
            type: type,
            label: _typeLabel(type),
            isSelected: selectedType == type,
            onSelected: onSelectType,
          )),
          ..._levels.map((level) => _LevelFilterChip(
            level: level,
            isSelected: selectedLevel == level,
            onSelected: onSelectLevel,
          )),
        ],
      ),
    );
  }
}

// ⚡ Chip effacer (constant)
class _ClearFilterChip extends StatelessWidget {
  const _ClearFilterChip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: const Text('Effacer filtres'),
        onPressed: () {
          final state = context.findAncestorStateOfType<_ScholarshipListScreenState>();
          state?._clearFilters();
        },
        backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppTheme.accent),
      ),
    );
  }
}

// ⚡ Chip de type extrait
class _TypeFilterChip extends StatelessWidget {
  final String type;
  final String label;
  final bool isSelected;
  final Function(String?) onSelected;

  const _TypeFilterChip({
    required this.type,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => onSelected(selected ? type : null),
        selectedColor: AppTheme.primary.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primary,
      ),
    );
  }
}

// ⚡ Chip de niveau extrait
class _LevelFilterChip extends StatelessWidget {
  final String level;
  final bool isSelected;
  final Function(String?) onSelected;

  const _LevelFilterChip({
    required this.level,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(formatLevelLabel(level)),
        selected: isSelected,
        onSelected: (selected) => onSelected(selected ? level : null),
        selectedColor: AppTheme.secondary.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.secondary,
      ),
    );
  }
}

// ⚡ Liste des résultats extraite
class _ResultsList extends StatelessWidget {
  final Map<String, dynamic> filters;
  final VoidCallback onClearFilters;

  const _ResultsList({
    required this.filters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScholarshipBloc, ScholarshipState>(
      buildWhen: (prev, curr) =>
          curr is ScholarshipsLoadedState ||
          curr is ScholarshipLoadingState ||
          curr is ScholarshipErrorState,
      builder: (context, state) {
        if (state is ScholarshipLoadingState) {
          return const ShimmerList();
        }

        if (state is ScholarshipErrorState) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<ScholarshipBloc>().add(LoadScholarshipsEvent()),
          );
        }

        if (state is ScholarshipsLoadedState) {
          if (state.scholarships.isEmpty) {
            return _EmptyView(
              hasFilters: filters.isNotEmpty,
              onClearFilters: onClearFilters,
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              context.read<ScholarshipBloc>().add(
                LoadScholarshipsEvent(filters: filters, refresh: true),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.scholarships.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ScholarshipCard(
                  key: ValueKey(state.scholarships[i].id),
                  scholarship: state.scholarships[i],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ⚡ Vue d'erreur extraite
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ⚡ Vue vide extraite
class _EmptyView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyView({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune bourse trouvée',
            style: TextStyle(
                fontSize: AppTheme.fsTitleLg,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez d\'autres critères de recherche',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            ElevatedButton(
              onPressed: onClearFilters,
              child: const Text('Effacer les filtres'),
            ),
        ],
      ),
    );
  }
}
