import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/cache_service.dart'; // ⚡ NOUVEAU : Import du cache
import '../models/scholarship_model.dart';

// Events
abstract class ScholarshipEvent extends Equatable {
  const ScholarshipEvent(); // ⚡ Ajout du const constructor

  @override
  List<Object?> get props => [];
}

// Permet de restaurer l'état de la liste déjà chargé (aucune requête)
class RestoreListEvent extends ScholarshipEvent {
  const RestoreListEvent();
}

class LoadScholarshipsEvent extends ScholarshipEvent {
  final Map<String, dynamic> filters;
  final bool refresh;

  const LoadScholarshipsEvent({this.filters = const {}, this.refresh = false});

  @override
  List<Object?> get props => [filters, refresh];
}

class LoadFeaturedEvent extends ScholarshipEvent {
  const LoadFeaturedEvent(); // ⚡ const
}

class LoadRecommendedEvent extends ScholarshipEvent {
  const LoadRecommendedEvent(); // ⚡ const
}

class LoadScholarshipDetailEvent extends ScholarshipEvent {
  final String id;

  const LoadScholarshipDetailEvent(this.id); // ⚡ const

  @override
  List<Object?> get props => [id];
}

class ToggleSaveEvent extends ScholarshipEvent {
  final String id;
  final bool isSaved;

  const ToggleSaveEvent({required this.id, required this.isSaved}); // ⚡ const

  @override
  List<Object?> get props => [id, isSaved];
}

class SyncSaveStateEvent extends ScholarshipEvent {
  final String id;
  final bool isSaved;

  const SyncSaveStateEvent({required this.id, required this.isSaved});

  @override
  List<Object?> get props => [id, isSaved];
}

class SearchScholarshipsEvent extends ScholarshipEvent {
  final String query;

  const SearchScholarshipsEvent(this.query); // ⚡ const

  @override
  List<Object?> get props => [query];
}

class RefreshScholarshipsSilentlyEvent extends ScholarshipEvent {
  final Map<String, dynamic> filters;

  const RefreshScholarshipsSilentlyEvent({this.filters = const {}});

  @override
  List<Object?> get props => [filters];
}

// States
abstract class ScholarshipState extends Equatable {
  const ScholarshipState(); // ⚡ const constructor

  @override
  List<Object?> get props => [];
}

class ScholarshipInitialState extends ScholarshipState {
  const ScholarshipInitialState(); // ⚡ const
}

class ScholarshipLoadingState extends ScholarshipState {
  const ScholarshipLoadingState(); // ⚡ const
}

class ScholarshipsLoadedState extends ScholarshipState {
  final List<Scholarship> scholarships;
  final List<Scholarship> featured;
  final List<Scholarship> recommended;
  final int totalPages;
  final int currentPage;

