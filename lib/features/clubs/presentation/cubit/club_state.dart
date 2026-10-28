import 'package:equatable/equatable.dart';
import '../../domain/entities/club_entity.dart';
import '../../domain/entities/club_creation_request_entity.dart';

enum ClubStatus { initial, loading, loaded, error }

class ClubState extends Equatable {
  final ClubStatus status;
  final List<ClubEntity> clubs;
  final List<ClubCreationRequestEntity> myRequests;
  final List<ClubCreationRequestEntity> pendingRequests;
  final String selectedCategory;
  final String searchQuery;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final bool isSubmitting;

  const ClubState({
    this.status = ClubStatus.initial,
    this.clubs = const [],
    this.myRequests = const [],
    this.pendingRequests = const [],
    this.selectedCategory = 'Tất cả',
    this.searchQuery = '',
    this.errorMessage,
    this.actionSuccessMessage,
    this.isSubmitting = false,
  });

  List<ClubEntity> getFilteredClubs([String? userId, String? studentId]) {
    return clubs.where((club) {
      if (club.status != 'approved') return false;
      final matchesCategory =
          selectedCategory == 'Tất cả' ||
          (selectedCategory == 'Đã tham gia'
              ? club.isMember(userId ?? '', studentId)
              : club.category == selectedCategory);
      final matchesQuery =
          searchQuery.isEmpty ||
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
    List<ClubCreationRequestEntity>? myRequests,
    List<ClubCreationRequestEntity>? pendingRequests,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
    String? actionSuccessMessage,
    bool? isSubmitting,
    bool clearActionMessage = false,
  }) {
    return ClubState(
      status: status ?? this.status,
      clubs: clubs ?? this.clubs,
      myRequests: myRequests ?? this.myRequests,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage:
          errorMessage ?? (clearActionMessage ? null : this.errorMessage),
      actionSuccessMessage:
          actionSuccessMessage ??
          (clearActionMessage ? null : this.actionSuccessMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    status,
    clubs,
    myRequests,
    pendingRequests,
    selectedCategory,
    searchQuery,
    errorMessage,
    actionSuccessMessage,
    isSubmitting,
  ];
}
