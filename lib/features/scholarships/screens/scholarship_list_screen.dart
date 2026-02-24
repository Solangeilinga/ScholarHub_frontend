import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/scholarship_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/scholarship_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class ScholarshipListScreen extends StatefulWidget {
  const ScholarshipListScreen({super.key});

  @override
  State<ScholarshipListScreen> createState() => _ScholarshipListScreenState();
}

class _ScholarshipListScreenState extends State<ScholarshipListScreen> {
  final _searchCtrl = TextEditingController();
  Map<String, dynamic> _filters = {};
  String? _selectedType;
  String? _selectedLevel;

  final _types = ['COMPLETE', 'PARTIELLE', 'RECHERCHE', 'FORMATION'];
  final _levels = ['BEPC','BACCALAUREAT','LICENCE 1', 'LICENCE 2', 'LICENCE 3', 'LICENCE', 'MAITRISE', 'MASTER 1', 'MASTER 2', 'MASTER', 'DOCTORAT 1', 'DOCTORAT 2', 'DOCTORAT'];

  @override
  void initState() {
    super.initState();
    context.read<ScholarshipBloc>().add(LoadScholarshipsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final filters = <String, dynamic>{};
    if (_searchCtrl.text.isNotEmpty) filters['search'] = _searchCtrl.text;
    if (_selectedType != null) filters['type'] = _selectedType;
    if (_selectedLevel != null) filters['level'] = _selectedLevel;
    _filters = filters;
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

  String _typeLabel(String type) {
    const labels = {
      'COMPLETE': 'Complète', 'PARTIELLE': 'Partielle',
      'RECHERCHE': 'Recherche', 'FORMATION': 'Formation',
    };
    return labels[type] ?? type;
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
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, domaine...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchCtrl.clear(); _search(); },
                      ),
                    IconButton(icon: const Icon(Icons.search), onPressed: _search),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 48,
            color: AppTheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (_filters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: const Text('Effacer filtres'),
                      onPressed: _clearFilters,
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppTheme.accent),
                    ),
                  ),
                ..._types.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeLabel(type)),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() => _selectedType = selected ? type : null);
                      _search();
                    },
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primary,
                  ),
                )),
                ..._levels.map((level) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(level),
                    selected: _selectedLevel == level,
                    onSelected: (selected) {
                      setState(() => _selectedLevel = selected ? level : null);
                      _search();
                    },
                    selectedColor: AppTheme.secondary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.secondary,
                  ),
                )),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(
            child: BlocBuilder<ScholarshipBloc, ScholarshipState>(
              buildWhen: (prev, curr) =>
                  curr is ScholarshipsLoadedState ||
                  curr is ScholarshipLoadingState ||
                  curr is ScholarshipErrorState,
              builder: (context, state) {
                if (state is ScholarshipLoadingState) return const ShimmerList();

                if (state is ScholarshipErrorState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<ScholarshipBloc>().add(LoadScholarshipsEvent()),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ScholarshipsLoadedState) {
                  if (state.scholarships.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text('Aucune bourse trouvée',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Essayez d\'autres critères de recherche',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 24),
                          if (_filters.isNotEmpty)
                            ElevatedButton(onPressed: _clearFilters, child: const Text('Effacer les filtres')),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () async {
                      context.read<ScholarshipBloc>().add(
                        LoadScholarshipsEvent(filters: _filters, refresh: true),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.scholarships.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScholarshipCard(scholarship: state.scholarships[i]),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}