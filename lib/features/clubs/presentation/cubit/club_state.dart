import 'package:equatable/equatable.dart';
import '../../domain/entities/club_entity.dart';

enum ClubStatus { initial, loading, loaded, error }

class ClubState extends Equatable {
  final ClubStatus status;
  final List<ClubEntity> clubs;
  final String selectedCategory;
  final String searchQuery;
  final String? errorMessage;
  final String? actionSuccessMessage;

  const ClubState({
    this.status = ClubStatus.initial,
    this.clubs = const [],
    this.selectedCategory = 'Tất cả',
    this.searchQuery = '',
    this.errorMessage,
    this.actionSuccessMessage,
  });

  List<ClubEntity> getFilteredClubs([String? userId, String? studentId]) {
    return clubs.where((club) {
      final matchesCategory = selectedCategory == 'Tất cả' ||
          (selectedCategory == 'Đã tham gia'
              ? club.isMember(userId ?? '', studentId)
              : club.category == selectedCategory);
      final matchesQuery = searchQuery.isEmpty ||
          club.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          club.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          club.leaderName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<ClubEntity> get filteredClubs => getFilteredClubs();

  List<ClubEntity> getJoinedClubs(String userId, [String? studentId]) {
    if (userId.isEmpty && (studentId == null || studentId.isEmpty)) return [];
    return clubs.where((club) => club.isMember(userId, studentId)).toList();
  }

  ClubState copyWith({
    ClubStatus? status,
    List<ClubEntity>? clubs,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
    String? actionSuccessMessage,
    bool clearActionMessage = false,
  }) {
    return ClubState(
      status: status ?? this.status,
      clubs: clubs ?? this.clubs,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? (clearActionMessage ? null : this.errorMessage),
      actionSuccessMessage: actionSuccessMessage ?? (clearActionMessage ? null : this.actionSuccessMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        clubs,
        selectedCategory,
        searchQuery,
        errorMessage,
        actionSuccessMessage,
      ];
}
