import '../../domain/entities/study_group_entity.dart';

enum StudyGroupStatus { initial, loading, loaded, error }

class StudyGroupState {
  final StudyGroupStatus status;
  final List<StudyGroupEntity> groups;
  final String? selectedSubjectFilter;
  final String? searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const StudyGroupState({
    this.status = StudyGroupStatus.initial,
    this.groups = const [],
    this.selectedSubjectFilter,
    this.searchQuery,
    this.errorMessage,
    this.successMessage,
  });

  List<StudyGroupEntity> get filteredGroups {
    return groups.where((g) {
      final matchSubject = selectedSubjectFilter == null ||
          selectedSubjectFilter!.isEmpty ||
          selectedSubjectFilter == 'Tất cả' ||
          g.subject.toLowerCase() == selectedSubjectFilter!.toLowerCase();

      final matchQuery = searchQuery == null ||
          searchQuery!.trim().isEmpty ||
          g.title.toLowerCase().contains(searchQuery!.trim().toLowerCase()) ||
          g.subject.toLowerCase().contains(searchQuery!.trim().toLowerCase()) ||
          g.description.toLowerCase().contains(searchQuery!.trim().toLowerCase()) ||
          g.location.toLowerCase().contains(searchQuery!.trim().toLowerCase());

      return matchSubject && matchQuery;
    }).toList();
  }

  StudyGroupState copyWith({
    StudyGroupStatus? status,
    List<StudyGroupEntity>? groups,
    String? Function()? selectedSubjectFilter,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return StudyGroupState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedSubjectFilter: selectedSubjectFilter != null
          ? selectedSubjectFilter()
          : this.selectedSubjectFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