  const ScholarshipsLoadedState({
    // ⚡ const
    required this.scholarships,
    this.featured = const [],
    this.recommended = const [],
    this.totalPages = 1,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props =>
      [scholarships, featured, recommended, totalPages, currentPage];
}

class ScholarshipDetailLoadedState extends ScholarshipState {
  final Scholarship scholarship;

  const ScholarshipDetailLoadedState(this.scholarship); // ⚡ const

  @override
  List<Object?> get props => [scholarship];
}

class ScholarshipErrorState extends ScholarshipState {
  final String message;

  const ScholarshipErrorState(this.message); // ⚡ const

  @override
  List<Object?> get props => [message];
}

class ScholarshipSavedToggledState extends ScholarshipState {
  final String scholarshipId;
  final bool isSaved;

  const ScholarshipSavedToggledState(
      { // ⚡ const
      required this.scholarshipId,
      required this.isSaved});

  @override
  List<Object?> get props => [scholarshipId, isSaved];
}

// BLoC
class ScholarshipBloc extends Bloc<ScholarshipEvent, ScholarshipState> {
  final ApiClient apiClient;
  final CacheService cacheService; // ⚡ NOUVEAU : Injection du cache

  List<Scholarship> _scholarships = [];
  List<Scholarship> _featured = [];
  List<Scholarship> _recommended = [];

  // conserver la dernière liste chargée pour restaurer sans nouvelle requête
  ScholarshipsLoadedState? _lastLoadedState;

  Future<Set<String>?> _fetchSavedIds() async {
    try {
      final response = await apiClient.getSaved();
      final saved = response.data['saved'];
      if (saved is! List) return <String>{};

      return saved
          .map((item) => item is Map<String, dynamic> ? item['id'] : null)
          .whereType<String>()
          .toSet();
    } catch (_) {
      // Non bloquant: si l'utilisateur n'est pas connecté ou en erreur réseau,
      // on conserve les valeurs locales existantes.
      return null;
    }
  }

  List<Scholarship> _mergeSavedFlags(
    List<Scholarship> scholarships,
    Set<String> savedIds,
  ) {
    return scholarships
        .map((s) => s.copyWith(isSaved: savedIds.contains(s.id)))
        .toList();
  }

  ScholarshipBloc({
    required this.apiClient,
    required this.cacheService,
  }) : super(const ScholarshipInitialState()) {
    on<LoadScholarshipsEvent>(_onLoad);
    on<LoadFeaturedEvent>(_onLoadFeatured);
    on<LoadRecommendedEvent>(_onLoadRecommended);
    on<LoadScholarshipDetailEvent>(_onLoadDetail);
    on<ToggleSaveEvent>(_onToggleSave);
    on<SyncSaveStateEvent>(_onSyncSaveState);
    on<SearchScholarshipsEvent>(_onSearch);
    on<RefreshScholarshipsSilentlyEvent>(_onRefreshSilently);
    on<RestoreListEvent>(_onRestore);
  }

  Future<void> _onLoad(
    LoadScholarshipsEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    if (event.refresh) _scholarships = [];

    emit(const ScholarshipLoadingState());

    try {
      // ⚡ OPTIMISATION : Vérifier le cache d'abord
      if (!event.refresh && cacheService.isCacheValid()) {
        final cached = cacheService.getCachedScholarships();
        if (cached != null) {
          _scholarships =
              cached.map((json) => Scholarship.fromJson(json)).toList();

          emit(ScholarshipsLoadedState(
            scholarships: _scholarships,
            featured: _featured,
            recommended: _recommended,
          ));
          _lastLoadedState = ScholarshipsLoadedState(
            scholarships: _scholarships,
            featured: _featured,
            recommended: _recommended,
          );

          // ⚡ Rafraîchir en arrière-plan
          _refreshInBackground(event.filters);
          return;
        }
      }

      // Pas de cache valide → appel API
      final response = await apiClient.getScholarships(event.filters);
      final data = response.data;

      _scholarships = (data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();

      final savedIds = await _fetchSavedIds();
      if (savedIds != null) {
        _scholarships = _mergeSavedFlags(_scholarships, savedIds);
      }

      // ⚡ Sauvegarder dans le cache
      await cacheService.cacheScholarships(
        _scholarships.map((s) => s.toJson()).toList(),
      );

      final stateToEmit = ScholarshipsLoadedState(
        scholarships: _scholarships,
        featured: _featured,
        recommended: _recommended,
        totalPages: data['pagination']?['totalPages'] ?? 1,
        currentPage: data['pagination']?['page'] ?? 1,
      );
      _lastLoadedState = stateToEmit; // conserver
      emit(stateToEmit);
    } catch (e) {
      emit(const ScholarshipErrorState('Impossible de charger les bourses'));
    }
  }

  Future<void> _refreshInBackground(Map<String, dynamic>? filters) async {
    // lorsque le rafraîchissement se termine, on met à jour _lastLoadedState aussi
    try {
      final response = await apiClient.getScholarships(filters ?? {});
      final data = response.data;

      final freshScholarships = (data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();

      // Mettre à jour le cache
      await cacheService.cacheScholarships(
        freshScholarships.map((s) => s.toJson()).toList(),
      );

      // Mettre à jour la mémoire
      _scholarships = freshScholarships;

      // Mettre à jour l'UI si le bloc est toujours actif
      if (!isClosed) {
        add(RefreshScholarshipsSilentlyEvent(filters: filters ?? {}));
      }
    } catch (e) {
      print('⚠️ Rafraîchissement arrière-plan échoué: $e');
    }
  }

  Future<void> _onRefreshSilently(
    RefreshScholarshipsSilentlyEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    try {
      final response = await apiClient.getScholarships(event.filters);
      final data = response.data;

      _scholarships = (data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();

      final savedIds = await _fetchSavedIds();
      if (savedIds != null) {
        _scholarships = _mergeSavedFlags(_scholarships, savedIds);
      }

      await cacheService.cacheScholarships(
        _scholarships.map((s) => s.toJson()).toList(),
      );

      final nextState = ScholarshipsLoadedState(
        scholarships: _scholarships,
        featured: _featured,
        recommended: _recommended,
        totalPages: data['pagination']?['totalPages'] ?? 1,
        currentPage: data['pagination']?['page'] ?? 1,
      );
      _lastLoadedState = nextState;
      emit(nextState);
    } catch (e) {
      print('⚠️ Rafraîchissement silencieux échoué: $e');
    }
  }

  Future<void> _onLoadFeatured(
    LoadFeaturedEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    try {
      final response = await apiClient.getFeaturedScholarships();
      _featured = (response.data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();

      final savedIds = await _fetchSavedIds();
      if (savedIds != null) {
        _featured = _mergeSavedFlags(_featured, savedIds);
      }

      // Émettre seulement si on est dans un état chargé
      if (state is ScholarshipsLoadedState) {
        final current = state as ScholarshipsLoadedState;
        final nextState = ScholarshipsLoadedState(
          scholarships: current.scholarships,
          featured: _featured,
          recommended: _recommended,
          totalPages: current.totalPages,
          currentPage: current.currentPage,
        );
        _lastLoadedState = nextState;
        emit(nextState);
      }
    } catch (e) {
      // Ne pas émettre d'erreur pour les featured, juste logger
      print('⚠️ Erreur chargement featured: $e');
    }
  }

  Future<void> _onLoadRecommended(
    LoadRecommendedEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    try {
      final response = await apiClient.getRecommended();
      _recommended = (response.data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();

      final savedIds = await _fetchSavedIds();
      if (savedIds != null) {
        _recommended = _mergeSavedFlags(_recommended, savedIds);
      }

      if (state is ScholarshipsLoadedState) {
        final current = state as ScholarshipsLoadedState;
        final nextState = ScholarshipsLoadedState(
          scholarships: current.scholarships,
          featured: _featured,
          recommended: _recommended,
          totalPages: current.totalPages,
          currentPage: current.currentPage,
        );
        _lastLoadedState = nextState;
        emit(nextState);
      }
    } catch (_) {
      // Ignorer silencieusement
    }
  }

  Future<void> _onLoadDetail(
    LoadScholarshipDetailEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    emit(const ScholarshipLoadingState());

    try {
      final response = await apiClient.getScholarship(event.id);
      final scholarship = Scholarship.fromJson(response.data['scholarship']);

      emit(ScholarshipDetailLoadedState(scholarship));
    } catch (_) {
      emit(const ScholarshipErrorState('Impossible de charger la bourse'));
    }
  }

  Future<void> _onRestore(
    RestoreListEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    if (_lastLoadedState != null) {
      emit(_lastLoadedState!);
    }
  }

  Future<void> _onToggleSave(
    ToggleSaveEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    final hadLoadedStateBeforeToggle = _lastLoadedState != null;
    final newIsSaved = !event.isSaved;

    // 1. Émettre immédiatement → UI réactive
    emit(ScholarshipSavedToggledState(
      scholarshipId: event.id,
      isSaved: newIsSaved,
    ));

    try {
      // 2. Appel API silencieux
      if (event.isSaved) {
        await apiClient.unsaveScholarship(event.id);
      } else {
        await apiClient.saveScholarship(event.id);
      }

      // 3. Mettre à jour les listes locales
      void updateList(List<Scholarship> list) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].id == event.id) {
            list[i] = list[i].copyWith(isSaved: newIsSaved);
          }
        }
      }

      updateList(_scholarships);
      updateList(_featured);
      updateList(_recommended);

      // 4. Mettre à jour le cache si nécessaire
      if (cacheService.isCacheValid()) {
        await cacheService.cacheScholarships(
          _scholarships.map((s) => s.toJson()).toList(),
        );
      }

      if (hadLoadedStateBeforeToggle) {
        final nextState = ScholarshipsLoadedState(
          scholarships: _scholarships,
          featured: _featured,
          recommended: _recommended,
        );
        _lastLoadedState = nextState;
        emit(nextState);
      }
    } catch (_) {
      // Rollback en cas d'erreur
      emit(ScholarshipSavedToggledState(
        scholarshipId: event.id,
        isSaved: event.isSaved,
      ));
    }
  }

  Future<void> _onSyncSaveState(
    SyncSaveStateEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    void updateList(List<Scholarship> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == event.id) {
          list[i] = list[i].copyWith(isSaved: event.isSaved);
        }
      }
    }

    updateList(_scholarships);
    updateList(_featured);
    updateList(_recommended);

    if (cacheService.isCacheValid()) {
      await cacheService.cacheScholarships(
        _scholarships.map((s) => s.toJson()).toList(),
      );
    }

    emit(ScholarshipSavedToggledState(
      scholarshipId: event.id,
      isSaved: event.isSaved,
    ));

    if (_lastLoadedState != null) {
      final nextState = ScholarshipsLoadedState(
        scholarships: _scholarships,
        featured: _featured,
        recommended: _recommended,
      );
      _lastLoadedState = nextState;
      emit(nextState);
    }
  }

  Future<void> _onSearch(
    SearchScholarshipsEvent event,
    Emitter<ScholarshipState> emit,
  ) async {
    add(LoadScholarshipsEvent(
      filters: {'search': event.query},
      refresh: true,
    ));
  }
}
