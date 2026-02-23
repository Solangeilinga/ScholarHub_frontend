import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../models/scholarship_model.dart';

// Events
abstract class ScholarshipEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadScholarshipsEvent extends ScholarshipEvent {
  final Map<String, dynamic> filters;
  final bool refresh;
  LoadScholarshipsEvent({this.filters = const {}, this.refresh = false});
  @override List<Object?> get props => [filters, refresh];
}
class LoadFeaturedEvent extends ScholarshipEvent {}
class LoadRecommendedEvent extends ScholarshipEvent {}
class LoadScholarshipDetailEvent extends ScholarshipEvent {
  final String id;
  LoadScholarshipDetailEvent(this.id);
  @override List<Object?> get props => [id];
}
class ToggleSaveEvent extends ScholarshipEvent {
  final String id;
  final bool isSaved;
  ToggleSaveEvent({required this.id, required this.isSaved});
  @override List<Object?> get props => [id, isSaved];
}
class SearchScholarshipsEvent extends ScholarshipEvent {
  final String query;
  SearchScholarshipsEvent(this.query);
  @override List<Object?> get props => [query];
}

// States
abstract class ScholarshipState extends Equatable {
  @override List<Object?> get props => [];
}
class ScholarshipInitialState extends ScholarshipState {}
class ScholarshipLoadingState extends ScholarshipState {}
class ScholarshipsLoadedState extends ScholarshipState {
  final List<Scholarship> scholarships;
  final List<Scholarship> featured;
  final List<Scholarship> recommended;
  final int totalPages;
  final int currentPage;

  ScholarshipsLoadedState({
    required this.scholarships,
    this.featured = const [],
    this.recommended = const [],
    this.totalPages = 1,
    this.currentPage = 1,
  });
  @override List<Object?> get props => [scholarships, featured, recommended];
}
class ScholarshipDetailLoadedState extends ScholarshipState {
  final Scholarship scholarship;
  ScholarshipDetailLoadedState(this.scholarship);
  @override List<Object?> get props => [scholarship];
}
class ScholarshipErrorState extends ScholarshipState {
  final String message;
  ScholarshipErrorState(this.message);
  @override List<Object?> get props => [message];
}

// ← État ajouté pour la sauvegarde réactive
class ScholarshipSavedToggledState extends ScholarshipState {
  final String scholarshipId;
  final bool isSaved;
  ScholarshipSavedToggledState({required this.scholarshipId, required this.isSaved});
  @override List<Object?> get props => [scholarshipId, isSaved];
}

// BLoC
class ScholarshipBloc extends Bloc<ScholarshipEvent, ScholarshipState> {
  final ApiClient apiClient;
  List<Scholarship> _scholarships = [];
  List<Scholarship> _featured = [];
  List<Scholarship> _recommended = [];

  ScholarshipBloc({required this.apiClient}) : super(ScholarshipInitialState()) {
    on<LoadScholarshipsEvent>(_onLoad);
    on<LoadFeaturedEvent>(_onLoadFeatured);
    on<LoadRecommendedEvent>(_onLoadRecommended);
    on<LoadScholarshipDetailEvent>(_onLoadDetail);
    on<ToggleSaveEvent>(_onToggleSave);
    on<SearchScholarshipsEvent>(_onSearch);
  }

  Future<void> _onLoad(LoadScholarshipsEvent event, Emitter<ScholarshipState> emit) async {
    if (event.refresh) _scholarships = [];
    emit(ScholarshipLoadingState());
    try {
      final response = await apiClient.getScholarships(event.filters);
      final data = response.data;
      _scholarships = (data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();
      emit(ScholarshipsLoadedState(
        scholarships: _scholarships,
        featured: _featured,
        recommended: _recommended,
        totalPages: data['pagination']['totalPages'],
        currentPage: data['pagination']['page'],
      ));
    } catch (e) {
      emit(ScholarshipErrorState('Impossible de charger les bourses'));
    }
  }

  Future<void> _onLoadFeatured(LoadFeaturedEvent event, Emitter<ScholarshipState> emit) async {
    try {
      final response = await apiClient.getFeaturedScholarships();
      _featured = (response.data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();
      emit(ScholarshipsLoadedState(
        scholarships: _scholarships,
        featured: _featured,
        recommended: _recommended,
      ));
    } catch (e) {
      emit(ScholarshipErrorState('Erreur chargement bourses vedettes'));
    }
  }

  Future<void> _onLoadRecommended(LoadRecommendedEvent event, Emitter<ScholarshipState> emit) async {
    try {
      final response = await apiClient.getRecommended();
      _recommended = (response.data['scholarships'] as List)
          .map((s) => Scholarship.fromJson(s))
          .toList();
      emit(ScholarshipsLoadedState(
        scholarships: _scholarships,
        featured: _featured,
        recommended: _recommended,
      ));
    } catch (_) {}
  }

  Future<void> _onLoadDetail(LoadScholarshipDetailEvent event, Emitter<ScholarshipState> emit) async {
    emit(ScholarshipLoadingState());
    try {
      final response = await apiClient.getScholarship(event.id);
      emit(ScholarshipDetailLoadedState(Scholarship.fromJson(response.data['scholarship'])));
    } catch (_) {
      emit(ScholarshipErrorState('Impossible de charger la bourse'));
    }
  }

  Future<void> _onToggleSave(ToggleSaveEvent event, Emitter<ScholarshipState> emit) async {
  final newIsSaved = !event.isSaved;

  // 1. Émettre immédiatement → UI réactive sans reload
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

    // 3. Mettre à jour les listes locales en mémoire SANS réémettre
    void updateList(List<Scholarship> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == event.id) {
          list[i].isSaved = newIsSaved;
        }
      }
    }
    updateList(_scholarships);
    updateList(_featured);
    updateList(_recommended);

    // ← Ne pas réémettre ScholarshipsLoadedState ici !

  } catch (_) {
    // 4. Rollback uniquement le bookmark en cas d'erreur
    emit(ScholarshipSavedToggledState(
      scholarshipId: event.id,
      isSaved: event.isSaved,
    ));
  }
}

  Future<void> _onSearch(SearchScholarshipsEvent event, Emitter<ScholarshipState> emit) async {
    add(LoadScholarshipsEvent(filters: {'search': event.query}, refresh: true));
  }
}